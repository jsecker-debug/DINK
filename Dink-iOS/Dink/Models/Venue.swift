import Foundation

struct Venue: Identifiable, Codable, Hashable {
    let id: UUID
    let clubId: UUID
    let name: String
    let address: String?
    let numberOfCourts: Int
    let isActive: Bool
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case clubId = "club_id"
        case name, address
        case numberOfCourts = "number_of_courts"
        case isActive = "is_active"
        case createdAt = "created_at"
    }
}
