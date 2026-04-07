import Foundation

struct DeviceToken: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let token: String
    let platform: String
    let isActive: Bool
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case token
        case platform
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
