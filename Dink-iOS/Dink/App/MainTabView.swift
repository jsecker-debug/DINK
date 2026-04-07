import SwiftUI

struct MainTabView: View {
    @Environment(ClubService.self) private var clubService
    @Environment(AuthService.self) private var authService
    @Environment(NavigationRouter.self) private var router

    var body: some View {
        if #available(iOS 18.0, *) {
            modernTabView
        } else {
            legacyTabView
        }
    }

    // MARK: - iOS 18+ (Tab API with sidebar adaptable on iOS 26)

    @available(iOS 18.0, *)
    private var modernTabView: some View {
        @Bindable var router = router
        return TabView(selection: $router.selectedTab) {
            Tab("Dashboard", systemImage: "house.fill", value: .dashboard) {
                NavigationStack {
                    DashboardView()
                        .toolbar { clubToolbar }
                }
            }

            Tab("Sessions", systemImage: "calendar", value: .sessions) {
                NavigationStack {
                    SessionsListView()
                        .toolbar { clubToolbar }
                }
            }

            Tab("Club", systemImage: "building.2.fill", value: .club) {
                ClubContainerView()
            }

            Tab("Profile", systemImage: "person.crop.circle", value: .profile) {
                NavigationStack {
                    ProfileView()
                        .toolbar { clubToolbar }
                }
            }
        }
        .applyAdaptableSidebar()
    }

    // MARK: - iOS 17 fallback (tabItem API)

    private var legacyTabView: some View {
        @Bindable var router = router
        return TabView(selection: $router.selectedTab) {
            NavigationStack {
                DashboardView()
                    .toolbar { clubToolbar }
            }
            .tabItem {
                Label("Dashboard", systemImage: "house.fill")
            }
            .tag(AppTab.dashboard)

            NavigationStack {
                SessionsListView()
                    .toolbar { clubToolbar }
            }
            .tabItem {
                Label("Sessions", systemImage: "calendar")
            }
            .tag(AppTab.sessions)

            ClubContainerView()
            .tabItem {
                Label("Club", systemImage: "building.2.fill")
            }
            .tag(AppTab.club)

            NavigationStack {
                ProfileView()
                    .toolbar { clubToolbar }
            }
            .tabItem {
                Label("Profile", systemImage: "person.crop.circle")
            }
            .tag(AppTab.profile)
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var clubToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            ClubSelectorView()
        }
    }
}

// MARK: - iPad Sidebar Adaptable Style (iOS 26+)

private extension View {
    @ViewBuilder
    func applyAdaptableSidebar() -> some View {
        if #available(iOS 26, *) {
            self.tabViewStyle(.sidebarAdaptable)
        } else {
            self
        }
    }
}
