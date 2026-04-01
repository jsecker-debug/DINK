import SwiftUI
import Supabase

struct EditProfileSheet: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.dismiss) private var dismiss
    @Environment(ToastManager.self) private var toastManager

    @State private var phone = ""
    @State private var bio = ""
    @State private var emergencyContactName = ""
    @State private var emergencyContactPhone = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Contact") {
                    TextField("Phone number", text: $phone)
                        .keyboardType(.phonePad)
                }

                Section("About") {
                    TextField("Tell us about yourself", text: $bio, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Emergency Contact") {
                    TextField("Contact name", text: $emergencyContactName)
                    TextField("Contact phone", text: $emergencyContactPhone)
                        .keyboardType(.phonePad)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(isSaving)
                }
            }
            .onAppear {
                phone = authService.userProfile?.phone ?? ""
            }
        }
    }

    private func save() {
        isSaving = true
        errorMessage = nil

        Task {
            defer { isSaving = false }

            guard let userId = authService.user?.id else {
                errorMessage = "Not signed in"
                return
            }

            let update = ProfileUpdate(
                phone: phone.isEmpty ? nil : phone,
                bio: bio.isEmpty ? nil : bio,
                emergencyContactName: emergencyContactName.isEmpty ? nil : emergencyContactName,
                emergencyContactPhone: emergencyContactPhone.isEmpty ? nil : emergencyContactPhone,
                updatedAt: ISO8601DateFormatter().string(from: Date())
            )

            do {
                try await supabase
                    .from("user_profiles")
                    .update(update)
                    .eq("id", value: userId.uuidString)
                    .execute()

                await authService.refreshUserProfile()
                toastManager.show("Profile updated", type: .success)
                dismiss()
            } catch {
                errorMessage = "Failed to update profile: \(error.localizedDescription)"
                toastManager.show("Failed to update profile", type: .error)
            }
        }
    }
}

// MARK: - Update Payload

private struct ProfileUpdate: Codable {
    let phone: String?
    let bio: String?
    let emergencyContactName: String?
    let emergencyContactPhone: String?
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case phone
        case bio
        case emergencyContactName = "emergency_contact_name"
        case emergencyContactPhone = "emergency_contact_phone"
        case updatedAt = "updated_at"
    }
}
