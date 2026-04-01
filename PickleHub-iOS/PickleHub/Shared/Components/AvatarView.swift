import SwiftUI

struct AvatarView: View {
    let firstName: String?
    let lastName: String?
    let avatarUrl: String?
    let size: CGFloat

    init(firstName: String? = nil, lastName: String? = nil, avatarUrl: String? = nil, size: CGFloat = 40) {
        self.firstName = firstName
        self.lastName = lastName
        self.avatarUrl = avatarUrl
        self.size = size
    }

    var body: some View {
        if let urlString = avatarUrl, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    initialsView
                case .empty:
                    ProgressView()
                        .frame(width: size, height: size)
                @unknown default:
                    initialsView
                }
            }
            .frame(width: size, height: size)
            .clipShape(.circle)
        } else {
            initialsView
        }
    }

    private var initialsView: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Text(initials)
                .font(.system(size: size * 0.36, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
        .accessibilityLabel("Avatar for \(firstName ?? "") \(lastName ?? "")")
    }

    private var initials: String {
        let first = firstName?.first.map(String.init) ?? ""
        let last = lastName?.first.map(String.init) ?? ""
        let result = (first + last).uppercased()
        return result.isEmpty ? "?" : result
    }
}
