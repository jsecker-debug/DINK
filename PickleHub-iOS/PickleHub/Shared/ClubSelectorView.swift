import SwiftUI

struct ClubSelectorView: View {
    @Environment(ClubService.self) private var clubService

    var body: some View {
        if clubService.isLoading {
            ProgressView()
                .controlSize(.small)
        } else if clubService.userClubs.isEmpty {
            Label("No Clubs", systemImage: "building.2")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        } else {
            Menu {
                Section("Your Clubs") {
                    ForEach(clubService.userClubs) { club in
                        Button {
                            clubService.setSelectedClub(club)
                        } label: {
                            HStack {
                                Text(club.name)
                                if club.id == clubService.selectedClubId {
                                    Image(systemName: "checkmark")
                                }
                                if club.role?.lowercased() == "admin" || club.role?.lowercased() == "owner" {
                                    Image(systemName: "crown.fill")
                                        .accessibilityLabel("Admin")
                                }
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "building.2")
                        .imageScale(.small)
                    Text(clubService.selectedClub?.name ?? "Select Club")
                        .lineLimit(1)
                    Image(systemName: "chevron.up.chevron.down")
                        .imageScale(.small)
                        .foregroundStyle(.tertiary)
                }
                .font(.subheadline.weight(.medium))
            }
        }
    }
}
