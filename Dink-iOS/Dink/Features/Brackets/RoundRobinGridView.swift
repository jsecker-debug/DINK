import SwiftUI

struct RoundRobinGridView: View {
    let matches: [TournamentMatch]
    let registrations: [TournamentRegistration]
    let standings: [TournamentStanding]
    var onMatchTapped: ((TournamentMatch) -> Void)? = nil

    private var teamNames: [UUID: String] {
        Dictionary(uniqueKeysWithValues: registrations.map { ($0.id, $0.teamName ?? "Team \($0.id.uuidString.prefix(4))") })
    }

    private var teamIds: [UUID] {
        registrations.map(\.id)
    }

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            VStack(alignment: .leading, spacing: 0) {
                // Header row
                HStack(spacing: 0) {
                    Text("")
                        .frame(width: 100, height: 40)
                    ForEach(teamIds, id: \.self) { teamId in
                        Text(teamNames[teamId] ?? "?")
                            .font(.caption2.bold())
                            .frame(width: 70, height: 40)
                            .lineLimit(1)
                    }
                    // Summary headers
                    Text("W").font(.caption2.bold()).frame(width: 35, height: 40)
                    Text("L").font(.caption2.bold()).frame(width: 35, height: 40)
                    Text("PF").font(.caption2.bold()).frame(width: 35, height: 40)
                    Text("PA").font(.caption2.bold()).frame(width: 35, height: 40)
                }

                ForEach(Array(teamIds.enumerated()), id: \.element) { rowIndex, rowTeamId in
                    HStack(spacing: 0) {
                        // Row header
                        Text(teamNames[rowTeamId] ?? "?")
                            .font(.caption.bold())
                            .frame(width: 100, height: 44, alignment: .leading)
                            .padding(.leading, 8)
                            .lineLimit(1)

                        // Match cells
                        ForEach(Array(teamIds.enumerated()), id: \.element) { colIndex, colTeamId in
                            if rowTeamId == colTeamId {
                                // Diagonal - self vs self
                                Rectangle()
                                    .fill(Color(.tertiarySystemBackground))
                                    .frame(width: 70, height: 44)
                            } else if let match = findMatch(teamA: rowTeamId, teamB: colTeamId) {
                                matchCell(match: match, isRowTeam: true)
                                    .frame(width: 70, height: 44)
                            } else {
                                Text("-")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                                    .frame(width: 70, height: 44)
                            }
                        }

                        // Summary columns
                        if let standing = standings.first(where: { $0.registrationId == rowTeamId }) {
                            Text("\(standing.wins)").font(.caption.bold()).frame(width: 35, height: 44)
                            Text("\(standing.losses)").font(.caption).frame(width: 35, height: 44)
                            Text("\(standing.pointsFor)").font(.caption).frame(width: 35, height: 44)
                            Text("\(standing.pointsAgainst)").font(.caption).frame(width: 35, height: 44)
                        } else {
                            ForEach(0..<4, id: \.self) { _ in
                                Text("0").font(.caption).frame(width: 35, height: 44)
                            }
                        }
                    }
                    .background(rowIndex % 2 == 0 ? Color(.systemBackground) : Color(.secondarySystemBackground).opacity(0.5))
                }
            }
            .padding(8)
        }
        .background(Color(.systemBackground))
        .clipShape(.rect(cornerRadius: 12))
    }

    private func findMatch(teamA: UUID, teamB: UUID) -> TournamentMatch? {
        matches.first { match in
            (match.teamAId == teamA && match.teamBId == teamB) ||
            (match.teamAId == teamB && match.teamBId == teamA)
        }
    }

    private func matchCell(match: TournamentMatch, isRowTeam: Bool) -> some View {
        Button {
            onMatchTapped?(match)
        } label: {
            if match.status == "completed" {
                let rowTeamIsA = match.teamAId == teamIds.first // simplified
                let score = "\(match.scoreA ?? 0)-\(match.scoreB ?? 0)"
                Text(score)
                    .font(.caption.bold())
                    .foregroundStyle(match.winnerId != nil ? .primary : .secondary)
            } else {
                Text("vs")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }
}
