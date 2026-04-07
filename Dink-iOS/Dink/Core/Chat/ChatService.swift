import Foundation
import Observation
import Supabase

@Observable
@MainActor
final class ChatService {
    var currentMessages: [ChatMessageWithSender] = []

    private var pollingTimer: Timer?
    private var senderCache: [UUID: (name: String, avatarUrl: String?)] = [:]
    private var activeConversationId: UUID?

    // MARK: - Polling

    func startPolling(conversationId: UUID) {
        stopPolling()
        activeConversationId = conversationId
        // Fetch immediately
        Task { await fetchMessages(conversationId: conversationId) }
        // Then every 3 seconds
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.fetchMessages(conversationId: conversationId)
            }
        }
    }

    func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
        activeConversationId = nil
    }

    // MARK: - Fetch Messages

    private func fetchMessages(conversationId: UUID) async {
        do {
            let messages = try await ChatRepository().fetchMessages(conversationId: conversationId)
            var enriched: [ChatMessageWithSender] = []

            for message in messages {
                let sender = await lookupSender(message.senderId)
                enriched.append(ChatMessageWithSender(
                    id: message.id,
                    conversationId: message.conversationId,
                    senderId: message.senderId,
                    content: message.content,
                    createdAt: message.createdAt,
                    senderName: sender.name,
                    senderAvatarUrl: sender.avatarUrl
                ))
            }

            currentMessages = enriched
        } catch {
            print("ChatService: failed to fetch messages: \(error)")
        }
    }

    // MARK: - Sender Lookup

    private func lookupSender(_ userId: UUID) async -> (name: String, avatarUrl: String?) {
        if let cached = senderCache[userId] {
            return cached
        }
        do {
            let profile: UserProfile = try await supabase
                .from("user_profiles")
                .select("id, first_name, last_name, avatar_url")
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
                .value
            let result = (name: profile.fullName, avatarUrl: profile.avatarUrl)
            senderCache[userId] = result
            return result
        } catch {
            return (name: "Unknown", avatarUrl: nil)
        }
    }

    // MARK: - Clear

    func clearMessages() {
        currentMessages = []
        senderCache = [:]
    }
}
