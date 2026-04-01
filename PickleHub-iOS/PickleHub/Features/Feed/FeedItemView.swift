import SwiftUI

struct FeedItemView: View {
    let item: ActivityWithRelatedData

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: icon + author + time
            HStack(spacing: 8) {
                Image(systemName: iconName)
                    .font(.body)
                    .foregroundStyle(iconColor)
                    .frame(width: 32, height: 32)
                    .background(iconColor.opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(authorName)
                        .font(.subheadline.bold())
                    Text(relativeTime)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(typeBadge)
                    .font(.caption2.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(iconColor.opacity(0.12))
                    .foregroundStyle(iconColor)
                    .clipShape(Capsule())
            }

            // Content
            if let title = item.activity.data?.title {
                Text(title)
                    .font(.subheadline.bold())
            }

            if let message = item.activity.data?.message {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Metadata
            if let session = item.targetSession {
                HStack(spacing: 12) {
                    if let date = session.date {
                        Label(date, systemImage: "calendar")
                    }
                    if let venue = session.venue {
                        Label(venue, systemImage: "mappin")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            // Actions
            HStack(spacing: 24) {
                Button { } label: {
                    Label("Like", systemImage: "heart")
                        .font(.caption)
                }
                Button { } label: {
                    Label("Comment", systemImage: "bubble.right")
                        .font(.caption)
                }
                Button { } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(.caption)
                }
            }
            .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(.rect(cornerRadius: 10))
        .liquidGlassStatic(cornerRadius: 10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(typeBadge) by \(authorName), \(relativeTime). \(item.activity.data?.title ?? "")")
    }

    // MARK: - Helpers

    private var iconName: String {
        switch item.activity.type {
        case "session_created": return "calendar.badge.plus"
        case "session_completed": return "checkmark.circle"
        case "member_joined": return "person.badge.plus"
        case "announcement": return "megaphone"
        case let t where t.contains("tournament"): return "trophy"
        default: return "bell"
        }
    }

    private var iconColor: Color {
        switch item.activity.type {
        case "session_created": return .blue
        case "session_completed": return .green
        case "member_joined": return .purple
        case "announcement": return .orange
        case let t where t.contains("tournament"): return .yellow
        default: return .secondary
        }
    }

    private var typeBadge: String {
        switch item.activity.type {
        case "session_created": return "New Session"
        case "session_completed": return "Complete"
        case "member_joined": return "New Member"
        case "announcement": return "Announcement"
        case let t where t.contains("tournament"): return "Tournament"
        default: return item.activity.type.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    private var authorName: String {
        if let actor = item.actorProfile {
            return [actor.firstName, actor.lastName].compactMap { $0 }.joined(separator: " ")
        }
        return "System"
    }

    private var relativeTime: String {
        guard let date = item.activity.createdAt else { return "" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
