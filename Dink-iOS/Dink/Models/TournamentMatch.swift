import Foundation

struct TournamentMatch: Identifiable, Codable, Hashable {
    let id: UUID
    let tournamentId: UUID
    let round: Int
    let matchNumber: Int
    let teamAId: UUID?
    let teamBId: UUID?
    let scoreA: Int?
    let scoreB: Int?
    let winnerId: UUID?
    let status: String
    let scheduledAt: Date?
    let completedAt: Date?
    let bracketType: String?
    let courtNumber: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case tournamentId = "tournament_id"
        case round
        case matchNumber = "match_number"
        case teamAId = "team_a_id"
        case teamBId = "team_b_id"
        case scoreA = "score_a"
        case scoreB = "score_b"
        case winnerId = "winner_id"
        case status
        case scheduledAt = "scheduled_at"
        case completedAt = "completed_at"
        case bracketType = "bracket_type"
        case courtNumber = "court_number"
    }
}
