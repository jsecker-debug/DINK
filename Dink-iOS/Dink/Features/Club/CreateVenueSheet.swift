import SwiftUI

struct CreateVenueSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ClubService.self) private var clubService
    @Environment(ToastManager.self) private var toastManager

    @State private var name = ""
    @State private var address = ""
    @State private var numberOfCourts = 4
    @State private var isSaving = false

    var venue: Venue?
    var onSaved: () async -> Void

    init(venue: Venue? = nil, onSaved: @escaping () async -> Void) {
        self.venue = venue
        self.onSaved = onSaved
    }

    private var isEditMode: Bool { venue != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Venue Details") {
                    TextField("Name", text: $name)
                    TextField("Address (optional)", text: $address)
                    Stepper("Courts: \(numberOfCourts)", value: $numberOfCourts, in: 1...20)
                }
            }
            .navigationTitle(isEditMode ? "Edit Venue" : "New Venue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditMode ? "Save" : "Create") {
                        Task { await saveVenue() }
                    }
                    .disabled(name.isEmpty || isSaving)
                }
            }
            .onAppear {
                if let venue {
                    name = venue.name
                    address = venue.address ?? ""
                    numberOfCourts = venue.numberOfCourts
                }
            }
        }
    }

    private func saveVenue() async {
        isSaving = true
        defer { isSaving = false }

        let trimmedAddress = address.isEmpty ? nil : address

        do {
            if let venue {
                _ = try await VenueRepository().updateVenue(
                    id: venue.id,
                    name: name,
                    address: trimmedAddress,
                    numberOfCourts: numberOfCourts
                )
                toastManager.show("Venue updated", type: .success)
            } else {
                guard let clubId = clubService.selectedClubId else { return }
                _ = try await VenueRepository().createVenue(
                    clubId: clubId,
                    name: name,
                    address: trimmedAddress,
                    numberOfCourts: numberOfCourts
                )
                toastManager.show("Venue created", type: .success)
            }
            await onSaved()
            dismiss()
        } catch {
            toastManager.show("Failed to save venue: \(error.localizedDescription)", type: .error)
        }
    }
}
