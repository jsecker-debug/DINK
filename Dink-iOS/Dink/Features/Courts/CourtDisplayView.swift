import SwiftUI

struct CourtDisplayView: View {
    let rotations: [ScheduleRotation]
    let sessionId: Int
    let isAdmin: Bool
    var onRotationUpdated: () async -> Void

    @State private var selectedRotationIndex = 0
    @State private var selectedPlayer: String?
    @State private var showScoring = false
    @State private var swapError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            rotationPicker
            if rotations.indices.contains(selectedRotationIndex) {
                courtGrid(for: rotations[selectedRotationIndex])
            }
            scoringToggle
        }
    }

    // MARK: - Rotation Picker

    private var rotationPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(rotations.indices, id: \.self) { index in
                    Button {
                        selectedRotationIndex = index
                        selectedPlayer = nil
                    } label: {
                        Text("Round \(index + 1)")
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selectedRotationIndex == index ? Color.accentColor : Color(.secondarySystemBackground))
                            .foregroundStyle(selectedRotationIndex == index ? .white : .primary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Round \(index + 1)")
                    .accessibilityAddTraits(selectedRotationIndex == index ? .isSelected : [])
                }
            }
        }
    }

    // MARK: - Court Grid

    private func courtGrid(for rotation: ScheduleRotation) -> some View {
        VStack(spacing: 12) {
            ForEach(rotation.courts.indices, id: \.self) { courtIndex in
                CourtCardView(
                    court: rotation.courts[courtIndex],
                    courtNumber: courtIndex + 1,
                    selectedPlayer: selectedPlayer,
                    showScoring: showScoring,
                    sessionId: sessionId,
                    rotationNumber: selectedRotationIndex + 1,
                    onPlayerTapped: { player in handlePlayerTap(player, courtIndex: courtIndex) },
                    onPlayerDropped: { source, target in handlePlayerDrop(source: source, target: target) }
                )
            }

            if !rotation.resters.isEmpty {
                RestingPlayersView(
                    resters: rotation.resters,
                    selectedPlayer: selectedPlayer,
                    onPlayerTapped: { player in handlePlayerTap(player, courtIndex: nil) },
                    onPlayerDropped: { source, target in handlePlayerDrop(source: source, target: target) }
                )
            }

            if let error = swapError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    // MARK: - Scoring Toggle

    private var scoringToggle: some View {
        HStack {
            Button {
                showScoring.toggle()
            } label: {
                Label(showScoring ? "Hide Scoring" : "Show Scoring", systemImage: "number.square")
                    .font(.subheadline)
            }
            .buttonStyle(.bordered)

            if isAdmin {
                Spacer()
                Button {
                    Task {
                        try? await GameScoreRepository().triggerSessionRatingUpdates(sessionId: sessionId)
                    }
                } label: {
                    Label("Update Ratings", systemImage: "arrow.triangle.2.circlepath")
                        .font(.subheadline)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    // MARK: - Player Swap (Tap)

    private func handlePlayerTap(_ player: String, courtIndex: Int?) {
        swapError = nil

        if let selected = selectedPlayer {
            if selected == player {
                selectedPlayer = nil
                return
            }

            guard rotations.indices.contains(selectedRotationIndex) else { return }
            let rotation = rotations[selectedRotationIndex]

            do {
                let updatedRotation = try PlayerSwapService.handlePlayerSwap(
                    selectedPlayer: selected,
                    targetPlayer: player,
                    rotation: rotation
                )
                var updated = rotations
                updated[selectedRotationIndex] = updatedRotation
                selectedPlayer = nil
                HapticService.notification(.success)

                Task {
                    try? await RotationRepository().updateRotation(
                        rotation: updatedRotation,
                        sessionId: sessionId
                    )
                    await onRotationUpdated()
                }
            } catch {
                swapError = error.localizedDescription
                selectedPlayer = nil
                HapticService.notification(.error)
            }
        } else {
            selectedPlayer = player
            HapticService.selection()
        }
    }

    // MARK: - Player Swap (Drag & Drop)

    private func handlePlayerDrop(source: String, target: String) {
        swapError = nil
        guard rotations.indices.contains(selectedRotationIndex) else { return }
        let rotation = rotations[selectedRotationIndex]

        do {
            let updatedRotation = try PlayerSwapService.handlePlayerSwap(
                selectedPlayer: source,
                targetPlayer: target,
                rotation: rotation
            )
            selectedPlayer = nil
            HapticService.notification(.success)

            Task {
                try? await RotationRepository().updateRotation(
                    rotation: updatedRotation,
                    sessionId: sessionId
                )
                await onRotationUpdated()
            }
        } catch {
            swapError = error.localizedDescription
            HapticService.notification(.error)
        }
    }
}
