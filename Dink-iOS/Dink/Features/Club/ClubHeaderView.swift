import SwiftUI

struct ClubHeaderView: View {
    @Environment(ClubService.self) private var clubService

    var body: some View {
        if let club = clubService.selectedClub {
            VStack(alignment: .leading, spacing: 8) {
                Text(club.name)
                    .font(.title2.bold())

                if let description = club.description, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 16) {
                    if let location = club.locationDisplay {
                        Label(location, systemImage: "mappin.and.ellipse")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    if let count = club.memberCount {
                        Label("\(count) members", systemImage: "person.2.fill")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemBackground))
            .clipShape(.rect(cornerRadius: 10))
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
    }
}
