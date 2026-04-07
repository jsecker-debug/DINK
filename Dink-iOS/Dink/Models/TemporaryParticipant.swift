import Foundation

/// Maps to the `temporary_session_participants` Supabase table.
struct TemporaryParticipant: Identifiable, Codable, Hashable {
    let id: UUID
    let sessionId: Int
    let name: String
    let skillLevel: Double
    let phone: String?
    let notes: String?
    let createdAt: Date?
    let createdBy: UUID?

    enum CodingKeys: String, CodingKey {
        case id
        case sessionId = "session_id"
        case name
        case skillLevel = "skill_level"
        case phone
        case notes
        case createdAt = "created_at"
        case createdBy = "created_by"
    }
}
