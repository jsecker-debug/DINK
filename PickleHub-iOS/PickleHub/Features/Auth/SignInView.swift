import SwiftUI

struct SignInView: View {
    @Environment(AuthService.self) private var authService
    @Environment(ClubService.self) private var clubService

    var inviteToken: String? = nil
    var showAccountCreatedBanner: Bool = false
    var showEmailConfirmedBanner: Bool = false

    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var showSignUp = false

    // Forgot password state
    @State private var showForgotPasswordAlert = false
    @State private var forgotPasswordEmail = ""
    @State private var forgotPasswordMessage: String?
    @State private var forgotPasswordIsError = false
    @State private var isSendingReset = false

    // Invite state
    @State private var isProcessingInvite = false

    private var effectiveInvite: InviteData? {
        authService.pendingInvite
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Spacer(minLength: 32)

                    // Logo area
                    VStack(spacing: 8) {
                        Image(systemName: "figure.pickleball")
                            .font(.largeTitle)
                            .imageScale(.large)
                            .foregroundStyle(.tint)
                            .accessibilityHidden(true)
                        Text("PickleHub")
                            .font(.largeTitle.bold())
                        Text("Manage your pickleball club")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    // Status banners
                    if showAccountCreatedBanner {
                        statusBanner(
                            icon: "checkmark.circle.fill",
                            title: "Account Created!",
                            message: "Please check your email to confirm your account, then sign in.",
                            tint: .green
                        )
                    }

                    if showEmailConfirmedBanner {
                        statusBanner(
                            icon: "checkmark.seal.fill",
                            title: "Email Confirmed!",
                            message: "Your email has been confirmed. You can now sign in.",
                            tint: .green
                        )
                    }

                    // Invite banner
                    if let invite = effectiveInvite {
                        inviteBanner(invite: invite)
                    }

                    // Form card
                    formCard

                    // Forgot password
                    Button("Forgot password?") {
                        forgotPasswordEmail = email
                        showForgotPasswordAlert = true
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                    // Help section
                    helpSection

                    Spacer(minLength: 16)

                    // Sign up link
                    Button {
                        showSignUp = true
                    } label: {
                        Text("Don't have an account? ")
                            .foregroundStyle(.secondary)
                        + Text("Sign Up")
                            .foregroundStyle(.tint)
                            .bold()
                    }
                    .font(.subheadline)
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 20)
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationDestination(isPresented: $showSignUp) {
                SignUpView(inviteToken: inviteToken)
            }
            .alert("Reset Password", isPresented: $showForgotPasswordAlert) {
                TextField("Email address", text: $forgotPasswordEmail)
                Button("Cancel", role: .cancel) {}
                Button("Send Reset Link") {
                    Task { await sendPasswordReset() }
                }
            } message: {
                Text("Enter your email address and we'll send you a link to reset your password.")
            }
            .task {
                await processInviteTokenIfNeeded()
            }
        }
    }

    // MARK: - Invite Banner

    private func inviteBanner(invite: InviteData) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "gift.fill")
                .font(.title2)
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 4) {
                Text("\(invite.inviterName) invited you to join \(invite.clubName)")
                    .font(.subheadline.bold())
                Text("Sign in or create an account to accept the invitation.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .liquidGlassStatic(cornerRadius: 10, tint: .blue)
        .background {
            if !isLiquidGlassAvailable {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.blue.opacity(0.1))
            }
        }
    }

    // MARK: - Status Banner

    private func statusBanner(
        icon: String,
        title: String,
        message: String,
        tint: Color
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(tint)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(tint.opacity(0.1))
        )
    }

    // MARK: - Form Card

    @ViewBuilder
    private var formCard: some View {
        VStack(spacing: 16) {
            // Error message
            if let errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                    Spacer(minLength: 0)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.red.opacity(0.1))
                )
            }

            // Forgot password success/error message
            if let forgotPasswordMessage {
                HStack(spacing: 8) {
                    Image(systemName: forgotPasswordIsError
                          ? "exclamationmark.triangle.fill"
                          : "checkmark.circle.fill")
                        .foregroundStyle(forgotPasswordIsError ? .red : .green)
                    Text(forgotPasswordMessage)
                        .font(.caption)
                        .foregroundStyle(forgotPasswordIsError ? .red : .primary)
                    Spacer(minLength: 0)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill((forgotPasswordIsError ? Color.red : Color.green).opacity(0.1))
                )
            }

            // Pre-fill email from invite
            TextField("Email", text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .padding()
                .background(.fill.tertiary)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            SecureField("Password", text: $password)
                .textContentType(.password)
                .padding()
                .background(.fill.tertiary)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            // Sign in button
            signInButton
        }
        .padding(20)
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

    // MARK: - Sign In Button

    @ViewBuilder
    private var signInButton: some View {
        Button {
            Task { await signIn() }
        } label: {
            Group {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Sign In")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .controlSize(.large)
        .disabled(email.isEmpty || password.isEmpty || isLoading)
        .modifier(SignInButtonStyle())
    }

    // MARK: - Help Section

    private var helpSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Help", systemImage: "questionmark.circle")
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 4) {
                helpItem("Check your spam folder for the confirmation email.")
                helpItem("Confirmation links expire after 24 hours.")
                helpItem("Contact your club admin if you need assistance.")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.tertiarySystemBackground))
        )
    }

    private func helpItem(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "circle.fill")
                .font(.system(size: 4))
                .foregroundStyle(.tertiary)
                .padding(.top, 6)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Liquid Glass Availability

    private var isLiquidGlassAvailable: Bool {
        if #available(iOS 26, *) {
            return true
        }
        return false
    }

    // MARK: - Actions

    private func signIn() async {
        isLoading = true
        errorMessage = nil
        forgotPasswordMessage = nil
        defer { isLoading = false }

        do {
            try await authService.signIn(email: email, password: password)

            // Process pending invite after successful sign in
            if let invite = authService.pendingInvite,
               let userId = authService.user?.id {
                do {
                    try await authService.acceptInvitation(
                        token: invite.token,
                        userId: userId
                    )
                    // Refresh clubs and select the newly joined club
                    await clubService.refreshClubs(userId: userId.uuidString)
                    if let clubId = UUID(uuidString: invite.clubId) {
                        clubService.setSelectedClubById(clubId)
                    }
                } catch {
                    // Sign-in succeeded but invite acceptance failed.
                    // User is signed in; they can accept later.
                    print("Failed to accept invitation: \(error)")
                }
            }
        } catch let error as AuthError {
            switch error {
            case .emailNotConfirmed:
                errorMessage = "Please check your email and click the confirmation link before signing in."
            case .invalidCredentials:
                errorMessage = "Invalid email or password. Please check your credentials."
            default:
                errorMessage = error.localizedDescription
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func sendPasswordReset() async {
        guard !forgotPasswordEmail.isEmpty else { return }
        isSendingReset = true
        defer { isSendingReset = false }

        do {
            try await authService.resetPassword(email: forgotPasswordEmail)
            forgotPasswordIsError = false
            forgotPasswordMessage = "Password reset link sent! Check your email."
        } catch {
            forgotPasswordIsError = true
            forgotPasswordMessage = "Failed to send reset email. Please try again."
        }
    }

    private func processInviteTokenIfNeeded() async {
        // If an explicit invite token was passed in and we don't already have invite data
        guard let token = inviteToken, authService.pendingInvite == nil else { return }
        isProcessingInvite = true
        defer { isProcessingInvite = false }

        do {
            let inviteData = try await authService.processInviteToken(token)
            // Pre-fill email from invitation
            if email.isEmpty {
                email = inviteData.email
            }
        } catch {
            // Token was invalid/expired -- just continue without invite banner
            print("Failed to process invite token: \(error)")
        }
    }
}

// MARK: - Sign In Button Style Modifier

/// Applies `.glassProminent` on iOS 26+, `.borderedProminent` on earlier versions.
private struct SignInButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content.buttonStyle(.glassProminent)
        } else {
            content.buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    SignInView()
        .environment(AuthService())
        .environment(ClubService())
}

#Preview("With Invite Banner") {
    SignInView(showAccountCreatedBanner: true)
        .environment(AuthService())
        .environment(ClubService())
}
