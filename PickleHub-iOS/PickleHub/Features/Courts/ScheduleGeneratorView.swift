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
                Section("Generated: \(result.roundsGenerated) rounds, \(result.courtsUsed) courts") {
                    ForEach(result.rotations.indices, id: \.self) { rotIndex in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Round \(rotIndex + 1)")
                                .font(.subheadline.bold())
                            ForEach(result.rotations[rotIndex].courts.indices, id: \.self) { courtIndex in
                                let court = result.rotations[rotIndex].courts[courtIndex]
                                Text("Court \(courtIndex + 1): \(court.team1.joined(separator: ", ")) vs \(court.team2.joined(separator: ", "))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            if !result.rotations[rotIndex].resters.isEmpty {
                                Text("Resting: \(result.rotations[rotIndex].resters.joined(separator: ", "))")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                }

                Section {
                    Button {
                        generatedResult = nil
                        error = nil
                    } label: {
                        Label("Back to Settings", systemImage: "arrow.left")
                    }

                    Button {
                        Task { await saveSchedule(result.rotations) }
                    } label: {
                        Label("Save Schedule", systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(isSaving)
                }
            }
        }
    }

    // MARK: - Logic

    private func generate() {
        let players = participants.enumerated().map { index, name in
            SessionPlayer(id: "\(index)", name: name, skillLevel: nil)
        }
        let settings = ScheduleSettings(courts: courts, rounds: rounds)

        do {
            generatedResult = try ScheduleGenerator.generate(players: players, settings: settings)
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
