import SwiftUI

struct MatchPosition: Equatable {
    let matchId: UUID
    let round: Int
    let center: CGPoint
}

struct MatchPositionKey: PreferenceKey {
    nonisolated(unsafe) static var defaultValue: [MatchPosition] = []
    static func reduce(value: inout [MatchPosition], nextValue: () -> [MatchPosition]) {
        value.append(contentsOf: nextValue())
    }
}

struct BracketConnectorOverlay: View {
    let positions: [MatchPosition]
    let roundSpacing: CGFloat

    var body: some View {
        Canvas { context, size in
            let grouped = Dictionary(grouping: positions, by: \.round)
            let sortedRounds = grouped.keys.sorted()

            for i in 0..<(sortedRounds.count - 1) {
                let currentRound = sortedRounds[i]
                let nextRound = sortedRounds[i + 1]

                guard let currentMatches = grouped[currentRound]?.sorted(by: { $0.center.y < $1.center.y }),
                      let nextMatches = grouped[nextRound]?.sorted(by: { $0.center.y < $1.center.y }) else { continue }

                // Each pair of current round matches feeds into one next round match
                for (j, nextMatch) in nextMatches.enumerated() {
                    let feeders = [j * 2, j * 2 + 1].compactMap { idx in
                        idx < currentMatches.count ? currentMatches[idx] : nil
                    }

                    for feeder in feeders {
                        drawConnector(context: context, from: feeder.center, to: nextMatch.center)
                    }
                }
            }
        }
    }

    private func drawConnector(context: GraphicsContext, from: CGPoint, to: CGPoint) {
        let midX = (from.x + to.x) / 2

        var path = Path()
        path.move(to: from)
        path.addLine(to: CGPoint(x: midX, y: from.y))
        path.addLine(to: CGPoint(x: midX, y: to.y))
        path.addLine(to: to)

        context.stroke(path, with: .color(.secondary.opacity(0.4)), lineWidth: 1.5)
    }
}
