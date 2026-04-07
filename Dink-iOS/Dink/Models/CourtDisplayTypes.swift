import Foundation

/// Data needed to render the court display UI.
struct CourtDisplayData: Equatable {
    let rotations: [ScheduleRotation]
    let isKingCourt: Bool
    let sessionId: UUID?
    let sessionStatus: String?
}

/// Basic player info for court rendering.
struct PlayerData: Codable, Hashable {
    let name: String
    let gender: String
}

/// Describes a player swap operation between positions.
struct SwapData: Equatable {
    let player: String
    let teamType: TeamType
    let courtIndex: Int
    let rotationIndex: Int
    let targetPlayer: String?

    enum TeamType: String, Codable {
        case team1
        case team2
    }
}

/// Score pair for a single game on a court.
struct ScoreData: Codable, Equatable {
    let team1: String
    let team2: String
}
