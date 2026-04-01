import Foundation

struct ClubInvitation: Identifiable, Codable, Equatable {
    let id: UUID
    let clubId: UUID
    let email: String
    let token: String
    let status: String
    let invitedBy: UUID
    let personalMessage: String?
    let expiresAt: Date?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case clubId = "club_id"
        case email
        case token
        case status
        case invitedBy = "invited_by"
        case personalMessage = "personal_message"
        case expiresAt = "expires_at"
        case createdAt = "created_at"
    }
}
