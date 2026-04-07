import SwiftUI

struct MatchCardView: View {
    let match: TournamentMatch
    let teamAName: String
    let teamBName: String
    var isCompact: Bool = false
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button {
            onTap?()
        } label: {
            VStack(spacing: 0) {
                teamRow(name: teamAName, score: match.scoreA, isWinner: match.winnerId == match.teamAId)
                Divider()
                teamRow(name: teamBName, score: match.scoreB, isWinner: match.winnerId == match.teamBId)
            }
            .frame(width: isCompact ? 140 : 180)
            .background(Color(.secondarySystemBackground))
            .clipShape(.rect(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(statusColor.opacity(0.5), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(onTap == nil)
    }

    private func teamRow(name: String, score: Int?, isWinner: Bool) -> some View {
        HStack(spacing: 8) {
            Text(name.isEmpty ? "TBD" : name)
                .font(isCompact ? .caption : .subheadline)
                .fontWeight(isWinner ? .bold : .regular)
                .foregroundStyle(name.isEmpty ? .tertiary : .primary)
                .lineLimit(1)
            Spacer()
            if let score {
                Text("\(score)")
                    .font(isCompact ? .caption.bold() : .subheadline.bold())
                    .foregroundStyle(isWinner ? .primary : .secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, isCompact ? 6 : 8)
        .background(isWinner ? statusColor.opacity(0.08) : .clear)
    }

    private var statusColor: Color {
        switch match.status {
        case "completed": return .dinkGreen
        case "scheduled": return .dinkTeal
        default: return .secondary
        }
    }
}
