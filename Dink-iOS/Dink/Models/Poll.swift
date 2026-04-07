import Foundation

struct Poll: Identifiable, Codable, Hashable {
    let id: UUID
    let clubId: UUID
    let question: String
    let type: String
    let createdBy: UUID
    let expiresAt: Date?
    let status: String
    let allowMultiple: Bool
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, question, type, status
        case clubId = "club_id"
        case createdBy = "created_by"
        case expiresAt = "expires_at"
        case allowMultiple = "allow_multiple"
        case createdAt = "created_at"
    }
}

struct PollOption: Identifiable, Codable, Hashable {
    let id: UUID
    let pollId: UUID
    let text: String
    let sortOrder: Int?

    enum CodingKeys: String, CodingKey {
        case id, text
        case pollId = "poll_id"
        case sortOrder = "sort_order"
    }
}

struct PollVote: Identifiable, Codable, Hashable {
    let id: UUID
    let pollId: UUID
    let optionId: UUID
    let userId: UUID
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case pollId = "poll_id"
        case optionId = "option_id"
        case userId = "user_id"
        case createdAt = "created_at"
    }
}
