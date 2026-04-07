import SwiftUI

struct RankingRowView: View {
    let rank: Int
    let participant: ParticipantWithProfile
    let sortBy: RankingsView.SortOption

    /// Converts the participant data into a `ClubMemberWithProfile` for navigation.
    private var memberValue: ClubMemberWithProfile {
        ClubMemberWithProfile(
            id: participant.id,
            userId: participant.id,
            role: "member",
            status: "active",
            joinedAt: nil,
            fullName: participant.name,
            phone: participant.phone,
            skillLevel: participant.skillLevel,
            gender: participant.gender,
            totalGamesPlayed: participant.totalGamesPlayed,
            wins: participant.wins,
            losses: participant.losses,
            avatarUrl: participant.avatarUrl
        )
    }

    var body: some View {
        NavigationLink(value: memberValue) {
            HStack(spacing: 12) {
                rankBadge
                    .frame(width: 32)

                // Avatar
                Circle()
                    .fill(LinearGradient.dinkAccent)
                    .frame(width: 40, height: 40)
                    .overlay {
                        Text(initials)
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text(participant.name)
                        .font(.subheadline.bold())
                    Text("\(participant.totalGamesPlayed) games")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(primaryStatValue)
                        .font(.subheadline.bold())
                    Text(primaryStatLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Rank \(rank), \(participant.name), \(primaryStatLabel): \(primaryStatValue), \(participant.totalGamesPlayed) games")
    }

    @ViewBuilder
    private var rankBadge: some View {
        switch rank {
        case 1:
            Image(systemName: "crown.fill")
                .foregroundStyle(.yellow)
                .font(.body)
                .accessibilityHidden(true)
        case 2:
            Image(systemName: "medal.fill")
                .foregroundStyle(.gray)
                .font(.body)
                .accessibilityHidden(true)
        case 3:
            Image(systemName: "medal.fill")
                .foregroundStyle(.dinkOrange)
                .font(.body)
                .accessibilityHidden(true)
        default:
            Text("\(rank)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
        }
    }

    private var initials: String {
        let parts = participant.name.split(separator: " ")
        let first = parts.first?.prefix(1) ?? ""
        let last = parts.count > 1 ? parts.last!.prefix(1) : ""
        return "\(first)\(last)".uppercased()
    }

    private var primaryStatValue: String {
        switch sortBy {
        case .skillLevel: return String(format: "%.1f", participant.skillLevel ?? 0)
        case .winRate:
            let rate = participant.totalGamesPlayed > 0
                ? Double(participant.wins) / Double(participant.totalGamesPlayed) * 100
                : 0
            return "\(Int(rate))%"
        case .gamesPlayed: return "\(participant.totalGamesPlayed)"
        case .totalWins: return "\(participant.wins)"
        case .confidence: return String(format: "%.0f", participant.ratingConfidence * 100)
        }
    }

    private var primaryStatLabel: String {
        switch sortBy {
        case .skillLevel: return "Level"
        case .winRate: return "Win Rate"
        case .gamesPlayed: return "Games"
        case .totalWins: return "Wins"
        case .confidence: return "Confidence"
        }
    }
}
