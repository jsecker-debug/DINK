import Foundation

struct MVPVote: Identifiable, Codable, Hashable {
    let id: UUID
    let sessionId: Int
    let voterId: UUID
    let nomineeId: UUID
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case sessionId = "session_id"
        case voterId = "voter_id"
        case nomineeId = "nominee_id"
        case createdAt = "created_at"
    }
}

struct MVPResult: Codable, Hashable {
    let nomineeId: UUID
    let voteCount: Int

    enum CodingKeys: String, CodingKey {
        case nomineeId = "nominee_id"
        case voteCount = "vote_count"
    }
}
