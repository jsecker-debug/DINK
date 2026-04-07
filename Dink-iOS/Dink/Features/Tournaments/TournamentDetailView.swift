import SwiftUI

struct TournamentDetailView: View {
    @Environment(ClubService.self) private var clubService
    @Environment(AuthService.self) private var authService
    @Environment(ToastManager.self) private var toastManager

    let tournament: Tournament

    @State private var currentTournament: Tournament
    @State private var registrations: [TournamentRegistration] = []
    @State private var matches: [TournamentMatch] = []
    @State private var standings: [TournamentStanding] = []
    @State private var isLoading = false
    @State private var isRegistering = false

    private let repository = TournamentRepository()

    init(tournament: Tournament) {
        self.tournament = tournament
        _currentTournament = State(initialValue: tournament)
    }

    private var isUserRegistered: Bool {
        guard let userId = authService.userProfile?.id else { return false }
        return registrations.contains { $0.userId == userId }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                overviewSection
                actionsSection
                registrationsSection
                matchesSection
                standingsSection
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .navigationTitle(currentTournament.name)
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await loadData() }
        .task { await loadData() }
    }

    // MARK: - Overview

    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Overview", systemImage: "info.circle")
                    .font(.headline)
                Spacer()
            }

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                StatCardView(
                    title: "Format",
                    value: currentTournament.format == "round_robin" ? "Round Robin" : "Elimination",
                    icon: currentTournament.format == "round_robin" ? "arrow.triangle.2.circlepath" : "chart.bar.doc.horizontal",
                    iconColor: .dinkTeal
                )
                StatCardView(
                    title: "Status",
                    value: currentTournament.status.replacingOccurrences(of: "_", with: " ").capitalized,
                    icon: "flag",
                    iconColor: statusColor(currentTournament.status)
                )
                StatCardView(
                    title: "Team Size",
                    value: "\(currentTournament.teamSize)",
                    icon: "person.2",
                    iconColor: .dinkNavy
                )
                StatCardView(
                    title: "Registered",
                    value: "\(registrations.count)\(currentTournament.maxTeams.map { "/\($0)" } ?? "")",
                    icon: "person.3",
                    iconColor: .green
                )
            }

            if let startDate = currentTournament.startDate {
                HStack {
                    Label("Starts: \(startDate)", systemImage: "calendar")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if let endDate = currentTournament.endDate {
                        Text("- \(endDate)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if let description = currentTournament.description, !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(.rect(cornerRadius: 10))
        .liquidGlassStatic(cornerRadius: 10)
    }

    // MARK: - Actions

    @ViewBuilder
    private var actionsSection: some View {
        VStack(spacing: 8) {
            // Member registration
            if currentTournament.status == "registration" && !isUserRegistered {
                Button {
                    Task { await registerSelf() }
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Register")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isRegistering)
            } else if isUserRegistered {
                Label("You are registered", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.dinkGreen)
                    .font(.subheadline)
            }

            // Admin actions
            if clubService.isAdmin {
                adminActions
            }
        }
    }

    @ViewBuilder
    private var adminActions: some View {
        let status = currentTournament.status
        HStack(spacing: 8) {
            if status == "draft" {
                Button("Open Registration") {
                    Task { await updateStatus("registration") }
                }
                .buttonStyle(.borderedProminent)
                .tint(.dinkTeal)
            }
            if status == "registration" {
                Button("Start Tournament") {
                    Task {
                        await generateBracket()
                        await updateStatus("in_progress")
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.dinkOrange)
                .disabled(registrations.count < 2)
            }
            if status == "in_progress" {
                Button("Complete") {
                    Task { await updateStatus("completed") }
                }
                .buttonStyle(.borderedProminent)
                .tint(.dinkGreen)
            }
        }
    }

    // MARK: - Registrations

    private var registrationsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Label("Registrations (\(registrations.count))", systemImage: "person.3")
                    .font(.headline)
                Spacer()
            }
            .padding(16)

            Divider().padding(.leading, 16)

            if registrations.isEmpty {
                EmptyStateView(
                    icon: "person.slash",
                    title: "No Registrations",
                    message: "No one has registered yet."
                )
                .frame(height: 120)
            } else {
                ForEach(registrations) { reg in
                    HStack {
                        Image(systemName: "person.circle")
                            .foregroundStyle(.secondary)
                        Text(reg.teamName ?? reg.id.uuidString.prefix(8).description)
                            .font(.body)
                        Spacer()
                        BadgeView(
                            text: reg.status.capitalized,
                            style: reg.status == "confirmed" ? .success : .secondary
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)

                    if reg.id != registrations.last?.id {
                        Divider().padding(.leading, 56)
                    }
                }
            }
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(.rect(cornerRadius: 10))
        .liquidGlassStatic(cornerRadius: 10)
    }

    // MARK: - Matches

    @ViewBuilder
    private var matchesSection: some View {
        if !matches.isEmpty {
            let groupedByRound = Dictionary(grouping: matches, by: \.round).sorted { $0.key < $1.key }

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Label("Matches", systemImage: "sportscourt")
                        .font(.headline)
                    Spacer()
                }
                .padding(16)

                ForEach(groupedByRound, id: \.key) { round, roundMatches in
                    Divider().padding(.leading, 16)

                    Text("Round \(round)")
                        .font(.subheadline.bold())
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 4)

                    ForEach(roundMatches) { match in
                        matchRow(match)
                    }
                }
            }
            .background(Color(.secondarySystemBackground))
            .clipShape(.rect(cornerRadius: 10))
            .liquidGlassStatic(cornerRadius: 10)
        }
    }

    private func matchRow(_ match: TournamentMatch) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Match \(match.matchNumber)")
                    .font(.subheadline.bold())
                HStack(spacing: 4) {
                    Text(teamLabel(match.teamAId))
                    Text("vs")
                        .foregroundStyle(.secondary)
                    Text(teamLabel(match.teamBId))
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            if let scoreA = match.scoreA, let scoreB = match.scoreB {
                Text("\(scoreA) - \(scoreB)")
                    .font(.body.bold().monospacedDigit())
            }

            BadgeView(
                text: match.status.capitalized,
                style: match.status == "completed" ? .success : .secondary
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private func teamLabel(_ teamId: UUID?) -> String {
        guard let teamId else { return "TBD" }
        if let reg = registrations.first(where: { $0.id == teamId }) {
            return reg.teamName ?? String(reg.id.uuidString.prefix(8))
        }
        return String(teamId.uuidString.prefix(8))
    }

    // MARK: - Standings

    @ViewBuilder
    private var standingsSection: some View {
        if !standings.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Label("Standings", systemImage: "list.number")
                        .font(.headline)
                    Spacer()
                }
                .padding(16)

                Divider().padding(.leading, 16)

                // Header
                HStack {
                    Text("#").frame(width: 30, alignment: .leading)
                    Text("Team").frame(maxWidth: .infinity, alignment: .leading)
                    Text("W").frame(width: 30)
                    Text("L").frame(width: 30)
                    Text("PF").frame(width: 35)
                    Text("PA").frame(width: 35)
                }
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                ForEach(standings) { standing in
                    Divider().padding(.leading, 16)
                    HStack {
                        Text("\(standing.rank ?? 0)").frame(width: 30, alignment: .leading)
                        Text(teamLabel(standing.registrationId))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("\(standing.wins)").frame(width: 30)
                        Text("\(standing.losses)").frame(width: 30)
                        Text("\(standing.pointsFor)").frame(width: 35)
                        Text("\(standing.pointsAgainst)").frame(width: 35)
                    }
                    .font(.subheadline.monospacedDigit())
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
            }
            .background(Color(.secondarySystemBackground))
            .clipShape(.rect(cornerRadius: 10))
            .liquidGlassStatic(cornerRadius: 10)
        }
    }

    // MARK: - Data Loading

    private func loadData() async {
        isLoading = true
        defer { isLoading = false }

        do {
            async let regs = repository.fetchRegistrations(tournamentId: tournament.id)
            async let mtchs = repository.fetchMatches(tournamentId: tournament.id)
            async let stnds = repository.fetchStandings(tournamentId: tournament.id)

            let (loadedRegs, loadedMatches, loadedStandings) = try await (regs, mtchs, stnds)
            registrations = loadedRegs
            matches = loadedMatches
            standings = loadedStandings
        } catch {
            toastManager.show("Failed to load tournament data", type: .error)
        }
    }

    private func registerSelf() async {
        guard let userId = authService.userProfile?.id,
              clubService.selectedClubId != nil else { return }
        isRegistering = true
        defer { isRegistering = false }

        do {
            let reg = try await repository.registerForTournament(
                tournamentId: tournament.id,
                userId: userId,
                teamName: nil,
                partnerId: nil
            )
            registrations.append(reg)
            toastManager.show("Registered successfully", type: .success)
        } catch {
            toastManager.show("Registration failed: \(error.localizedDescription)", type: .error)
        }
    }

    private func updateStatus(_ newStatus: String) async {
        do {
            try await repository.updateTournamentStatus(id: tournament.id, status: newStatus)
            currentTournament = Tournament(
                id: currentTournament.id,
                clubId: currentTournament.clubId,
                name: currentTournament.name,
                description: currentTournament.description,
                format: currentTournament.format,
                status: newStatus,
                maxTeams: currentTournament.maxTeams,
                teamSize: currentTournament.teamSize,
                startDate: currentTournament.startDate,
                endDate: currentTournament.endDate,
                createdBy: currentTournament.createdBy,
                createdAt: currentTournament.createdAt
            )
            toastManager.show("Status updated to \(newStatus.replacingOccurrences(of: "_", with: " "))", type: .success)
        } catch {
            toastManager.show("Failed to update status", type: .error)
        }
    }

    private func generateBracket() async {
        guard !registrations.isEmpty else { return }

        let generatedMatches: [TournamentMatch]
        if currentTournament.format == "round_robin" {
            generatedMatches = TournamentBracketGenerator.generateRoundRobin(registrations: registrations)
        } else {
            generatedMatches = TournamentBracketGenerator.generateElimination(registrations: registrations)
        }

        // Insert matches via repository (batch insert not in repo, so insert individually)
        for match in generatedMatches {
            do {
                try await supabase
                    .from("tournament_matches")
                    .insert(match)
                    .execute()
            } catch {
                toastManager.show("Failed to generate bracket", type: .error)
                return
            }
        }

        matches = generatedMatches
        toastManager.show("Bracket generated", type: .success)
    }

    private func statusColor(_ status: String) -> Color {
        switch status {
        case "draft": .gray
        case "registration": .dinkTeal
        case "in_progress": .dinkOrange
        case "completed": .dinkGreen
        default: .gray
        }
    }
}
