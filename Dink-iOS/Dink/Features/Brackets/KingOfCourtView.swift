import SwiftUI

struct KingOfCourtView: View {
    let courts: [KingOfCourtState]
    let queue: [KingOfCourtQueue]
    let standings: [TournamentStanding]
    let registrations: [TournamentRegistration]
    var onReportResult: ((Int) -> Void)? = nil  // courtNumber

    private var teamNames: [UUID: String] {
        Dictionary(uniqueKeysWithValues: registrations.map { ($0.id, $0.teamName ?? "Team \($0.id.uuidString.prefix(4))") })
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                activeCourtsSection
                queueSection
                leaderboardSection
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Active Courts

    private var activeCourtsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Active Courts", systemImage: "sportscourt.fill")
                .font(.headline)

            if courts.isEmpty {
                Text("No active courts")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(courts) { court in
                    courtCard(court)
                }
            }
        }
    }

    private func courtCard(_ court: KingOfCourtState) -> some View {
        VStack(spacing: 12) {
            HStack {
                Text("Court \(court.courtNumber)")
                    .font(.subheadline.bold())
                Spacer()
                if court.streak > 0 {
                    Label("\(court.streak) streak", systemImage: "flame.fill")
                        .font(.caption.bold())
                        .foregroundStyle(.dinkOrange)
                }
            }

            HStack {
                // King team
                VStack(spacing: 4) {
                    Image(systemName: "crown.fill")
                        .foregroundStyle(.yellow)
                        .font(.caption)
                    Text(court.currentTeamId.flatMap { teamNames[$0] } ?? "Empty")
                        .font(.subheadline.bold())
                }
                .frame(maxWidth: .infinity)

                Text("vs")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                // Challenger (first in queue)
                VStack(spacing: 4) {
                    Image(systemName: "figure.run")
                        .foregroundStyle(.dinkTeal)
                        .font(.caption)
                    Text(nextChallenger ?? "Waiting...")
                        .font(.subheadline)
                }
                .frame(maxWidth: .infinity)
            }

            Button {
                onReportResult?(court.courtNumber)
            } label: {
                Text("Report Result")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(.rect(cornerRadius: 12))
    }

    private var nextChallenger: String? {
        guard let first = queue.sorted(by: { $0.queuePosition < $1.queuePosition }).first else { return nil }
        return teamNames[first.teamId]
    }

    // MARK: - Queue

    private var queueSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Queue", systemImage: "person.3.sequence")
                .font(.headline)

            if queue.isEmpty {
                Text("Queue is empty")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(queue.sorted(by: { $0.queuePosition < $1.queuePosition })) { item in
                    HStack(spacing: 12) {
                        Text("#\(item.queuePosition)")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                            .frame(width: 30)
                        Text(teamNames[item.teamId] ?? "Unknown")
                            .font(.subheadline)
                        Spacer()
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                }
            }
        }
    }

    // MARK: - Leaderboard

    private var leaderboardSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Leaderboard", systemImage: "list.number")
                .font(.headline)

            if standings.isEmpty {
                Text("No games played yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                // Header
                HStack(spacing: 0) {
                    Text("#").font(.caption2.bold()).frame(width: 24)
                    Text("Team").font(.caption2.bold()).frame(maxWidth: .infinity, alignment: .leading)
                    Text("W").font(.caption2.bold()).frame(width: 30)
                    Text("L").font(.caption2.bold()).frame(width: 30)
                    Text("Streak").font(.caption2.bold()).frame(width: 50)
                    Text("Best").font(.caption2.bold()).frame(width: 40)
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)

                ForEach(standings.sorted(by: { $0.wins > $1.wins })) { standing in
                    HStack(spacing: 0) {
                        Text("\(standing.rank ?? 0)")
                            .font(.caption.bold())
                            .frame(width: 24)
                        Text(teamNames[standing.registrationId] ?? "Unknown")
                            .font(.subheadline)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("\(standing.wins)")
                            .font(.caption.bold())
                            .frame(width: 30)
                        Text("\(standing.losses)")
                            .font(.caption)
                            .frame(width: 30)
                        Text("\(standing.currentStreak ?? 0)")
                            .font(.caption)
                            .frame(width: 50)
                        HStack(spacing: 2) {
                            if (standing.maxStreak ?? 0) >= 3 {
                                Image(systemName: "flame.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.dinkOrange)
                            }
                            Text("\(standing.maxStreak ?? 0)")
                                .font(.caption)
                        }
                        .frame(width: 40)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                }
            }
        }
    }
}
