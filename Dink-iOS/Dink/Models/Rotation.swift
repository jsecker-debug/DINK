import Foundation

struct Rotation: Identifiable, Codable, Hashable {
    let id: UUID
    let sessionId: Int?
    let rotationNumber: Int?
    let groupId: UUID?
    let isKingCourt: Bool?
    let lastModified: Date?
    let manuallyModified: Bool?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case sessionId = "session_id"
        case rotationNumber = "rotation_number"
        case groupId = "group_id"
        case isKingCourt = "is_king_court"
        case lastModified = "last_modified"
        case manuallyModified = "manually_modified"
        case createdAt = "created_at"
    }
}
