import SwiftUI

struct MemberCardView: View {
    let member: ClubMemberWithProfile

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(.tertiarySystemBackground))
                .frame(width: 44, height: 44)
                .overlay {
                    Text(initials)
                        .font(.subheadline.bold())
                        .foregroundStyle(.secondary)
                }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(member.fullName)
                        .font(.subheadline.bold())

                    if member.role.lowercased() == "admin" || member.role.lowercased() == "owner" {
                        Text(member.role.capitalized)
                            .font(.caption2.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.15))
                            .foregroundStyle(Color.accentColor)
                            .clipShape(Capsule())
                    }
                }

                HStack(spacing: 12) {
                    if let level = member.skillLevel {
                        Label(String(format: "%.1f", level), systemImage: "chart.bar.fill")
                    }
                    Label("\(member.totalGamesPlayed)", systemImage: "sportscourt.fill")
                    if member.totalGamesPlayed > 0 {
                        let rate = Double(member.wins) / Double(member.totalGamesPlayed) * 100
                        Label("\(Int(rate))%", systemImage: "percent")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(.rect(cornerRadius: 10))
        .liquidGlassStatic(cornerRadius: 10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(member.fullName), \(member.role.capitalized), \(member.totalGamesPlayed) games played")
    }

    private var initials: String {
        let parts = member.fullName.split(separator: " ")
        let first = parts.first?.prefix(1) ?? ""
        let last = parts.count > 1 ? parts.last!.prefix(1) : ""
        return "\(first)\(last)".uppercased()
    }
}
