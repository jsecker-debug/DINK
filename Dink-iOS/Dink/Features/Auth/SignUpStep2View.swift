import SwiftUI

struct SignUpStep2View: View {
    @Binding var firstName: String
    @Binding var lastName: String
    @Binding var phone: String
    @Binding var skillLevel: Double
    @Binding var gender: String
    var isLoading: Bool
    var onSubmit: () -> Void
    var onBack: () -> Void

    private var isValidPhone: Bool {
        let digits = phone.filter(\.isNumber)
        let regex = "^[0-9\\s\\-\\(\\)\\+]+$"
        return digits.count >= 7 && digits.count <= 15
            && NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: phone)
    }

    private var phoneError: String? {
        if !phone.isEmpty && !isValidPhone {
            return "Enter a valid phone number (7\u{2013}15 digits)"
        }
        return nil
    }

    private var isValid: Bool {
        !firstName.isEmpty && !lastName.isEmpty && isValidPhone
    }

    // MARK: - Skill Levels

    private static let skillLevels: [(value: Double, label: String)] = [
        (2.0, "2.0 - Beginner"),
        (2.5, "2.5 - Beginner+"),
        (3.0, "3.0 - Intermediate"),
        (3.5, "3.5 - Intermediate+"),
        (4.0, "4.0 - Advanced"),
        (4.5, "4.5 - Advanced+"),
        (5.0, "5.0 - Expert"),
    ]

    // MARK: - Gender Options

    private static let genderOptions: [(value: String, label: String)] = [
        ("M", "Male"),
        ("F", "Female"),
        ("O", "Other"),
    ]

    var body: some View {
        VStack(spacing: 16) {
            Text("Your Profile")
                .font(.title3.bold())
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 12) {
                TextField("First Name", text: $firstName)
                    .textContentType(.givenName)
                    .autocorrectionDisabled()
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                TextField("Last Name", text: $lastName)
                    .textContentType(.familyName)
                    .autocorrectionDisabled()
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                TextField("Phone", text: $phone)
                    .textContentType(.telephoneNumber)
                    .keyboardType(.phonePad)
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                if let phoneError {
                    Text(phoneError)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Skill Level Picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Skill Level")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Picker("Skill Level", selection: $skillLevel) {
                        ForEach(Self.skillLevels, id: \.value) { level in
                            Text(level.label).tag(level.value)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.top, 4)

                // Gender Picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Gender")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Picker("Gender", selection: $gender) {
                        ForEach(Self.genderOptions, id: \.value) { option in
                            Text(option.label).tag(option.value)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.top, 4)
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

            // Buttons
            VStack(spacing: 12) {
                submitButton

                Button {
                    onBack()
                } label: {
                    Text("Back")
                        .font(.subheadline)
                }
                .disabled(isLoading)
            }
        }
    }

    @ViewBuilder
    private var submitButton: some View {
        Button {
            onSubmit()
        } label: {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else {
                Text("Create Account")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
        }
        .controlSize(.large)
        .disabled(!isValid || isLoading)
        .modifier(AdaptiveButtonStyle())
    }
}
