import SwiftUI

struct SignUpView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.dismiss) private var dismiss

    var inviteToken: String?

    // MARK: - Form State

    @State private var currentStep = 1

    // Step 1
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    // Step 2
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var phone = ""
    @State private var skillLevel: Double = 3.0
    @State private var gender = "M"

    // UI State
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSuccess = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Invite banner
                if let invite = authService.pendingInvite {
                    inviteBanner(invite)
                }

                // Step progress indicator
                stepIndicator

                // Step content
                if currentStep == 1 {
                    SignUpStep1View(
                        email: $email,
                        password: $password,
                        confirmPassword: $confirmPassword,
                        onNext: { currentStep = 2 }
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading),
                        removal: .move(edge: .leading)
                    ))
                } else {
                    SignUpStep2View(
                        firstName: $firstName,
                        lastName: $lastName,
                        phone: $phone,
                        skillLevel: $skillLevel,
                        gender: $gender,
                        isLoading: isLoading,
                        onSubmit: { Task { await submitSignUp() } },
                        onBack: { currentStep = 1 }
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .trailing)
                    ))
                }

                // Error message
                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }

                // Info card
                infoCard
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .scrollDismissesKeyboard(.interactively)
        .animation(.easeInOut(duration: 0.3), value: currentStep)
        .navigationTitle("Sign Up")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if let inviteToken {
                do {
                    try await authService.processInviteToken(inviteToken)
                    if let invite = authService.pendingInvite {
                        email = invite.email
                    }
                } catch {
                    errorMessage = "Could not load invitation: \(error.localizedDescription)"
                }
            }
        }
        .alert("Account Created", isPresented: $showSuccess) {
            Button("OK") { dismiss() }
        } message: {
            if authService.pendingInvite != nil {
                Text("Your account has been created and you have joined the club. Please sign in to continue.")
            } else {
                Text("Your account has been created. Please sign in to continue.")
            }
        }
    }

    // MARK: - Invite Banner

    private func inviteBanner(_ invite: InviteData) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "envelope.open.fill")
                .font(.title3)
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 4) {
                Text("\(invite.inviterName) invited you to join")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(invite.clubName)
                    .font(.headline)
            }

            Spacer()
        }
        .padding(16)
        .background {
            if #available(iOS 26, *) {
                Color.clear
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.blue.opacity(0.1))
            }
        }
        .liquidGlassStatic(cornerRadius: 10, tint: .blue)
    }

    // MARK: - Step Indicator

    private var stepIndicator: some View {
        HStack(spacing: 0) {
            stepCircle(step: 1)

            Rectangle()
                .fill(currentStep >= 2 ? Color.accentColor : Color(.tertiaryLabel))
                .frame(height: 2)
                .frame(maxWidth: 48)

            stepCircle(step: 2)
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Step \(currentStep) of 2")
    }

    private func stepCircle(step: Int) -> some View {
        let isActive = currentStep == step
        let isComplete = currentStep > step

        return ZStack {
            if isComplete {
                Image(systemName: "checkmark")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
            } else {
                Text("\(step)")
                    .font(.caption.bold())
                    .foregroundStyle(isActive ? .white : .secondary)
            }
        }
        .frame(width: 32, height: 32)
        .background(
            Circle()
                .fill(isActive || isComplete ? Color.accentColor : Color(.tertiarySystemFill))
        )
    }

    // MARK: - Info Card

    private var infoCard: some View {
        let text: String = if authService.pendingInvite != nil {
            "After signing up, you'll automatically join the club you were invited to. You can start playing right away!"
        } else {
            "After signing up, you can join a club by requesting an invitation from a club administrator, or create your own club."
        }

        return HStack(alignment: .top, spacing: 12) {
            Image(systemName: "info.circle")
                .font(.title3)
                .foregroundStyle(.secondary)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background {
            if #available(iOS 26, *) {
                Color.clear
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.secondarySystemBackground))
            }
        }
        .liquidGlassStatic(cornerRadius: 10)
    }

    // MARK: - Submit

    private func submitSignUp() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await authService.signUp(
                email: email,
                password: password,
                firstName: firstName,
                lastName: lastName,
                phone: phone,
                skillLevel: skillLevel,
                gender: gender
            )

            // Handle pending invite
            if let invite = authService.pendingInvite,
               let user = authService.user {
                try await authService.acceptInvitation(
                    token: invite.token,
                    userId: user.id
                )
            }

            showSuccess = true
        } catch {
            let message = error.localizedDescription
            if message.lowercased().contains("already registered")
                || message.lowercased().contains("already been registered") {
                errorMessage = "This email is already registered. Please go back and sign in instead."
            } else {
                errorMessage = message
            }
        }
    }
}
