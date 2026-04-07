import Foundation

struct ChatConversation: Identifiable, Codable, Hashable {
    let id: UUID
    let clubId: UUID
    let name: String?
    let type: String
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case clubId = "club_id"
        case name, type
        case createdAt = "created_at"
    }
}
