import Foundation

struct Club: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let description: String?
    let location: String?
    let status: String?
    var role: String?
    let memberCount: Int?
    let createdAt: Date?
    let createdBy: UUID?

    enum CodingKeys: String, CodingKey {
        case id, name, description, location, status, role
        case memberCount = "member_count"
        case createdAt = "created_at"
        case createdBy = "created_by"
    }
}
