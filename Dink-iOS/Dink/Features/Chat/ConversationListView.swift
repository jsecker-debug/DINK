import SwiftUI

struct ConversationListView: View {
    @Environment(ClubService.self) private var clubService
    @Environment(AuthService.self) private var authService
    @Environment(ToastManager.self) private var toastManager

    @State private var conversations: [ChatConversation] = []
    @State private var isLoading = false
    @State private var showNewConversation = false

    var body: some View {
        Group {
            if isLoading && conversations.isEmpty {
                LoadingView(message: "Loading conversations...")
            } else if conversations.isEmpty {
                EmptyStateView(
                    icon: "bubble.left.and.bubble.right",
                    title: "No Conversations",
                    message: "Start a conversation with your club members.",
                    actionTitle: "New Conversation"
                ) {
                    showNewConversation = true
                }
            } else {
                List(conversations) { conversation in
                    NavigationLink(value: conversation) {
                        conversationRow(conversation)
                    }
                }
                .listStyle(.plain)
                .refreshable {
                    await loadConversations()
                }
            }
        }
        .navigationDestination(for: ChatConversation.self) { conversation in
            ChatView(conversation: conversation)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showNewConversation = true
                } label: {
                    Image(systemName: "square.and.pencil")
                }
            }
        }
        .sheet(isPresented: $showNewConversation) {
            NewConversationSheet { newConversation in
                conversations.insert(newConversation, at: 0)
            }
        }
        .task(id: clubService.selectedClubId) {
            await loadConversations()
        }
    }

    // MARK: - Row

    @ViewBuilder
    private func conversationRow(_ conversation: ChatConversation) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(conversation.name ?? "Chat")
                .font(.headline)

            if let createdAt = conversation.createdAt {
                Text(createdAt, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Data Loading

    private func loadConversations() async {
        guard let clubId = clubService.selectedClubId,
              let userId = authService.user?.id else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            conversations = try await ChatRepository().fetchConversations(clubId: clubId, userId: userId)
        } catch {
            toastManager.show("Failed to load conversations", type: .error)
        }
    }
}
