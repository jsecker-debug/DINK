import Foundation

struct Tournament: Identifiable, Codable, Hashable {
    let id: UUID
    let clubId: UUID
    let name: String
    let description: String?
    let format: String
    let status: String
    let maxTeams: Int?
    let teamSize: Int
    let startDate: String?
    let endDate: String?
    let createdBy: UUID?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case clubId = "club_id"
        case name, description, format, status
        case maxTeams = "max_teams"
        case teamSize = "team_size"
        case startDate = "start_date"
        case endDate = "end_date"
        case createdBy = "created_by"
        case createdAt = "created_at"
    }
}
