import SwiftUI

struct RestingPlayersView: View {
    let resters: [String]
    let selectedPlayer: String?
    var onPlayerTapped: (String) -> Void
    var onPlayerDropped: ((String, String) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Resting", systemImage: "figure.seated.side.air.distribution.upper")
                .font(.subheadline.bold())
                .foregroundStyle(.dinkOrange)

            FlowLayout(spacing: 8) {
                ForEach(resters.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }, id: \.self) { player in
                    resterChip(player: player)
                }
            }
        }
        .padding(16)
        .background(Color.dinkOrange.opacity(0.08))
        .clipShape(.rect(cornerRadius: 10))
        .dropDestination(for: String.self) { items, _ in
            // Allow dropping a court player into the resting area
            // The swap is handled by matching the dropped player against the first rester
            // But we need a target — use the onPlayerDropped with a sentinel or handle in parent
            guard let droppedPlayer = items.first else { return false }
            // If the dropped player is already resting, ignore
            if resters.contains(droppedPlayer) { return false }
            // Swap with the first rester (or handle specially in parent)
            if let firstRester = resters.first {
                onPlayerDropped?(droppedPlayer, firstRester)
            }
            return true
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Resting players: \(resters.count)")
    }

    private func resterChip(player: String) -> some View {
        let isSelected = selectedPlayer == player

        return Button {
            onPlayerTapped(player)
        } label: {
            HStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.dinkOrange, .dinkOrange.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 28, height: 28)

                    Text(player.playerInitials)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                }

                Text(player.components(separatedBy: " ").first ?? player)
                    .font(.subheadline)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? Color.dinkOrange.opacity(0.3) : Color.dinkOrange.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.dinkOrange : .clear, lineWidth: 2)
            )
            .clipShape(.rect(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .draggable(player)
        .dropDestination(for: String.self) { items, _ in
            guard let droppedPlayer = items.first, droppedPlayer != player else { return false }
            onPlayerDropped?(droppedPlayer, player)
            return true
        }
        .accessibilityLabel("\(player), resting")
        .accessibilityHint("Tap to select for swap, or drag to swap.")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Flow Layout for wrapping chips

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(in: proposal.width ?? 0, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(in: bounds.width, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func layout(in width: CGFloat, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var maxHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width && x > 0 {
                x = 0
                y += maxHeight + spacing
                maxHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            maxHeight = max(maxHeight, size.height)
            x += size.width + spacing
            totalHeight = y + maxHeight
        }

        return (CGSize(width: width, height: totalHeight), positions)
    }
}
