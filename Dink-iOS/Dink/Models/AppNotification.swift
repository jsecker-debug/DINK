import Foundation

struct AppNotification: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let title: String
    let body: String
    let type: String
    let data: NotificationData?
    let read: Bool
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title, body, type, data, read
        case createdAt = "created_at"
    }
}

struct NotificationData: Codable {
    let sessionId: Int?
    let clubId: String?

    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case clubId = "club_id"
    }
}
