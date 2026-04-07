import SwiftUI

struct VenueManagementView: View {
    @Environment(ClubService.self) private var clubService
    @Environment(ToastManager.self) private var toastManager

    @State private var venues: [Venue] = []
    @State private var isLoading = false
    @State private var showCreateSheet = false
    @State private var venueToEdit: Venue?

    var body: some View {
        Group {
            if isLoading && venues.isEmpty {
                LoadingView(message: "Loading venues...")
            } else if venues.isEmpty {
                EmptyStateView(
                    icon: "mappin.slash",
                    title: "No Venues",
                    message: "Add a venue to get started."
                )
            } else {
                List {
                    ForEach(venues) { venue in
                        Button {
                            venueToEdit = venue
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(venue.name)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                HStack(spacing: 12) {
                                    if let address = venue.address, !address.isEmpty {
                                        Label(address, systemImage: "mappin")
                                    }
                                    Label("\(venue.numberOfCourts) court\(venue.numberOfCourts == 1 ? "" : "s")", systemImage: "sportscourt")
                                }
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(
                            Color.clear
                                .liquidGlassStatic(cornerRadius: 10)
                        )
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                Task { await deleteVenue(venue) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Venues")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showCreateSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            CreateVenueSheet { await loadVenues() }
        }
        .sheet(item: $venueToEdit) { venue in
            CreateVenueSheet(venue: venue) { await loadVenues() }
        }
        .refreshable { await loadVenues() }
        .task(id: clubService.selectedClubId) { await loadVenues() }
    }

    // MARK: - Actions

    private func loadVenues() async {
        guard let clubId = clubService.selectedClubId else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            venues = try await VenueRepository().fetchVenues(clubId: clubId)
        } catch {
            toastManager.show("Failed to load venues: \(error.localizedDescription)", type: .error)
        }
    }

    private func deleteVenue(_ venue: Venue) async {
        do {
            try await VenueRepository().deleteVenue(id: venue.id)
            venues.removeAll { $0.id == venue.id }
            toastManager.show("Venue deleted", type: .success)
        } catch {
            toastManager.show("Failed to delete venue: \(error.localizedDescription)", type: .error)
        }
    }
}
