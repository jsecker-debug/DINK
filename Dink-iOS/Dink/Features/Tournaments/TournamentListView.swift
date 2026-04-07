import SwiftUI

struct TournamentListView: View {
    @Environment(ClubService.self) private var clubService
    @Environment(AuthService.self) private var authService
    @Environment(ToastManager.self) private var toastManager

    @State private var tournaments: [Tournament] = []
    @State private var isLoading = false
    @State private var showCreateSheet = false

    private let repository = TournamentRepository()

    var body: some View {
        Group {
            if isLoading {
                LoadingView(message: "Loading tournaments...")
            } else if tournaments.isEmpty {
                EmptyStateView(
                    icon: "trophy",
                    title: "No Tournaments",
                    message: "There are no tournaments yet for this club."
                )
            } else {
                tournamentList
            }
        }
        .refreshable { await loadTournaments() }
        .task(id: clubService.selectedClubId) {
            tournaments = []
            await loadTournaments()
        }
        .toolbar {
            if clubService.isAdmin {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCreateSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            CreateTournamentSheet {
                await loadTournaments()
            }
        }
    }

    // MARK: - Tournament List

    private var tournamentList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(tournaments) { tournament in
                    NavigationLink(value: tournament) {
                        tournamentCard(tournament)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .navigationDestination(for: Tournament.self) { tournament in
            TournamentDetailView(tournament: tournament)
        }
    }

    private func tournamentCard(_ tournament: Tournament) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(tournament.name)
                    .font(.headline)
                Spacer()
                statusBadge(tournament.status)
            }

            HStack(spacing: 12) {
                formatBadge(tournament.format)

                if let startDate = tournament.startDate {
                    Label(startDate, systemImage: "calendar")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Label("Team of \(tournament.teamSize)", systemImage: "person.2")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let description = tournament.description, !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(.rect(cornerRadius: 10))
        .liquidGlassStatic(cornerRadius: 10)
    }

    private func statusBadge(_ status: String) -> some View {
        let style: BadgeView.BadgeStyle = switch status {
        case "draft": .secondary
        case "registration": .info
        case "in_progress": .warning
        case "completed": .success
        default: .secondary
        }
        return BadgeView(text: status.replacingOccurrences(of: "_", with: " ").capitalized, style: style)
    }

    private func formatBadge(_ format: String) -> some View {
        let label = format == "round_robin" ? "Round Robin" : "Elimination"
        let icon = format == "round_robin" ? "arrow.triangle.2.circlepath" : "chart.bar.doc.horizontal"
        return Label(label, systemImage: icon)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.dinkTeal.opacity(0.15))
            .foregroundStyle(.dinkTeal)
            .clipShape(Capsule())
    }

    // MARK: - Data Loading

    private func loadTournaments() async {
        guard let clubId = clubService.selectedClubId else { return }
        isLoading = tournaments.isEmpty
        defer { isLoading = false }

        do {
            tournaments = try await repository.fetchTournaments(clubId: clubId)
        } catch {
            toastManager.show("Failed to load tournaments", type: .error)
        }
    }
}
