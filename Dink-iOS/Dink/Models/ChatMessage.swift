import Foundation

struct ChatMessage: Identifiable, Codable, Hashable {
    let id: UUID
    let conversationId: UUID
    let senderId: UUID
    let content: String
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case conversationId = "conversation_id"
        case senderId = "sender_id"
        case content
        case createdAt = "created_at"
    }
}

struct ChatMessageWithSender: Identifiable, Hashable {
    let id: UUID
    let conversationId: UUID
    let senderId: UUID
    let content: String
    let createdAt: Date?
    let senderName: String
    let senderAvatarUrl: String?
}
