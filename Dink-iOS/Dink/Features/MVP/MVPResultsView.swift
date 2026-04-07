import SwiftUI

struct MVPResultsView: View {
    let results: [MVPResult]
    let participants: [SessionRegistrationWithUser]

    private var totalVotes: Int {
        results.reduce(0) { $0 + $1.voteCount }
    }

    private var sortedResults: [MVPResult] {
        results.sorted { $0.voteCount > $1.voteCount }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Voting Results")
                    .font(.headline)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                if sortedResults.isEmpty {
                    Text("No votes cast yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(sortedResults.enumerated()), id: \.element.nomineeId) { index, result in
                            resultRow(result: result, rank: index + 1)

                            if index < sortedResults.count - 1 {
                                Divider().padding(.leading, 68)
                            }
                        }
                    }
                    .background(Color(.secondarySystemBackground))
                    .clipShape(.rect(cornerRadius: 10))
                    .padding(.horizontal, 20)
                }
            }
            .padding(.vertical, 16)
        }
    }

    // MARK: - Result Row

    private func resultRow(result: MVPResult, rank: Int) -> some View {
        let participant = participants.first { $0.userId == result.nomineeId }
        let percentage = totalVotes > 0 ? Double(result.voteCount) / Double(totalVotes) : 0

        return HStack(spacing: 12) {
            ZStack {
                if rank <= 3 {
                    Image(systemName: rank == 1 ? "trophy.fill" : "medal.fill")
                        .font(.title3)
                        .foregroundStyle(medalColor(for: rank))
                } else {
                    Text("#\(rank)")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 28)

            AvatarView(
                firstName: participant?.userProfiles?.firstName,
                lastName: participant?.userProfiles?.lastName,
                avatarUrl: participant?.userProfiles?.avatarUrl,
                size: 40
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(participant?.userProfiles?.fullName ?? "Unknown")
                    .font(.body)
                    .fontWeight(rank == 1 ? .semibold : .regular)

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(.tertiarySystemBackground))
                            .frame(height: 6)

                        Capsule()
                            .fill(medalColor(for: rank))
                            .frame(width: geometry.size.width * percentage, height: 6)
                    }
                }
                .frame(height: 6)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(result.voteCount)")
                    .font(.headline)
                    .foregroundStyle(medalColor(for: rank))
                Text(result.voteCount == 1 ? "vote" : "votes")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Helpers

    private func medalColor(for rank: Int) -> Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .secondary
        }
    }
}
