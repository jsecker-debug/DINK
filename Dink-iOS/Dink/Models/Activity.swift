import Foundation

struct Activity: Identifiable, Codable, Equatable {
    let id: UUID
    let clubId: UUID?
    let type: String
    let actorId: UUID?
    let targetId: String?
    let targetType: String?
    let data: ActivityData?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case clubId = "club_id"
        case type
        case actorId = "actor_id"
        case targetId = "target_id"
        case targetType = "target_type"
        case data
        case createdAt = "created_at"
    }
}

/// Flexible JSON payload attached to activity records.
struct ActivityData: Codable, Equatable {
    let title: String?
    let message: String?
    let sessionId: Int?
    let sessionDate: String?
    let venue: String?
    let registeredCount: Int?

    enum CodingKeys: String, CodingKey {
        case title
        case message
        case sessionId = "session_id"
        case sessionDate = "session_date"
        case venue
        case registeredCount = "registered_count"
    }
}
