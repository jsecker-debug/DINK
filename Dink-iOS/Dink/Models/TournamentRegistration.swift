import Foundation

struct TournamentRegistration: Identifiable, Codable, Hashable {
    let id: UUID
    let tournamentId: UUID
    let userId: UUID
    let teamName: String?
    let partnerId: UUID?
    let status: String
    let registeredAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case tournamentId = "tournament_id"
        case userId = "user_id"
        case teamName = "team_name"
        case partnerId = "partner_id"
        case status
        case registeredAt = "registered_at"
    }
}
