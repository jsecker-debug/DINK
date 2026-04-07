import Foundation

/// Maps to the `rotation_resters` Supabase table.
struct RotationRester: Identifiable, Codable, Equatable {
    let id: UUID
    let rotationId: UUID?
    let restingPlayers: [String]?
    let createdAt: Date?

    // Maps to "rotation_resters" Supabase table.
    enum CodingKeys: String, CodingKey {
        case id
        case rotationId = "rotation_id"
        case restingPlayers = "resting_players"
        case createdAt = "created_at"
    }
}
