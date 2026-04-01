import Foundation

struct GameResult: Identifiable, Codable, Hashable {
    let id: UUID
    let sessionId: Int?
    let courtNumber: Int?
    let gameNumber: Int?
    let isBestOfThree: Bool?
    let winningTeamPlayers: [String]
    let winningTeamScore: Int
    let losingTeamPlayers: [String]
    let losingTeamScore: Int
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case sessionId = "session_id"
        case courtNumber = "court_number"
        case gameNumber = "game_number"
        case isBestOfThree = "is_best_of_three"
        case winningTeamPlayers = "winning_team_players"
        case winningTeamScore = "winning_team_score"
        case losingTeamPlayers = "losing_team_players"
        case losingTeamScore = "losing_team_score"
        case createdAt = "created_at"
    }
}
