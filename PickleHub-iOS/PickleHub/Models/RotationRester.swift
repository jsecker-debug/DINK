import Foundation

/// Maps to the `roation_resters` Supabase table (typo in original DB schema).
struct RotationRester: Identifiable, Codable, Equatable {
    let id: UUID
    let rotationId: UUID?
    let restingPlayers: [String]?
    let createdAt: Date?

    // NOTE: The table name in Supabase is "roation_resters" (typo preserved).
    enum CodingKeys: String, CodingKey {
        case id
        case rotationId = "rotation_id"
        case restingPlayers = "resting_players"
        case createdAt = "created_at"
    }
}
