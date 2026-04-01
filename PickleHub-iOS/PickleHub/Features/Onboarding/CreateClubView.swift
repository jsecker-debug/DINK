import SwiftUI

struct CreateClubView: View {
    @Environment(AuthService.self) private var authService
    @Environment(ClubService.self) private var clubService
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var description = ""
    @State private var location = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.green)
                        .accessibilityHidden(true)

                    Text("Create Your Club")
                        .font(.title2.bold())

                    Text("Set up your pickleball club and start inviting players.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 16)

                // Form
                VStack(spacing: 16) {
                    if let errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundStyle(.red)
                            Spacer()
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.red.opacity(0.1))
                        )
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Club Name")
                            .font(.subheadline.weight(.medium))
                        TextField("e.g. Downtown Dinkers", text: $name)
                            .textContentType(.organizationName)
                            .padding()
                            .background(.fill.tertiary)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Description")
                            .font(.subheadline.weight(.medium))
                        TextField("What's your club about?", text: $description, axis: .vertical)
                            .lineLimit(3...6)
                            .padding()
                            .background(.fill.tertiary)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Location")
                            .font(.subheadline.weight(.medium))
                        TextField("e.g. Central Park Courts", text: $location)
                            .padding()
                            .background(.fill.tertiary)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                .padding(20)
                .background {
                    if #available(iOS 26, *) {
                        Color.clear
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.secondarySystemBackground))
                    }
                }
                .liquidGlassStatic(cornerRadius: 12)

                // Create button
                Button {
                    Task { await createClub() }
                } label: {
                    Group {
                        if isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Create Club")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                .controlSize(.large)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
                .modifier(PrimaryButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Create Club")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func createClub() async {
        guard let userId = authService.user?.id else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await clubService.createClub(
                name: name.trimmingCharacters(in: .whitespaces),
                description: description.isEmpty ? nil : description,
                location: location.isEmpty ? nil : location,
                userId: userId.uuidString
            )
        } catch {
            errorMessage = "Failed to create club: \(error.localizedDescription)"
        }
    }
}

// MARK: - Reusable Primary Button Style

private struct PrimaryButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content.buttonStyle(.glassProminent)
        } else {
            content.buttonStyle(.borderedProminent)
        }
    }
}
