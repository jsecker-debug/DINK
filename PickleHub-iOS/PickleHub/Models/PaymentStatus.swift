import Foundation

/// Maps to the `session_payments` Supabase table.
struct PaymentStatus: Identifiable, Codable, Equatable {
    let id: UUID
    let sessionId: Int
    let userId: UUID
    let registrationId: UUID?
    let amount: Double?
    let paid: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case sessionId = "session_id"
        case userId = "user_id"
        case registrationId = "registration_id"
        case amount
        case paid
    }
}
