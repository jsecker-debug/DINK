import Foundation

/// A single court matchup within a rotation round.
struct Court: Codable, Hashable {
    var team1: [String]
    var team2: [String]
}

/// A full rotation round: courts in play plus resting players.
struct ScheduleRotation: Identifiable, Codable, Hashable {
    var id: UUID?
    var courts: [Court]
    var resters: [String]
}

/// Settings controlling schedule generation.
struct RotationSettings: Codable, Equatable {
    let count: Int
    let minRestCount: Int?

    enum CodingKeys: String, CodingKey {
        case count
        case minRestCount = "min_rest_count"
    }
}
