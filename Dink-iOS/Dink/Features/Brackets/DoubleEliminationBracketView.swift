import SwiftUI

struct DoubleEliminationBracketView: View {
    let matches: [TournamentMatch]
    let registrations: [TournamentRegistration]
    var onMatchTapped: ((TournamentMatch) -> Void)? = nil

    @State private var selectedBracket = "winners"

    private var winnersMatches: [TournamentMatch] {
        matches.filter { $0.bracketType == "winners" }
    }

    private var losersMatches: [TournamentMatch] {
        matches.filter { $0.bracketType == "losers" }
    }

    private var grandFinalMatches: [TournamentMatch] {
        matches.filter { $0.bracketType == "grand_final" }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Bracket selector
            Picker("Bracket", selection: $selectedBracket) {
                Text("Winners").tag("winners")
                Text("Losers").tag("losers")
                Text("Final").tag("grand_final")
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            switch selectedBracket {
            case "winners":
                SingleEliminationBracketView(
                    matches: winnersMatches,
                    registrations: registrations,
                    onMatchTapped: onMatchTapped
                )
            case "losers":
                SingleEliminationBracketView(
                    matches: losersMatches,
                    registrations: registrations,
                    onMatchTapped: onMatchTapped
                )
            case "grand_final":
                grandFinalView
            default:
                EmptyView()
            }
        }
    }

    private var grandFinalView: some View {
        VStack(spacing: 16) {
            Text("Grand Final")
                .font(.headline)

            if let finalMatch = grandFinalMatches.first {
                MatchCardView(
                    match: finalMatch,
                    teamAName: teamName(for: finalMatch.teamAId, label: "Winners Champion"),
                    teamBName: teamName(for: finalMatch.teamBId, label: "Losers Champion"),
                    onTap: finalMatch.teamAId != nil && finalMatch.teamBId != nil ? { onMatchTapped?(finalMatch) } : nil
                )
            } else {
                Text("Grand Final not yet determined")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func teamName(for teamId: UUID?, label: String) -> String {
        guard let id = teamId else { return label }
        return registrations.first { $0.id == id }?.teamName ?? "Team \(id.uuidString.prefix(4))"
    }
}
