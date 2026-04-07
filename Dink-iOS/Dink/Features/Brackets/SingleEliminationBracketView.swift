import SwiftUI

struct SingleEliminationBracketView: View {
    let matches: [TournamentMatch]
    let registrations: [TournamentRegistration]
    var onMatchTapped: ((TournamentMatch) -> Void)? = nil

    @State private var positions: [MatchPosition] = []
    @State private var zoomScale: CGFloat = 1.0

    private var teamNames: [UUID: String] {
        Dictionary(uniqueKeysWithValues: registrations.map { ($0.id, $0.teamName ?? "Team \($0.id.uuidString.prefix(4))") })
    }

    private var rounds: [[TournamentMatch]] {
        let grouped = Dictionary(grouping: matches, by: \.round)
        return grouped.keys.sorted().map { grouped[$0]!.sorted { $0.matchNumber < $1.matchNumber } }
    }

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            bracketContent
                .scaleEffect(zoomScale)
                .padding(20)
                .onPreferenceChange(MatchPositionKey.self) { positions = $0 }
        }
        .gesture(
            MagnifyGesture()
                .onChanged { value in
                    zoomScale = min(max(value.magnification, 0.5), 2.0)
                }
        )
    }

    private var bracketContent: some View {
        ZStack {
            // Connector lines
            BracketConnectorOverlay(positions: positions, roundSpacing: 200)

            // Match cards by round
            HStack(alignment: .top, spacing: 40) {
                ForEach(Array(rounds.enumerated()), id: \.offset) { roundIndex, roundMatches in
                    VStack(spacing: spacingForRound(roundIndex)) {
                        ForEach(roundMatches) { match in
                            MatchCardView(
                                match: match,
                                teamAName: teamName(for: match.teamAId),
                                teamBName: teamName(for: match.teamBId),
                                isCompact: rounds.count > 4,
                                onTap: match.teamAId != nil && match.teamBId != nil ? { onMatchTapped?(match) } : nil
                            )
                            .background(
                                GeometryReader { geo in
                                    Color.clear.preference(
                                        key: MatchPositionKey.self,
                                        value: [MatchPosition(
                                            matchId: match.id,
                                            round: roundIndex + 1,
                                            center: CGPoint(
                                                x: geo.frame(in: .named("bracket")).midX,
                                                y: geo.frame(in: .named("bracket")).midY
                                            )
                                        )]
                                    )
                                }
                            )
                        }
                    }
                    .frame(minHeight: 0, maxHeight: .infinity)

                    if roundIndex < rounds.count - 1 {
                        // Round label
                        VStack {
                            Spacer()
                            Text(roundLabel(roundIndex + 1))
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                                .rotationEffect(.degrees(-90))
                            Spacer()
                        }
                        .frame(width: 16)
                    }
                }
            }
            .coordinateSpace(name: "bracket")
        }
    }

    private func spacingForRound(_ roundIndex: Int) -> CGFloat {
        let base: CGFloat = 20
        return base * pow(2.0, CGFloat(roundIndex))
    }

    private func teamName(for teamId: UUID?) -> String {
        guard let id = teamId else { return "" }
        return teamNames[id] ?? "Team \(id.uuidString.prefix(4))"
    }

    private func roundLabel(_ round: Int) -> String {
        let totalRounds = rounds.count
        if round == totalRounds { return "Final" }
        if round == totalRounds - 1 { return "Semis" }
        if round == totalRounds - 2 { return "Quarters" }
        return "Round \(round)"
    }
}
