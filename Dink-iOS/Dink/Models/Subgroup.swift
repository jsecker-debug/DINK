import Foundation

struct Subgroup: Identifiable, Codable, Hashable {
    let id: UUID
    let clubId: UUID
    let name: String
    let color: String
    let description: String?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, name, color, description
        case clubId = "club_id"
        case createdAt = "created_at"
    }
}

struct SubgroupMember: Identifiable, Codable, Hashable {
    let id: UUID
    let subgroupId: UUID
    let userId: UUID
    let joinedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case subgroupId = "subgroup_id"
        case userId = "user_id"
        case joinedAt = "joined_at"
    }
}
