import SwiftUI

struct TournamentCourtDisplayView: View {
    let matches: [TournamentMatch]
    let registrations: [TournamentRegistration]
    var onScoreSaved: () async -> Void

    @State private var selectedMatch: TournamentMatch?

    private var teamNames: [UUID: String] {
        Dictionary(uniqueKeysWithValues: registrations.map { ($0.id, $0.teamName ?? "Team \($0.id.uuidString.prefix(4))") })
    }

    /// Matches that have court assignments and are scheduled (active on courts now)
    private var activeCourtMatches: [TournamentMatch] {
        matches
            .filter { $0.courtNumber != nil && $0.status == "scheduled" && $0.teamAId != nil && $0.teamBId != nil }
            .sorted { ($0.courtNumber ?? 0) < ($1.courtNumber ?? 0) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Live Courts", systemImage: "sportscourt.fill")
                .font(.headline)

            if activeCourtMatches.isEmpty {
                Text("No matches currently on courts")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
            } else {
                ForEach(activeCourtMatches) { match in
                    tournamentCourtCard(match)
                }
            }
        }
        .sheet(item: $selectedMatch) { match in
            TournamentScoreInputSheet(
                match: match,
                teamAName: teamName(for: match.teamAId),
                teamBName: teamName(for: match.teamBId),
                onSaved: onScoreSaved
            )
        }
    }

    private func tournamentCourtCard(_ match: TournamentMatch) -> some View {
        VStack(spacing: 12) {
            HStack {
                Text("Court \(match.courtNumber ?? 0)")
                    .font(.subheadline.bold())
                Spacer()
                bracketLabel(match)
            }

            // Court surface with teams
            HStack {
                VStack(spacing: 4) {
                    playerBubbles(teamId: match.teamAId, color: .dinkTeal)
                    Text(teamName(for: match.teamAId))
                        .font(.caption)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)

                Text("vs")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                VStack(spacing: 4) {
                    playerBubbles(teamId: match.teamBId, color: .dinkNavy)
                    Text(teamName(for: match.teamBId))
                        .font(.caption)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 8)

            Button {
                selectedMatch = match
            } label: {
                Text("Enter Score")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(.rect(cornerRadius: 12))
    }

    private func bracketLabel(_ match: TournamentMatch) -> some View {
        Group {
            if let bracket = match.bracketType {
                Text(bracketDisplayName(bracket, round: match.round))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(Capsule())
            }
        }
    }

    private func bracketDisplayName(_ bracket: String, round: Int) -> String {
        switch bracket {
        case "winners": return "Winners R\(round)"
        case "losers": return "Losers R\(round)"
        case "grand_final": return "Grand Final"
        default: return "R\(round)"
        }
    }

    private func playerBubbles(teamId: UUID?, color: Color) -> some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [color, color.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 44, height: 44)
            .overlay {
                Text(teamName(for: teamId).prefix(2).uppercased())
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
            }
    }

    private func teamName(for teamId: UUID?) -> String {
        guard let id = teamId else { return "TBD" }
        return teamNames[id] ?? "Team \(id.uuidString.prefix(4))"
    }
}
