import SwiftUI

struct CourtCardView: View {
    let court: Court
    let courtNumber: Int
    let selectedPlayer: String?
    let showScoring: Bool
    let sessionId: Int
    let rotationNumber: Int
    var onPlayerTapped: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Court \(courtNumber)")
                .font(.subheadline.bold())

            HStack(spacing: 16) {
                TeamDisplayView(
                    label: "Team 1",
                    players: court.team1,
                    selectedPlayer: selectedPlayer,
                    onPlayerTapped: onPlayerTapped
                )

                Divider().frame(height: 40)

                TeamDisplayView(
                    label: "Team 2",
                    players: court.team2,
                    selectedPlayer: selectedPlayer,
                    onPlayerTapped: onPlayerTapped
                )
            }

            if showScoring {
                GameScoreInputView(
                    sessionId: sessionId,
                    courtNumber: courtNumber,
                    rotationNumber: rotationNumber,
                    team1Players: court.team1,
                    team2Players: court.team2
                )
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(.rect(cornerRadius: 10))
        .liquidGlassStatic(cornerRadius: 10)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Court \(courtNumber)")
    }
}
