import SwiftUI

struct SubgroupBadge: View {
    let name: String
    let color: String

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color(hex: color))
                .frame(width: 8, height: 8)
            Text(name)
                .font(.caption2)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Color(hex: color).opacity(0.15))
        .clipShape(Capsule())
    }
}
