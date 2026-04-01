import Foundation

/// Maps to the `participants` Supabase table.
/// Represents a persistent participant record with stats.
struct Participant: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String?
    let gender: String
    let level: Double?
    let linked: Bool?
    let userId: UUID?
    let avatarUrl: String?
    let wins: Int?
    let losses: Int?
    let totalGamesPlayed: Int?
    let ratingConfidence: Double?
    let ratingVolatility: Double?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case gender
        case level
        case linked = "Linked"
        case userId = "user_id"
        case avatarUrl = "avatar_url"
        case wins
        case losses
        case totalGamesPlayed = "total_games_played"
        case ratingConfidence = "rating_confidence"
        case ratingVolatility = "rating_volatility"
        case createdAt = "created_at"
    }
}
