import SwiftUI

struct ClubSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ClubService.self) private var clubService
    @Environment(AuthService.self) private var authService
    @Environment(ToastManager.self) private var toastManager

    @State private var clubName = ""
    @State private var clubDescription = ""
    @State private var clubLocation = ""
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Club Details") {
                    TextField("Club Name", text: $clubName)

                    TextField("Description", text: $clubDescription, axis: .vertical)
                        .lineLimit(3...6)

                    TextField("Location", text: $clubLocation)
                }
            }
            .navigationTitle("Club Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await saveChanges() }
                    }
                    .disabled(clubName.isEmpty || isSaving)
                }
            }
            .onAppear {
                if let club = clubService.selectedClub {
                    clubName = club.name
                    clubDescription = club.description ?? ""
                    clubLocation = club.location ?? ""
                }
            }
        }
    }

    // MARK: - Save

    private func saveChanges() async {
        guard let clubId = clubService.selectedClubId else { return }
        isSaving = true
        defer { isSaving = false }

        do {
            try await supabase
                .from("clubs")
                .update([
                    "name": clubName,
                    "description": clubDescription,
                    "location": clubLocation
                ])
                .eq("id", value: clubId.uuidString)
                .execute()

            // Refresh the club list so the selected club reflects changes
            if let userId = authService.userProfile?.id.uuidString {
                await clubService.refreshClubs(userId: userId)
            }

            toastManager.show("Club settings updated", type: .success)
            dismiss()
        } catch {
            toastManager.show("Failed to update: \(error.localizedDescription)", type: .error)
        }
    }
}
