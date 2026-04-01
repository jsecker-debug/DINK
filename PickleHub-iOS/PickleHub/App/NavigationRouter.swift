import SwiftUI
import Observation

// MARK: - Tab Enum

enum AppTab: Int, Hashable, CaseIterable {
    case dashboard
    case sessions
    case club
    case profile
}

// MARK: - Navigation Router

@Observable
@MainActor
final class NavigationRouter {
    var selectedTab: AppTab = .dashboard

    /// Pending invite token received via deep link before the user authenticated.
    var pendingInviteToken: String?

    func switchTo(_ tab: AppTab) {
        selectedTab = tab
    }
}
