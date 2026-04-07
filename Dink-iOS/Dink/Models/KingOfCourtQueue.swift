import Foundation

struct KingOfCourtQueue: Identifiable, Codable, Hashable {
    let id: UUID
    let tournamentId: UUID
    let teamId: UUID
    let queuePosition: Int

    enum CodingKeys: String, CodingKey {
        case id
        case tournamentId = "tournament_id"
        case teamId = "team_id"
        case queuePosition = "queue_position"
    }
}
