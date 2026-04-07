import SwiftUI

struct GameScoreInputView: View {
    let sessionId: Int
    let courtNumber: Int
    let rotationNumber: Int
    let team1Players: [String]
    let team2Players: [String]

    @Environment(AuthService.self) private var authService
    @Environment(ToastManager.self) private var toastManager

    @State private var games: [GameEntry] = [GameEntry()]
    @State private var isSaving = false
    @State private var saveSuccess = false
    @State private var error: String?

    struct GameEntry: Identifiable {
        let id = UUID()
        var team1Score: Int = 0
        var team2Score: Int = 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Scores")
                    .font(.subheadline.bold())
                Spacer()
                Text("T1: \(team1Wins) - T2: \(team2Wins)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ForEach($games) { $game in
                HStack(spacing: 12) {
                    Text("G\(gameIndex(game) + 1)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 24)

                    Stepper(value: $game.team1Score, in: 0...99) {
                        Text("\(game.team1Score)")
                            .font(.subheadline)
                            .fontWeight(game.team1Score > game.team2Score ? .bold : .regular)
                            .frame(width: 32, alignment: .center)
                    }

                    Text("vs")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Stepper(value: $game.team2Score, in: 0...99) {
                        Text("\(game.team2Score)")
                            .font(.subheadline)
                            .fontWeight(game.team2Score > game.team1Score ? .bold : .regular)
                            .frame(width: 32, alignment: .center)
                    }
                }
            }

            HStack(spacing: 12) {
                if games.count < 5 {
                    Button {
                        games.append(GameEntry())
                    } label: {
                        Label("Add Game", systemImage: "plus")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                }

                if games.count > 1 {
                    Button(role: .destructive) {
                        games.removeLast()
                    } label: {
                        Label("Remove", systemImage: "minus")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                }

                Spacer()

                Button {
                    Task { await saveScores() }
                } label: {
                    Text(saveSuccess ? "Saved" : "Save")
                        .font(.subheadline.bold())
                }
                .buttonStyle(.borderedProminent)
                .disabled(isSaving)
            }

            if let error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding(.top, 8)
        .task { await loadExistingScores() }
    }

    // MARK: - Computed

    private var team1Wins: Int {
        games.filter { $0.team1Score > $0.team2Score }.count
    }

    private var team2Wins: Int {
        games.filter { $0.team2Score > $0.team1Score }.count
    }

    private func gameIndex(_ game: GameEntry) -> Int {
        games.firstIndex(where: { $0.id == game.id }) ?? 0
    }

    // MARK: - Data

    private func loadExistingScores() async {
        do {
            let existing = try await GameScoreRepository().fetchCourtScores(
                sessionId: sessionId,
                courtNumber: courtNumber,
                rotationNumber: rotationNumber
            )
            if !existing.isEmpty {
                games = existing.map { score in
                    GameEntry(team1Score: score.team1Score, team2Score: score.team2Score)
                }
            }
        } catch {
            print("Failed to load scores: \(error)")
        }
    }

    private func saveScores() async {
        guard let userId = authService.user?.id else { return }
        isSaving = true
        saveSuccess = false
        defer { isSaving = false }

        let scores = games.enumerated().map { index, game in
            (gameNumber: index + 1, team1Score: game.team1Score, team2Score: game.team2Score)
        }

        do {
            _ = try await GameScoreRepository().saveGameScores(
                sessionId: sessionId,
                courtNumber: courtNumber,
                rotationNumber: rotationNumber,
                team1Players: team1Players,
                team2Players: team2Players,
                scores: scores,
                createdBy: userId
            )
            saveSuccess = true
            toastManager.show("Scores saved", type: .success)
        } catch {
            self.error = error.localizedDescription
            toastManager.show("Failed to save scores: \(error.localizedDescription)", type: .error)
        }
    }
}
