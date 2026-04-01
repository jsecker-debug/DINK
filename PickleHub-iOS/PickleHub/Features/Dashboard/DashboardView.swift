import SwiftUI

struct DashboardView: View {
    @Environment(AuthService.self) private var authService
    @Environment(ClubService.self) private var clubService
    @Environment(NavigationRouter.self) private var router

    @State private var sessions: [ClubSession] = []
    @State private var members: [ClubMemberWithProfile] = []
    @State private var isLoading = false
    @State private var error: String?
    @State private var showCreateSessionSheet = false

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        Group {
            if isLoading && sessions.isEmpty && members.isEmpty {
                LoadingView(message: "Loading dashboard...")
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        welcomeHeader
                        statsGrid
                        quickActions
                        upcomingSessionsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
        }
        .navigationTitle("Dashboard")
        .navigationDestination(for: ClubSession.self) { session in
            SessionDetailView(session: session)
        }
        .sheet(isPresented: $showCreateSessionSheet) {
            CreateSessionSheet { await loadData() }
        }
        .refreshable { await loadData() }
        .task(id: clubService.selectedClubId) {
            sessions = []
            members = []
            await loadData()
        }
    }

    // MARK: - Welcome

    private var welcomeHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Welcome back, \(authService.userProfile?.firstName ?? "Player")")
                .font(.title2.bold())
            if let club = clubService.selectedClub {
                Text(club.name)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Stats

    private var statsGrid: some View {
        LiquidGlassContainer(spacing: 12) {
            LazyVGrid(columns: columns, spacing: 12) {
                StatCardView(title: "Total Members", value: "\(members.count)", icon: "person.2.fill")
                StatCardView(title: "Active Players", value: "\(activePlayers)", icon: "figure.pickleball")
                StatCardView(title: "Upcoming", value: "\(upcomingSessions.count)", icon: "calendar")
                StatCardView(title: "Total Sessions", value: "\(sessions.count)", icon: "list.bullet")
            }
        }
    }

    // MARK: - Quick Actions

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)

            LiquidGlassContainer(spacing: 12) {
                LazyVGrid(columns: columns, spacing: 12) {
                    QuickActionButton(icon: "calendar.badge.plus", label: "Schedule Session") {
                        showCreateSessionSheet = true
                    }
                    QuickActionButton(icon: "person.badge.plus", label: "Manage Members") {
                        router.switchTo(.club)
                    }
                    QuickActionButton(icon: "sportscourt.fill", label: "Generate Games") {
                        router.switchTo(.sessions)
                    }
                    QuickActionButton(icon: "trophy.fill", label: "View Rankings") {
                        router.switchTo(.club)
                    }
                }
            }
        }
    }

    // MARK: - Upcoming Sessions

    private var upcomingSessionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Upcoming Sessions")
                .font(.headline)

            if upcomingSessions.isEmpty {
                Text("No upcoming sessions")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
            } else {
                ForEach(upcomingSessions.prefix(5)) { session in
                    NavigationLink(value: session) {
                        SessionRowCard(session: session)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Computed

    private var upcomingSessions: [ClubSession] {
        sessions.filter { ($0.status ?? "").lowercased() != "completed" && ($0.status ?? "").lowercased() != "cancelled" }
    }

    private var activePlayers: Int {
        members.filter { $0.totalGamesPlayed >= 1 }.count
    }

    // MARK: - Data Loading

    private func loadData() async {
        guard let clubId = clubService.selectedClubId else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            async let fetchedSessions = SessionRepository().fetchSessions(clubId: clubId)
            async let fetchedMembers = MemberRepository().fetchClubMembers(clubId: clubId)
            sessions = try await fetchedSessions
            members = try await fetchedMembers
        } catch {
            self.error = error.localizedDescription
        }
    }
}

// MARK: - Quick Action Button

private struct QuickActionButton: View {
    let icon: String
    let label: String
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .accessibilityHidden(true)
                Text(label)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(.secondarySystemBackground))
            .clipShape(.rect(cornerRadius: 10))
            .liquidGlass(cornerRadius: 10)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

// MARK: - Session Row Card

struct SessionRowCard: View {
    let session: ClubSession

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.date ?? "No date")
                    .font(.subheadline.bold())
                Text(session.venue ?? "No venue")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let status = session.status {
                Text(status)
                    .font(.caption2.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor(status).opacity(0.15))
                    .foregroundStyle(statusColor(status))
                    .clipShape(Capsule())
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(.rect(cornerRadius: 10))
        .liquidGlassStatic(cornerRadius: 10)
        .accessibilityElement(children: .combine)
    }

    private func statusColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "upcoming": return .blue
        case "completed": return .green
        case "cancelled": return .red
        default: return .secondary
        }
    }
}
