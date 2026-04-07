import SwiftUI

struct RankingsView: View {
    @Environment(ClubService.self) private var clubService

    @State private var participants: [ParticipantWithProfile] = []
    @State private var sortBy: SortOption = .skillLevel
    @State private var filterBy: FilterOption = .all
    @State private var isLoading = false

    enum SortOption: String, CaseIterable {
        case skillLevel = "Skill Level"
        case winRate = "Win Rate"
        case gamesPlayed = "Games Played"
        case totalWins = "Total Wins"
        case confidence = "Confidence"
    }

    enum FilterOption: String, CaseIterable {
        case all = "All Players"
        case active = "Active (10+)"
        case male = "Male"
        case female = "Female"
        case lowConfidence = "Low Confidence"
    }

    var body: some View {
        Group {
            if isLoading && participants.isEmpty {
                LoadingView(message: "Loading rankings...")
            } else if participants.isEmpty && !isLoading {
                EmptyStateView(icon: "trophy", title: "No Rankings", message: "Rankings will appear once players have participated in sessions.")
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        overviewStats
                        sortFilterControls
                        leaderboard
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
        }
        .navigationTitle("Rankings")
        .refreshable { await loadData() }
        .task(id: clubService.selectedClubId) {
            participants = []
            await loadData()
        }
    }

    // MARK: - Overview Stats

    private var overviewStats: some View {
        let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
        return LiquidGlassContainer(spacing: 12) {
            LazyVGrid(columns: columns, spacing: 12) {
                StatCardView(title: "Total Players", value: "\(participants.count)", icon: "person.3.fill")
                StatCardView(title: "Avg Level", value: avgLevel, icon: "chart.bar.fill")
                StatCardView(title: "Top Player", value: topPlayerName, icon: "crown.fill")
                StatCardView(title: "Avg Win Rate", value: avgWinRate, icon: "percent")
            }
        }
    }

    // MARK: - Sort & Filter

    private var sortFilterControls: some View {
        HStack(spacing: 12) {
            Menu {
                ForEach(SortOption.allCases, id: \.self) { option in
                    Button {
                        sortBy = option
                    } label: {
                        Label(option.rawValue, systemImage: sortBy == option ? "checkmark" : "")
                    }
                }
            } label: {
                Label(sortBy.rawValue, systemImage: "arrow.up.arrow.down")
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(Capsule())
            }

            Menu {
                ForEach(FilterOption.allCases, id: \.self) { option in
                    Button {
                        filterBy = option
                    } label: {
                        Label(option.rawValue, systemImage: filterBy == option ? "checkmark" : "")
                    }
                }
            } label: {
                Label(filterBy.rawValue, systemImage: "line.3.horizontal.decrease")
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(Capsule())
            }

            Spacer()
        }
    }

    // MARK: - Leaderboard

    private var leaderboard: some View {
        LazyVStack(spacing: 0) {
            ForEach(Array(sortedAndFiltered.enumerated()), id: \.element.id) { index, participant in
                RankingRowView(rank: index + 1, participant: participant, sortBy: sortBy)

                if index < sortedAndFiltered.count - 1 {
                    Divider().padding(.leading, 56)
                }
            }
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(.rect(cornerRadius: 10))
        .liquidGlassStatic(cornerRadius: 10)
    }

    // MARK: - Computed

    private var sortedAndFiltered: [ParticipantWithProfile] {
        let filtered = participants.filter { p in
            switch filterBy {
            case .all: return true
            case .active: return p.totalGamesPlayed >= 10
            case .male: return p.gender?.lowercased() == "male"
            case .female: return p.gender?.lowercased() == "female"
            case .lowConfidence: return p.totalGamesPlayed < 50
            }
        }

        return filtered.sorted { a, b in
            switch sortBy {
            case .skillLevel: return (a.skillLevel ?? 0) > (b.skillLevel ?? 0)
            case .winRate: return winRate(a) > winRate(b)
            case .gamesPlayed: return a.totalGamesPlayed > b.totalGamesPlayed
            case .totalWins: return a.wins > b.wins
            case .confidence: return a.ratingConfidence > b.ratingConfidence
            }
        }
    }

    private func winRate(_ p: ParticipantWithProfile) -> Double {
        guard p.totalGamesPlayed > 0 else { return 0 }
        return Double(p.wins) / Double(p.totalGamesPlayed)
    }

    private var avgLevel: String {
        guard !participants.isEmpty else { return "0.0" }
        let total = participants.compactMap(\.skillLevel).reduce(0, +)
        let count = participants.compactMap(\.skillLevel).count
        guard count > 0 else { return "0.0" }
        return String(format: "%.1f", total / Double(count))
    }

    private var topPlayerName: String {
        participants.max { ($0.skillLevel ?? 0) < ($1.skillLevel ?? 0) }?.name ?? "-"
    }

    private var avgWinRate: String {
        guard !participants.isEmpty else { return "0%" }
        let rates = participants.map { winRate($0) }
        let avg = rates.reduce(0, +) / Double(rates.count)
        return "\(Int(avg * 100))%"
    }

    private func loadData() async {
        guard let clubId = clubService.selectedClubId else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            participants = try await MemberRepository().fetchParticipants(clubId: clubId)
        } catch {
            print("Failed to load rankings: \(error)")
        }
    }
}
