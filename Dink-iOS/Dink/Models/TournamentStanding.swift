import Foundation

struct TournamentStanding: Identifiable, Codable, Hashable {
    let id: UUID
    let tournamentId: UUID
    let registrationId: UUID
    let wins: Int
    let losses: Int
    let pointsFor: Int
    let pointsAgainst: Int
    let rank: Int?
    let maxStreak: Int?
    let currentStreak: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case tournamentId = "tournament_id"
        case registrationId = "registration_id"
        case wins, losses
        case pointsFor = "points_for"
        case pointsAgainst = "points_against"
        case rank
        case maxStreak = "max_streak"
        case currentStreak = "current_streak"
    }
}
