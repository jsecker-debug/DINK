import SwiftUI

struct SessionsListView: View {
    @Environment(ClubService.self) private var clubService
    @Environment(AuthService.self) private var authService

    @State private var sessions: [ClubSession] = []
    @State private var isLoading = false
    @State private var showCreateSheet = false

    var body: some View {
        Group {
            if isLoading && sessions.isEmpty {
                LoadingView(message: "Loading sessions...")
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        if let next = nextSession {
                            nextSessionCard(next)
                        }

                        if !upcomingSessions.isEmpty {
                            sectionHeader("Upcoming Sessions")
                            ForEach(upcomingSessions) { session in
                                NavigationLink(value: session) {
                                    SessionRowCard(session: session)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        if !completedSessions.isEmpty {
                            sectionHeader("Completed Sessions")
                            ForEach(completedSessions) { session in
                                NavigationLink(value: session) {
                                    SessionRowCard(session: session)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        if sessions.isEmpty && !isLoading {
                            ContentUnavailableView("No Sessions", systemImage: "calendar.badge.exclamationmark", description: Text("Create a session to get started."))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
        }
        .navigationTitle("Sessions")
        .navigationDestination(for: ClubSession.self) { session in
            SessionDetailView(session: session)
        }
        .toolbar {
            if clubService.isAdmin {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showCreateSheet = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            CreateSessionSheet { await loadData() }
        }
        .refreshable { await loadData() }
        .task(id: clubService.selectedClubId) {
            sessions = []
            await loadData()
        }
    }

    // MARK: - Sections

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
    }

    private func nextSessionCard(_ session: ClubSession) -> some View {
        NavigationLink(value: session) {
            VStack(alignment: .leading, spacing: 8) {
                Label("Next Session", systemImage: "star.fill")
                    .font(.caption.bold())
                    .foregroundStyle(.dinkOrange)

                Text(session.date ?? "TBD")
                    .font(.title3.bold())

                HStack(spacing: 16) {
                    Label(session.venue ?? "TBD", systemImage: "mappin")
                    if let fee = session.feePerPlayer, fee > 0 {
                        Label(String(format: "£%.2f", fee), systemImage: "sterlingsign.circle")
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color(.secondarySystemBackground))
            .clipShape(.rect(cornerRadius: 10))
            .liquidGlass(cornerRadius: 10)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Next session: \(session.date ?? "TBD") at \(session.venue ?? "TBD")")
            .accessibilityHint("Tap to view session details")
        }
        .buttonStyle(.plain)
    }

    // MARK: - Computed

    private var nextSession: ClubSession? {
        upcomingSessions.first
    }

    private var upcomingSessions: [ClubSession] {
        sessions.filter { ($0.status ?? "").lowercased() == "upcoming" }
    }

    private var completedSessions: [ClubSession] {
        sessions.filter { ($0.status ?? "").lowercased() == "completed" }
    }

    private func loadData() async {
        guard let clubId = clubService.selectedClubId else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            sessions = try await SessionRepository().fetchSessions(clubId: clubId)
        } catch {
            print("Failed to load sessions: \(error)")
        }
    }
}
