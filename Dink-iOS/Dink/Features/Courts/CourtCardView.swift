import SwiftUI

// MARK: - Initials Helper

extension String {
    var playerInitials: String {
        let parts = split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String(prefix(2)).uppercased()
    }
}

// MARK: - Court Card View (2D Court Visual)

struct CourtCardView: View {
    let court: Court
    let courtNumber: Int
    let selectedPlayer: String?
    let showScoring: Bool
    let sessionId: Int
    let rotationNumber: Int
    var onPlayerTapped: (String) -> Void
    var onPlayerDropped: ((String, String) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Court \(courtNumber)")
                .font(.subheadline.bold())

            courtSurface

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
        .clipShape(.rect(cornerRadius: 12))
        .liquidGlassStatic(cornerRadius: 12)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Court \(courtNumber)")
    }

    // MARK: - Court Surface

    private var courtSurface: some View {
        ZStack {
            // Court background
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.dinkGreen.opacity(0.15))

            // Court lines
            courtLines

            // Players positioned on court
            HStack(spacing: 0) {
                // Team 1 (left side)
                teamHalf(players: court.team1, isLeftSide: true)

                // Team 2 (right side)
                teamHalf(players: court.team2, isLeftSide: false)
            }
            .padding(12)
        }
        .frame(height: 160)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Court Lines

    private var courtLines: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            // Outer boundary
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.5), lineWidth: 1.5)

            // Net (center vertical line)
            Path { path in
                path.move(to: CGPoint(x: w / 2, y: 4))
                path.addLine(to: CGPoint(x: w / 2, y: h - 4))
            }
            .stroke(Color.white.opacity(0.7), style: StrokeStyle(lineWidth: 2, dash: [6, 4]))

            // Kitchen / NVZ lines (parallel to net, offset inward)
            let kitchenOffset: CGFloat = w * 0.22
            Path { path in
                path.move(to: CGPoint(x: w / 2 - kitchenOffset, y: 4))
                path.addLine(to: CGPoint(x: w / 2 - kitchenOffset, y: h - 4))
            }
            .stroke(Color.white.opacity(0.3), lineWidth: 1)

            Path { path in
                path.move(to: CGPoint(x: w / 2 + kitchenOffset, y: 4))
                path.addLine(to: CGPoint(x: w / 2 + kitchenOffset, y: h - 4))
            }
            .stroke(Color.white.opacity(0.3), lineWidth: 1)

            // Center horizontal line on each side
            Path { path in
                path.move(to: CGPoint(x: w / 2 - kitchenOffset, y: h / 2))
                path.addLine(to: CGPoint(x: 4, y: h / 2))
            }
            .stroke(Color.white.opacity(0.25), lineWidth: 1)

            Path { path in
                path.move(to: CGPoint(x: w / 2 + kitchenOffset, y: h / 2))
                path.addLine(to: CGPoint(x: w - 4, y: h / 2))
            }
            .stroke(Color.white.opacity(0.25), lineWidth: 1)
        }
    }

    // MARK: - Team Half

    private func teamHalf(players: [String], isLeftSide: Bool) -> some View {
        VStack(spacing: 16) {
            ForEach(players, id: \.self) { player in
                playerBubble(player: player, teamColor: isLeftSide ? .dinkTeal : .dinkNavy)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Player Bubble

    private func playerBubble(player: String, teamColor: Color) -> some View {
        let isSelected = selectedPlayer == player

        return Button {
            onPlayerTapped(player)
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: isSelected
                                    ? [Color.accentColor, Color.accentColor.opacity(0.7)]
                                    : [teamColor, teamColor.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle()
                                .stroke(isSelected ? Color.accentColor : .clear, lineWidth: 3)
                                .scaleEffect(1.15)
                        )
                        .shadow(color: isSelected ? Color.accentColor.opacity(0.5) : .clear, radius: 6)

                    Text(player.playerInitials)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                }

                Text(player.components(separatedBy: " ").first ?? player)
                    .font(.caption2)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
        .draggable(player)
        .dropDestination(for: String.self) { items, _ in
            guard let droppedPlayer = items.first, droppedPlayer != player else { return false }
            onPlayerDropped?(droppedPlayer, player)
            return true
        }
        .accessibilityLabel(player)
        .accessibilityHint(isSelected ? "Selected. Tap another player to swap." : "Tap to select for swap, or drag to swap.")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
