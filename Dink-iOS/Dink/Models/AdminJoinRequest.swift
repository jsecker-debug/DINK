import Foundation

struct AdminJoinRequest: Identifiable, Codable {
    let id: UUID
    let clubId: UUID
    let userId: UUID
    let message: String?
    let status: String
    let createdAt: Date?
    let userData: JoinRequestUserData?

    enum CodingKeys: String, CodingKey {
        case id
        case clubId = "club_id"
        case userId = "user_id"
        case message, status
        case createdAt = "created_at"
        case userData = "user_data"
    }
}

struct JoinRequestUserData: Codable {
    let firstName: String?
    let lastName: String?
    let email: String?
    let skillLevel: Double?

    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName = "last_name"
        case email
        case skillLevel = "skill_level"
    }

    var fullName: String {
        [firstName, lastName].compactMap { $0 }.joined(separator: " ")
    }
}
