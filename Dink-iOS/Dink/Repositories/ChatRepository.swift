import Foundation
import Supabase

struct ChatRepository {

    // MARK: - Private Helpers

    private struct ChatParticipantRow: Codable {
        let conversationId: UUID

        enum CodingKeys: String, CodingKey {
            case conversationId = "conversation_id"
        }
    }

    private struct ChatParticipantInsert: Codable {
        let conversationId: UUID
        let userId: UUID

        enum CodingKeys: String, CodingKey {
            case conversationId = "conversation_id"
            case userId = "user_id"
        }
    }

    private struct ConversationInsert: Codable {
        let clubId: UUID
        let name: String?
        let type: String

        enum CodingKeys: String, CodingKey {
            case clubId = "club_id"
            case name, type
        }
    }

    private struct MessageInsert: Codable {
        let conversationId: UUID
        let senderId: UUID
        let content: String

        enum CodingKeys: String, CodingKey {
            case conversationId = "conversation_id"
            case senderId = "sender_id"
            case content
        }
    }

    // MARK: - Fetch Conversations

    func fetchConversations(clubId: UUID, userId: UUID) async throws -> [ChatConversation] {
        let participations: [ChatParticipantRow] = try await supabase
            .from("chat_participants")
            .select("conversation_id")
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value

        let conversationIds = participations.map { $0.conversationId.uuidString }
        guard !conversationIds.isEmpty else { return [] }

        let conversations: [ChatConversation] = try await supabase
            .from("chat_conversations")
            .select()
            .eq("club_id", value: clubId.uuidString)
            .in("id", values: conversationIds)
            .order("created_at", ascending: false)
            .execute()
            .value

        return conversations
    }

    // MARK: - Fetch Messages

    func fetchMessages(conversationId: UUID, limit: Int = 50) async throws -> [ChatMessage] {
        let messages: [ChatMessage] = try await supabase
            .from("chat_messages")
            .select()
            .eq("conversation_id", value: conversationId.uuidString)
            .order("created_at", ascending: true)
            .limit(limit)
            .execute()
            .value

        return messages
    }

    // MARK: - Send Message

    @discardableResult
    func sendMessage(conversationId: UUID, senderId: UUID, content: String) async throws -> ChatMessage {
        let payload = MessageInsert(
            conversationId: conversationId,
            senderId: senderId,
            content: content
        )

        let message: ChatMessage = try await supabase
            .from("chat_messages")
            .insert(payload)
            .select()
            .single()
            .execute()
            .value

        return message
    }

    // MARK: - Create Conversation

    @discardableResult
    func createConversation(clubId: UUID, name: String?, participantIds: [UUID]) async throws -> ChatConversation {
        let conversationType = participantIds.count == 2 ? "direct" : "group"
        let payload = ConversationInsert(
            clubId: clubId,
            name: name,
            type: conversationType
        )

        let conversation: ChatConversation = try await supabase
            .from("chat_conversations")
            .insert(payload)
            .select()
            .single()
            .execute()
            .value

        let participants = participantIds.map { userId in
            ChatParticipantInsert(conversationId: conversation.id, userId: userId)
        }

        try await supabase
            .from("chat_participants")
            .insert(participants)
            .execute()

        return conversation
    }

    // MARK: - Fetch Participant Profiles

    func fetchParticipantProfiles(conversationId: UUID) async throws -> [UserProfile] {
        let participantUserIds: [ParticipantUserRow] = try await supabase
            .from("chat_participants")
            .select("user_id")
            .eq("conversation_id", value: conversationId.uuidString)
            .execute()
            .value

        let userIds = participantUserIds.map { $0.userId.uuidString }
        guard !userIds.isEmpty else { return [] }

        let profiles: [UserProfile] = try await supabase
            .from("user_profiles")
            .select()
            .in("id", values: userIds)
            .execute()
            .value

        return profiles
    }
}

// MARK: - Additional Helper

private struct ParticipantUserRow: Codable {
    let userId: UUID

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
    }
}
