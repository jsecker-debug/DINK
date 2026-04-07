import Foundation

enum SessionType: String, CaseIterable, Identifiable {
    case openPlay = "open_play"
    case roundRobin = "round_robin"
    case singleElimination = "single_elimination"
    case doubleElimination = "double_elimination"
    case kingOfTheCourt = "king_of_the_court"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .openPlay: return "Open Play"
        case .roundRobin: return "Round Robin"
        case .singleElimination: return "Single Elimination"
        case .doubleElimination: return "Double Elimination"
        case .kingOfTheCourt: return "King of the Court"
        }
    }

    var icon: String {
        switch self {
        case .openPlay: return "sportscourt.fill"
        case .roundRobin: return "arrow.triangle.2.circlepath"
        case .singleElimination: return "trophy.fill"
        case .doubleElimination: return "trophy"
        case .kingOfTheCourt: return "crown.fill"
        }
    }

    var isTournament: Bool { self != .openPlay }

    var description: String {
        switch self {
        case .openPlay: return "Casual rotation play with balanced court assignments"
        case .roundRobin: return "Every team plays every other team"
        case .singleElimination: return "Single loss elimination bracket"
        case .doubleElimination: return "Two losses required for elimination"
        case .kingOfTheCourt: return "Winners stay on court, losers rotate out"
        }
    }
}
