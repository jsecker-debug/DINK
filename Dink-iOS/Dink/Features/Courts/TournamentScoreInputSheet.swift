import SwiftUI

struct TournamentScoreInputSheet: View {
    let match: TournamentMatch
    let teamAName: String
    let teamBName: String
    var onSaved: () async -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(ToastManager.self) private var toastManager

    @State private var scoreA = 0
    @State private var scoreB = 0
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Text("Enter Score")
                    .font(.headline)

                HStack(spacing: 24) {
                    // Team A
                    VStack(spacing: 12) {
                        Text(teamAName)
                            .font(.subheadline.bold())
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                        Stepper("\(scoreA)", value: $scoreA, in: 0...99)
                            .labelsHidden()
                        Text("\(scoreA)")
                            .font(.system(size: 48, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)

                    Text("vs")
                        .font(.title3)
                        .foregroundStyle(.secondary)

                    // Team B
                    VStack(spacing: 12) {
                        Text(teamBName)
                            .font(.subheadline.bold())
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                        Stepper("\(scoreB)", value: $scoreB, in: 0...99)
                            .labelsHidden()
                        Text("\(scoreB)")
                            .font(.system(size: 48, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 24)

                Spacer()
            }
            .padding(.top, 24)
            .navigationTitle("Match Score")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await saveScore() }
                    }
                    .disabled(isSaving || scoreA == scoreB)
                }
            }
        }
    }

    private func saveScore() async {
        isSaving = true
        defer { isSaving = false }

        let winnerId = scoreA > scoreB ? match.teamAId : match.teamBId

        do {
            try await TournamentRepository().updateMatchScore(
                matchId: match.id,
                scoreA: scoreA,
                scoreB: scoreB,
                winnerId: winnerId
            )
            await onSaved()
            toastManager.show("Score saved", type: .success)
            dismiss()
        } catch {
            toastManager.show("Failed to save score: \(error.localizedDescription)", type: .error)
        }
    }
}
