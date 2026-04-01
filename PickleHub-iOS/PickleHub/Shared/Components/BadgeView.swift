import SwiftUI

struct BadgeView: View {
    let text: String
    let style: BadgeStyle

    enum BadgeStyle {
        case success, warning, destructive, info, secondary

        var foregroundColor: Color {
            switch self {
            case .success: .green
            case .warning: .orange
            case .destructive: .red
            case .info: .blue
            case .secondary: .secondary
            }
        }

        var backgroundColor: Color {
            switch self {
            case .success: .green.opacity(0.15)
            case .warning: .orange.opacity(0.15)
            case .destructive: .red.opacity(0.15)
            case .info: .blue.opacity(0.15)
            case .secondary: Color(.tertiarySystemFill)
            }
        }
    }

    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundStyle(style.foregroundColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(style.backgroundColor)
            .clipShape(.capsule)
            .accessibilityLabel(text)
    }
}
