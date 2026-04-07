import SwiftUI

struct SignUpStep1View: View {
    @Binding var email: String
    @Binding var password: String
    @Binding var confirmPassword: String
    var onNext: () -> Void

    private var isValidEmail: Bool {
        let regex = "[A-Za-z0-9._%+\\-]+@[A-Za-z0-9.\\-]+\\.[A-Za-z]{2,}"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: email)
    }

    private var isValid: Bool {
        isValidEmail && password.count >= 6 && password == confirmPassword
    }

    private var emailError: String? {
        if !email.isEmpty && !isValidEmail {
            return "Please enter a valid email address"
        }
        return nil
    }

    private var passwordError: String? {
        if !password.isEmpty && password.count < 6 {
            return "Password must be at least 6 characters"
        }
        if !confirmPassword.isEmpty && password != confirmPassword {
            return "Passwords do not match"
        }
        return nil
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Account Details")
                .font(.title3.bold())
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 12) {
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                if let emailError {
                    Text(emailError)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                SecureField("Password", text: $password)
                    .textContentType(.newPassword)
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                SecureField("Confirm Password", text: $confirmPassword)
                    .textContentType(.newPassword)
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                if let passwordError {
                    Text(passwordError)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
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

            nextButton
        }
    }

    @ViewBuilder
    private var nextButton: some View {
        Button {
            onNext()
        } label: {
            Text("Next Step")
                .font(.headline)
                .frame(maxWidth: .infinity)
        }
        .controlSize(.large)
        .disabled(!isValid)
        .modifier(AdaptiveButtonStyle())
    }
}

// MARK: - Adaptive Button Style

struct AdaptiveButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content.buttonStyle(.glassProminent)
        } else {
            content.buttonStyle(.borderedProminent)
        }
    }
}
