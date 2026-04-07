import SwiftUI

/// Compact team list view — used outside the court visual (e.g. schedule preview).
struct TeamDisplayView: View {
    let label: String
    let players: [String]
    let selectedPlayer: String?
    var onPlayerTapped: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach(players, id: \.self) { player in
                Button {
                    onPlayerTapped(player)
                } label: {
                    Text(player)
                        .font(.subheadline)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(selectedPlayer == player ? Color.accentColor.opacity(0.2) : Color(.tertiarySystemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(selectedPlayer == player ? Color.accentColor : .clear, lineWidth: 2)
                        )
                        .clipShape(.rect(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(player)
                .accessibilityHint("Tap to select for swap")
                .accessibilityAddTraits(selectedPlayer == player ? .isSelected : [])
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
