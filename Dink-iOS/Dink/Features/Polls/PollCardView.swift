import SwiftUI

struct PollCardView: View {
    let poll: Poll
    let options: [PollOption]
    let votes: [PollVote]
    let currentUserId: UUID

    var onVote: (UUID) async -> Void
    var onRemoveVote: (UUID) async -> Void

    private var totalVotes: Int { votes.count }

    private var isExpired: Bool {
        if let expiresAt = poll.expiresAt {
            return expiresAt < Date()
        }
        return false
    }

    private var isClosed: Bool {
        poll.status == "closed" || isExpired
    }

    private func votesForOption(_ optionId: UUID) -> Int {
        votes.filter { $0.optionId == optionId }.count
    }

    private func currentUserVotedFor(_ optionId: UUID) -> Bool {
        votes.contains { $0.optionId == optionId && $0.userId == currentUserId }
    }

    private func percentage(for optionId: UUID) -> Double {
        guard totalVotes > 0 else { return 0 }
        return Double(votesForOption(optionId)) / Double(totalVotes) * 100
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.body)
                    .foregroundStyle(.purple)
                    .frame(width: 32, height: 32)
                    .background(Color.purple.opacity(0.12))
                    .clipShape(Circle())

                Text(poll.question)
                    .font(.subheadline.bold())

                Spacer()

                Text(statusLabel)
                    .font(.caption2.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.12))
                    .foregroundStyle(statusColor)
                    .clipShape(Capsule())
            }

            // Options
            VStack(spacing: 8) {
                ForEach(options) { option in
                    optionRow(option)
                }
            }

            // Footer
            HStack {
                Text("\(totalVotes) vote\(totalVotes == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                if let expiresAt = poll.expiresAt {
                    if isExpired {
                        Text("Expired")
                            .font(.caption)
                            .foregroundStyle(.red)
                    } else {
                        Text("Expires \(expiresAt, style: .relative)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if poll.allowMultiple {
                    Text("Multiple choice")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(.rect(cornerRadius: 10))
        .liquidGlassStatic(cornerRadius: 10)
    }

    @ViewBuilder
    private func optionRow(_ option: PollOption) -> some View {
        let voted = currentUserVotedFor(option.id)
        let pct = percentage(for: option.id)

        Button {
            Task {
                if voted {
                    await onRemoveVote(option.id)
                } else {
                    await onVote(option.id)
                }
            }
        } label: {
            ZStack(alignment: .leading) {
                // Background bar
                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: 6)
                        .fill(voted ? Color.purple.opacity(0.2) : Color(.tertiarySystemBackground))
                        .frame(width: geo.size.width * (pct / 100))
                        .animation(.easeInOut(duration: 0.3), value: pct)
                }

                HStack {
                    if voted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.purple)
                            .font(.caption)
                    }

                    Text(option.text)
                        .font(.subheadline)
                        .foregroundStyle(.primary)

                    Spacer()

                    Text("\(Int(pct))%")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
            }
            .frame(minHeight: 36)
            .background(Color(.tertiarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .disabled(isClosed)
    }

    private var statusLabel: String {
        if isClosed { return "Closed" }
        return "Active"
    }

    private var statusColor: Color {
        if isClosed { return .secondary }
        return .purple
    }
}
