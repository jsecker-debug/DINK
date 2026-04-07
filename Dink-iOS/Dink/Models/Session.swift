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
    let sessionType: String?
    let tournamentId: UUID?
    let parentSessionId: Int?
    let isTemplate: Bool?
    let recurringConfig: RecurringConfig?
    let subgroupId: UUID?

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
        case sessionType = "session_type"
        case tournamentId = "tournament_id"
        case parentSessionId = "parent_session_id"
        case isTemplate = "is_template"
        case recurringConfig = "recurring_config"
        case subgroupId = "subgroup_id"
    }

    var resolvedSessionType: SessionType {
        SessionType(rawValue: sessionType ?? "open_play") ?? .openPlay
    }
}
