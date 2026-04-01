import SwiftUI

struct InviteMemberSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ClubService.self) private var clubService
    @Environment(AuthService.self) private var authService
    @Environment(ToastManager.self) private var toastManager

    @State private var email = ""
    @State private var personalMessage = ""
    @State private var isSending = false
    @State private var didSend = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Invite Details") {
                    TextField("Email address", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)

                    TextField("Personal message (optional)", text: $personalMessage, axis: .vertical)
                        .lineLimit(3...6)
                }

                if let error {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.subheadline)
                    }
                }

                if didSend {
                    Section {
                        Label("Invitation sent!", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }
            }
            .navigationTitle("Invite Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Send") {
                        Task { await sendInvite() }
                    }
                    .disabled(email.isEmpty || isSending)
                }
            }
        }
    }

    private func sendInvite() async {
        guard let clubId = clubService.selectedClubId,
              let userId = authService.user?.id else { return }
        isSending = true
        error = nil
        defer { isSending = false }

        do {
            _ = try await InvitationRepository().createInvitation(
                clubId: clubId,
                email: email,
                invitedBy: userId,
                personalMessage: personalMessage.isEmpty ? nil : personalMessage
            )
            didSend = true
            toastManager.show("Invitation sent", type: .success)
            email = ""
            personalMessage = ""
        } catch {
            self.error = error.localizedDescription
            toastManager.show("Failed to send invitation: \(error.localizedDescription)", type: .error)
        }
    }
}
