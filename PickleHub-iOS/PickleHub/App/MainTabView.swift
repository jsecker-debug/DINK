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

            Tab("Rankings", systemImage: "trophy.fill", value: .rankings) {
                NavigationStack {
                    RankingsView()
                        .toolbar { clubToolbar }
                }
            }

            Tab("Members", systemImage: "person.2.fill", value: .members) {
                NavigationStack {
                    MembersContainerView()
                        .toolbar { clubToolbar }
                }
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

            NavigationStack {
                RankingsView()
                    .toolbar { clubToolbar }
            }
            .tabItem {
                Label("Rankings", systemImage: "trophy.fill")
            }
            .tag(AppTab.rankings)

            NavigationStack {
                MembersContainerView()
                    .toolbar { clubToolbar }
            }
            .tabItem {
                Label("Members", systemImage: "person.2.fill")
            }
            .tag(AppTab.members)

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
