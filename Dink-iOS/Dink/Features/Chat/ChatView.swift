import SwiftUI

struct ChatView: View {
    @Environment(ChatService.self) private var chatService
    @Environment(AuthService.self) private var authService
    @Environment(ToastManager.self) private var toastManager

    let conversation: ChatConversation

    @State private var messageText = ""
    @State private var isSending = false

    var body: some View {
        VStack(spacing: 0) {
            messagesList

            Divider()

            inputBar
        }
        .navigationTitle(conversation.name ?? "Chat")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            chatService.startPolling(conversationId: conversation.id)
        }
        .onDisappear {
            chatService.stopPolling()
            chatService.clearMessages()
        }
    }

    // MARK: - Messages List

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(chatService.currentMessages) { message in
                        messageBubble(message)
                            .id(message.id)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .onChange(of: chatService.currentMessages.count) { _, _ in
                if let lastMessage = chatService.currentMessages.last {
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    // MARK: - Message Bubble

    @ViewBuilder
    private func messageBubble(_ message: ChatMessageWithSender) -> some View {
        let isCurrentUser = message.senderId == authService.user?.id

        HStack(alignment: .top, spacing: 8) {
            if isCurrentUser { Spacer(minLength: 48) }

            if !isCurrentUser {
                AvatarView(
                    firstName: message.senderName.components(separatedBy: " ").first,
                    lastName: message.senderName.components(separatedBy: " ").dropFirst().first.map { String($0) },
                    avatarUrl: message.senderAvatarUrl,
                    size: 32
                )
            }

            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 2) {
                if !isCurrentUser {
                    Text(message.senderName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(message.content)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        isCurrentUser
                            ? Color.accentColor
                            : Color(.systemGray5)
                    )
                    .foregroundStyle(isCurrentUser ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                if let createdAt = message.createdAt {
                    Text(createdAt, style: .time)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            if !isCurrentUser { Spacer(minLength: 48) }
        }
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: 8) {
            TextField("Message", text: $messageText, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .lineLimit(1...5)

            Button {
                Task { await sendMessage() }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
            }
            .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Send

    private func sendMessage() async {
        let content = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty,
              let senderId = authService.user?.id else { return }

        isSending = true
        messageText = ""

        do {
            try await ChatRepository().sendMessage(
                conversationId: conversation.id,
                senderId: senderId,
                content: content
            )
        } catch {
            messageText = content
            toastManager.show("Failed to send message", type: .error)
        }

        isSending = false
    }
}
