import Foundation

struct ClubMembership: Identifiable, Codable, Equatable {
    let id: UUID
    let clubId: UUID
    let userId: UUID
    let role: String
    let status: String
    let joinedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case clubId = "club_id"
        case userId = "user_id"
        case role
        case status
        case joinedAt = "joined_at"
    }
}
