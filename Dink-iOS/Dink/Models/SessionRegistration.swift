import Foundation

struct SessionRegistration: Identifiable, Codable, Hashable {
    let id: UUID
    let sessionId: Int
    let userId: UUID
    let status: String
    let registeredAt: Date?
    let feeAmount: Double?
    let calendarEventId: String?

    enum CodingKeys: String, CodingKey {
        case id
        case sessionId = "session_id"
        case userId = "user_id"
        case status
        case registeredAt = "registered_at"
        case feeAmount = "fee_amount"
        case calendarEventId = "calendar_event_id"
    }
}
