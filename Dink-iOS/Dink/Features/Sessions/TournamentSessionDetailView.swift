import SwiftUI

struct TournamentSessionDetailView: View {
    let session: ClubSession

    @Environment(AuthService.self) private var authService
    @Environment(ClubService.self) private var clubService
    @Environment(ToastManager.self) private var toastManager

    @State private var tournament: Tournament?
    @State private var registrations: [TournamentRegistration] = []
    @State private var matches: [TournamentMatch] = []
    @State private var standings: [TournamentStanding] = []
    @State private var kotcCourts: [KingOfCourtState] = []
    @State private var kotcQueue: [KingOfCourtQueue] = []
    @State private var isLoading = false
    @State private var selectedTab = 0
    @State private var showScoreSheet = false
    @State private var selectedMatch: TournamentMatch?
    @State private var showKotcScoreSheet = false
    @State private var selectedCourtNumber = 0

    var body: some View {
        Group {
            if isLoading && tournament == nil {
                LoadingView(message: "Loading tournament...")
            } else if let tournament {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        sessionHeader
                        tournamentInfoCard(tournament)
                        actionButtons(tournament)
                        tabContent(tournament)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            } else {
                VStack {
                    Text("Tournament not found")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Tournament")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await loadData() }
        .task { await loadData() }
        .sheet(item: $selectedMatch) { match in
            TournamentScoreInputSheet(
                match: match,
                teamAName: teamName(for: match.teamAId),
                teamBName: teamName(for: match.teamBId),
                onSaved: { await handleScoreSaved(match: match) }
            )
        }
    }

    // MARK: - Header

    private var sessionHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(session.date ?? "No Date")
                    .font(.title2.bold())
                Spacer()
                if let status = session.status {
                    StatusBadge(status: status)
                }
            }

            HStack(spacing: 16) {
                if let venue = session.venue {
                    Label(venue, systemImage: "mappin")
                }
                if let fee = session.feePerPlayer, fee > 0 {
                    Label(String(format: "£%.2f", fee), systemImage: "sterlingsign.circle")
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
    }

    // MARK: - Tournament Info

    private func tournamentInfoCard(_ tournament: Tournament) -> some View {
        VStack(spacing: 0) {
            infoRow(label: "Format", value: session.resolvedSessionType.displayName, icon: session.resolvedSessionType.icon)
            Divider().padding(.leading, 16)
            infoRow(label: "Status", value: tournament.status.capitalized, icon: "circle.fill")
            Divider().padding(.leading, 16)
            infoRow(label: "Team Size", value: "\(tournament.teamSize)v\(tournament.teamSize)", icon: "person.2")
            Divider().padding(.leading, 16)
            infoRow(label: "Registered", value: "\(registrations.count)\(tournament.maxTeams != nil ? "/\(tournament.maxTeams!)" : "") teams", icon: "person.3")
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(.rect(cornerRadius: 10))
    }

    private func infoRow(label: String, value: String, icon: String) -> some View {
        HStack {
            Label(label, systemImage: icon)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.subheadline)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Actions

    private func actionButtons(_ tournament: Tournament) -> some View {
        HStack(spacing: 12) {
            if tournament.status == "registration" || tournament.status == "draft" {
                let isRegistered = registrations.contains { $0.userId == authService.user?.id }
                if isRegistered {
                    Button(role: .destructive) {
                        // TODO: Unregister
                    } label: {
                        Label("Unregister", systemImage: "xmark")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                } else {
                    Button {
                        Task { await registerForTournament(tournament) }
                    } label: {
                        Label("Register", systemImage: "checkmark")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            if clubService.isAdmin {
                Menu {
                    if tournament.status == "draft" {
                        Button {
                            Task { await updateStatus(tournament, to: "registration") }
                        } label: {
                            Label("Open Registration", systemImage: "person.badge.plus")
                        }
                    }
                    if tournament.status == "registration" {
                        Button {
                            Task { await startTournament(tournament) }
                        } label: {
                            Label("Start Tournament", systemImage: "play.fill")
                        }
                    }
                    if tournament.status == "in_progress" {
                        Button {
                            Task { await updateStatus(tournament, to: "completed") }
                        } label: {
                            Label("Complete Tournament", systemImage: "checkmark.circle")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                }
            }
        }
    }

    // MARK: - Tab Content

    private func tabContent(_ tournament: Tournament) -> some View {
        VStack(spacing: 16) {
            Picker("View", selection: $selectedTab) {
                Text("Bracket").tag(0)
                Text("Courts").tag(1)
                Text("Standings").tag(2)
            }
            .pickerStyle(.segmented)

            switch selectedTab {
            case 0:
                bracketView(tournament)
            case 1:
                courtsView(tournament)
            case 2:
                standingsView
            default:
                EmptyView()
            }
        }
    }

    @ViewBuilder
    private func bracketView(_ tournament: Tournament) -> some View {
        switch session.resolvedSessionType {
        case .roundRobin:
            RoundRobinGridView(
                matches: matches,
                registrations: registrations,
                standings: standings,
                onMatchTapped: { selectedMatch = $0 }
            )
        case .singleElimination:
            SingleEliminationBracketView(
                matches: matches,
                registrations: registrations,
                onMatchTapped: { selectedMatch = $0 }
            )
        case .doubleElimination:
            DoubleEliminationBracketView(
                matches: matches,
                registrations: registrations,
                onMatchTapped: { selectedMatch = $0 }
            )
        case .kingOfTheCourt:
            KingOfCourtView(
                courts: kotcCourts,
                queue: kotcQueue,
                standings: standings,
                registrations: registrations,
                onReportResult: { courtNumber in
                    selectedCourtNumber = courtNumber
                    // Find the current match for this court or create ad-hoc score entry
                    if let court = kotcCourts.first(where: { $0.courtNumber == courtNumber }),
                       let currentTeamId = court.currentTeamId,
                       let challengerId = kotcQueue.sorted(by: { $0.queuePosition < $1.queuePosition }).first?.teamId {
                        selectedMatch = TournamentMatch(
                            id: UUID(),
                            tournamentId: tournament.id,
                            round: 1, matchNumber: 0,
                            teamAId: currentTeamId, teamBId: challengerId,
                            scoreA: nil, scoreB: nil, winnerId: nil,
                            status: "scheduled",
                            scheduledAt: nil, completedAt: nil,
                            bracketType: "king_of_court", courtNumber: courtNumber
                        )
                    }
                }
            )
        default:
            Text("Bracket view not available for this format")
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func courtsView(_ tournament: Tournament) -> some View {
        if session.resolvedSessionType == .kingOfTheCourt {
            KingOfCourtView(
                courts: kotcCourts,
                queue: kotcQueue,
                standings: standings,
                registrations: registrations,
                onReportResult: { courtNumber in
                    selectedCourtNumber = courtNumber
                }
            )
        } else {
            TournamentCourtDisplayView(
                matches: matches,
                registrations: registrations,
                onScoreSaved: { await loadData() }
            )
        }
    }

    private var standingsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            if standings.isEmpty {
                Text("No standings yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
            } else {
                ForEach(standings.sorted(by: { ($0.rank ?? 999) < ($1.rank ?? 999) })) { standing in
                    HStack {
                        Text("#\(standing.rank ?? 0)")
                            .font(.caption.bold())
                            .frame(width: 30)
                        Text(teamName(for: standing.registrationId))
                            .font(.subheadline)
                        Spacer()
                        Text("\(standing.wins)W - \(standing.losses)L")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(standing.pointsFor)-\(standing.pointsAgainst)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                }
            }
        }
    }

    // MARK: - Data Loading

    private func loadData() async {
        guard let tournamentId = session.tournamentId else { return }
        isLoading = true
        defer { isLoading = false }

        let repo = TournamentRepository()
        do {
            async let t = repo.fetchTournaments(clubId: session.clubId ?? UUID())
            async let r = repo.fetchRegistrations(tournamentId: tournamentId)
            async let m = repo.fetchMatches(tournamentId: tournamentId)
            async let s = repo.fetchStandings(tournamentId: tournamentId)

            let tournaments = try await t
            tournament = tournaments.first { $0.id == tournamentId }
            registrations = try await r
            matches = try await m
            standings = try await s

            // Load KotC-specific data
            if session.resolvedSessionType == .kingOfTheCourt {
                kotcCourts = try await repo.fetchKingOfCourtState(tournamentId: tournamentId)
                kotcQueue = try await repo.fetchKingOfCourtQueue(tournamentId: tournamentId)
            }
        } catch {
            toastManager.show("Failed to load tournament: \(error.localizedDescription)", type: .error)
        }
    }

    // MARK: - Actions

    private func registerForTournament(_ tournament: Tournament) async {
        guard let userId = authService.user?.id else { return }
        do {
            _ = try await TournamentRepository().registerForTournament(
                tournamentId: tournament.id,
                userId: userId,
                teamName: nil,
                partnerId: nil
            )
            toastManager.show("Registered for tournament", type: .success)
            await loadData()
        } catch {
            toastManager.show("Registration failed: \(error.localizedDescription)", type: .error)
        }
    }

    private func updateStatus(_ tournament: Tournament, to status: String) async {
        do {
            try await TournamentRepository().updateTournamentStatus(id: tournament.id, status: status)
            toastManager.show("Tournament \(status)", type: .success)
            await loadData()
        } catch {
            toastManager.show("Failed to update status: \(error.localizedDescription)", type: .error)
        }
    }

    private func startTournament(_ tournament: Tournament) async {
        let repo = TournamentRepository()
        do {
            // Generate bracket based on format
            let generatedMatches: [TournamentMatch]
            switch session.resolvedSessionType {
            case .roundRobin:
                generatedMatches = TournamentBracketGenerator.generateRoundRobin(registrations: registrations)
            case .singleElimination:
                generatedMatches = TournamentBracketGenerator.generateElimination(registrations: registrations)
            case .doubleElimination:
                generatedMatches = TournamentBracketGenerator.generateDoubleElimination(registrations: registrations)
            case .kingOfTheCourt:
                let state = TournamentBracketGenerator.generateKingOfTheCourt(
                    registrations: registrations,
                    courtCount: 4, // TODO: make configurable
                    tournamentId: tournament.id
                )
                try await repo.upsertKingOfCourtState(state.courts)
                try await repo.replaceKingOfCourtQueue(tournamentId: tournament.id, queue: state.queue)
                try await repo.updateTournamentStatus(id: tournament.id, status: "in_progress")
                toastManager.show("Tournament started", type: .success)
                await loadData()
                return
            default:
                return
            }

            try await repo.insertMatches(generatedMatches)
            try await repo.updateTournamentStatus(id: tournament.id, status: "in_progress")
            toastManager.show("Tournament started", type: .success)
            await loadData()
        } catch {
            toastManager.show("Failed to start tournament: \(error.localizedDescription)", type: .error)
        }
    }

    private func handleScoreSaved(match: TournamentMatch) async {
        // For elimination formats, advance the bracket
        if session.resolvedSessionType == .singleElimination || session.resolvedSessionType == .doubleElimination {
            // Reload matches to get updated scores
            await loadData()

            if let updatedMatch = matches.first(where: { $0.id == match.id }),
               let winnerId = updatedMatch.winnerId {
                // Advance winner
                if let advancement = DoubleEliminationEngine.advanceWinner(
                    completedMatch: updatedMatch,
                    winnerId: winnerId,
                    allMatches: matches
                ) {
                    let teamAId = advancement.slotIsTeamA ? winnerId : advancement.advanceTo.teamAId
                    let teamBId = advancement.slotIsTeamA ? advancement.advanceTo.teamBId : winnerId
                    try? await TournamentRepository().updateMatchAdvancement(
                        matchId: advancement.advanceTo.id,
                        teamAId: teamAId,
                        teamBId: teamBId
                    )
                }

                // For double elimination, also handle loser drop-down
                if session.resolvedSessionType == .doubleElimination,
                   let loserId = updatedMatch.teamAId == winnerId ? updatedMatch.teamBId : updatedMatch.teamAId,
                   let loserEntry = DoubleEliminationEngine.findLosersEntry(
                       completedMatch: updatedMatch,
                       loserId: loserId,
                       allMatches: matches
                   ) {
                    let teamAId = loserEntry.slotIsTeamA ? loserId : loserEntry.advanceTo.teamAId
                    let teamBId = loserEntry.slotIsTeamA ? loserEntry.advanceTo.teamBId : loserId
                    try? await TournamentRepository().updateMatchAdvancement(
                        matchId: loserEntry.advanceTo.id,
                        teamAId: teamAId,
                        teamBId: teamBId
                    )
                }
            }
        }

        await loadData()
    }

    private func teamName(for registrationId: UUID?) -> String {
        guard let id = registrationId else { return "TBD" }
        return registrations.first { $0.id == id }?.teamName ?? "Team \(id.uuidString.prefix(4))"
    }
}
