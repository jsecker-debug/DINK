import Foundation

struct ClubSession: Identifiable, Codable, Hashable {
    let id: Int
    let createdAt: Date?
    let date: String?
    let venue: String?
    let status: String?
    let groupId: UUID?
    let clubId: UUID?
    let scoresEntered: Bool?
    let feePerPlayer: Double?
    let maxParticipants: Int?
    let registrationDeadline: Date?
    let startTime: Date?
    let endTime: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case date = "Date"
        case venue = "Venue"
        case status = "Status"
        case groupId = "group_id"
        case clubId = "club_id"
        case scoresEntered = "scores_entered"
        case feePerPlayer = "fee_per_player"
        case maxParticipants = "max_participants"
        case registrationDeadline = "registration_deadline"
        case startTime = "start_time"
        case endTime = "end_time"
    }
}
