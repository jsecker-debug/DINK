import SwiftUI

struct ScheduleGeneratorView: View {
    let sessionId: Int
    let participants: [String]
    var onSaved: () async -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(ToastManager.self) private var toastManager

    @State private var courts = 2
    @State private var rounds = 4
    @State private var generatedResult: ScheduleGenerationResult?
    @State private var editedRotations: [ScheduleRotation] = []
    @State private var selectedRotationIndex = 0
    @State private var selectedPlayer: String?
    @State private var error: String?
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                if generatedResult == nil {
                    settingsSection
                } else {
                    previewSection
                }
            }
            .navigationTitle("Generate Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    // MARK: - Settings

    private var settingsSection: some View {
        Group {
            Section("Settings") {
                Stepper("Courts: \(courts)", value: $courts, in: 1...10)
                Stepper("Rounds: \(rounds)", value: $rounds, in: 1...20)
            }

            Section("Players (\(participants.count))") {
                FlowLayout(spacing: 8) {
                    ForEach(participants, id: \.self) { name in
                        Text(name)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.tertiarySystemBackground))
                            .clipShape(Capsule())
                    }
                }
            }

            if let error {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.subheadline)
                }
            }

            Section {
                Button {
                    generate()
                } label: {
                    Label("Generate Schedule", systemImage: "sportscourt.fill")
                        .frame(maxWidth: .infinity)
                }
                .disabled(participants.count < 4)
            }
        }
    }

    // MARK: - Preview

    private var previewSection: some View {
        Group {
            if let result = generatedResult {
                Section {
                    Text("\(result.roundsGenerated) rounds, \(result.courtsUsed) courts")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("Drag players between positions to adjust before saving.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                // Round picker
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(editedRotations.indices, id: \.self) { index in
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
                            }
                        }
                    }
                }

                // Court visuals for selected round
                if editedRotations.indices.contains(selectedRotationIndex) {
                    Section {
                        let rotation = editedRotations[selectedRotationIndex]
                        ForEach(rotation.courts.indices, id: \.self) { courtIndex in
                            CourtCardView(
                                court: rotation.courts[courtIndex],
                                courtNumber: courtIndex + 1,
                                selectedPlayer: selectedPlayer,
                                showScoring: false,
                                sessionId: sessionId,
                                rotationNumber: selectedRotationIndex + 1,
                                onPlayerTapped: { player in handlePreviewTap(player) },
                                onPlayerDropped: { source, target in handlePreviewDrop(source: source, target: target) }
                            )
                            .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                        }

                        if !rotation.resters.isEmpty {
                            RestingPlayersView(
                                resters: rotation.resters,
                                selectedPlayer: selectedPlayer,
                                onPlayerTapped: { player in handlePreviewTap(player) },
                                onPlayerDropped: { source, target in handlePreviewDrop(source: source, target: target) }
                            )
                            .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                        }
                    }
                }

                Section {
                    Button {
                        generatedResult = nil
                        editedRotations = []
                        selectedRotationIndex = 0
                        selectedPlayer = nil
                        error = nil
                    } label: {
                        Label("Back to Settings", systemImage: "arrow.left")
                    }

                    Button {
                        Task { await saveSchedule(editedRotations) }
                    } label: {
                        Label("Save Schedule", systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(isSaving)
                }
            }
        }
    }

    // MARK: - Preview Swap (Tap)

    private func handlePreviewTap(_ player: String) {
        if let selected = selectedPlayer {
            if selected == player {
                selectedPlayer = nil
                return
            }
            guard editedRotations.indices.contains(selectedRotationIndex) else { return }
            let rotation = editedRotations[selectedRotationIndex]
            do {
                let updated = try PlayerSwapService.handlePlayerSwap(
                    selectedPlayer: selected,
                    targetPlayer: player,
                    rotation: rotation
                )
                editedRotations[selectedRotationIndex] = updated
                selectedPlayer = nil
                HapticService.notification(.success)
            } catch {
                self.error = error.localizedDescription
                selectedPlayer = nil
                HapticService.notification(.error)
            }
        } else {
            selectedPlayer = player
            HapticService.selection()
        }
    }

    // MARK: - Preview Swap (Drag & Drop)

    private func handlePreviewDrop(source: String, target: String) {
        guard editedRotations.indices.contains(selectedRotationIndex) else { return }
        let rotation = editedRotations[selectedRotationIndex]
        do {
            let updated = try PlayerSwapService.handlePlayerSwap(
                selectedPlayer: source,
                targetPlayer: target,
                rotation: rotation
            )
            editedRotations[selectedRotationIndex] = updated
            selectedPlayer = nil
            HapticService.notification(.success)
        } catch {
            self.error = error.localizedDescription
            HapticService.notification(.error)
        }
    }

    // MARK: - Logic

    private func generate() {
        let players = participants.enumerated().map { index, name in
            SessionPlayer(id: "\(index)", name: name, skillLevel: nil)
        }
        let settings = ScheduleSettings(courts: courts, rounds: rounds)

        do {
            let result = try ScheduleGenerator.generate(players: players, settings: settings)
            generatedResult = result
            editedRotations = result.rotations
            selectedRotationIndex = 0
            selectedPlayer = nil
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func saveSchedule(_ rotations: [ScheduleRotation]) async {
        isSaving = true
        defer { isSaving = false }
        do {
            try await RotationRepository().saveSchedule(sessionId: sessionId, rotations: rotations)
            await onSaved()
            toastManager.show("Schedule saved", type: .success)
            dismiss()
        } catch {
            self.error = error.localizedDescription
            toastManager.show("Failed to save schedule: \(error.localizedDescription)", type: .error)
        }
    }
}
