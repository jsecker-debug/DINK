import SwiftUI

struct AuthGateView: View {
    @Environment(AuthService.self) private var authService
    @Environment(ClubService.self) private var clubService
    @Environment(NavigationRouter.self) private var router

    @State private var sessionStatusUpdater = SessionStatusUpdater()

    @State private var clubsLoaded = false

    var body: some View {
        Group {
            if authService.isLoading {
                loadingView
            } else if authService.isAuthenticated {
                if clubsLoaded && clubService.userClubs.isEmpty {
                    OnboardingView()
                        .task(id: authService.user?.id) {
                            await processPendingInviteIfNeeded()
                        }
                } else {
                    MainTabView()
                        .onChange(of: clubService.selectedClubId) { _, newClubId in
                            if let clubId = newClubId {
                                sessionStatusUpdater.start(clubId: clubId)
                            } else {
                                sessionStatusUpdater.stop()
                            }
                        }
                }
            } else {
                SignInView()
            }
        }
        .task(id: authService.user?.id) {
            await fetchClubsIfNeeded()
        }
        .onChange(of: clubService.userClubs.count) { _, count in
            // When user creates/joins a club, transition out of onboarding
            if count > 0 {
                clubsLoaded = true
            }
        }
        .animation(.default, value: authService.isAuthenticated)
        .animation(.default, value: clubsLoaded)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text("Loading...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }

    // MARK: - Club Fetching

    private func fetchClubsIfNeeded() async {
        guard let userId = authService.user?.id else { return }
        do {
            try await clubService.fetchUserClubs(userId: userId.uuidString)
        } catch {
            print("Failed to fetch user clubs: \(error)")
        }
        clubsLoaded = true
    }

    /// Processes any pending invite token that was received via deep link before authentication.
    private func processPendingInviteIfNeeded() async {
        guard let token = router.pendingInviteToken else { return }
        router.pendingInviteToken = nil
        do {
            try await authService.processInviteToken(token)
        } catch {
            print("Failed to process pending invite: \(error)")
        }
    }
}
