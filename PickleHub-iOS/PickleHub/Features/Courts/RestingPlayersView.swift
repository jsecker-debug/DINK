import SwiftUI

struct RestingPlayersView: View {
    let resters: [String]
    let selectedPlayer: String?
    var onPlayerTapped: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Resting", systemImage: "figure.seated.side.air.distribution.upper")
                .font(.subheadline.bold())
                .foregroundStyle(.orange)

            FlowLayout(spacing: 8) {
                ForEach(resters, id: \.self) { player in
                    Button {
                        onPlayerTapped(player)
                    } label: {
                        Text(player)
                            .font(.subheadline)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(selectedPlayer == player ? Color.orange.opacity(0.3) : Color.orange.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(selectedPlayer == player ? Color.orange : .clear, lineWidth: 2)
                            )
                            .clipShape(.rect(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(player), resting")
                    .accessibilityHint("Tap to select for swap")
                    .accessibilityAddTraits(selectedPlayer == player ? .isSelected : [])
                }
            }
        }
        .padding(16)
        .background(Color.orange.opacity(0.08))
        .clipShape(.rect(cornerRadius: 10))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Resting players: \(resters.count)")
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
