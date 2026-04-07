import Foundation

struct KingOfCourtState: Identifiable, Codable, Hashable {
    let id: UUID
    let tournamentId: UUID
    let courtNumber: Int
    let currentTeamId: UUID?
    let streak: Int
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case tournamentId = "tournament_id"
        case courtNumber = "court_number"
        case currentTeamId = "current_team_id"
        case streak
        case updatedAt = "updated_at"
    }
}
