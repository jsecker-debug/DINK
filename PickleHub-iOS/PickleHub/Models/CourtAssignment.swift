import Foundation

struct CourtAssignment: Identifiable, Codable, Hashable {
    let id: UUID
    let rotationId: UUID?
    let courtNumber: Int?
    let team1Players: [String]?
    let team2Players: [String]?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case rotationId = "rotation_id"
        case courtNumber = "court_number"
        case team1Players = "team1_players"
        case team2Players = "team2_players"
        case createdAt = "created_at"
    }
}
