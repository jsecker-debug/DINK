import SwiftUI
import PhotosUI

struct ProfileView: View {
    @Environment(AuthService.self) private var authService
    @Environment(ClubService.self) private var clubService

    @State private var showEditSheet = false
    @State private var showSignOutConfirm = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var avatarImage: Image?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                avatarSection
                statsGrid
                personalInfoSection
                accountSettingsSection
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .navigationTitle("Profile")
        .sheet(isPresented: $showEditSheet) {
            EditProfileSheet()
        }
        .confirmationDialog("Sign Out", isPresented: $showSignOutConfirm) {
            Button("Sign Out", role: .destructive) {
                Task { try? await authService.signOut() }
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .onChange(of: selectedPhoto) { _, newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    avatarImage = Image(uiImage: uiImage)
                }
            }
        }
    }

    // MARK: - Avatar Section

    private var avatarSection: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                if let avatarImage {
                    avatarImage
                        .resizable()
                        .scaledToFill()
                        .frame(width: 96, height: 96)
                        .clipShape(.circle)
                } else {
                    AvatarView(
                        firstName: authService.userProfile?.firstName,
                        lastName: authService.userProfile?.lastName,
                        avatarUrl: authService.userProfile?.avatarUrl,
                        size: 96
                    )
                }

                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Image(systemName: "camera.fill")
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(.blue)
                        .clipShape(.circle)
                }
                .accessibilityLabel("Change profile photo")
            }

            Text(authService.userProfile?.fullName ?? "User")
                .font(.title2)
                .fontWeight(.semibold)

            BadgeView(text: "Member", style: .info)

            if let createdAt = authService.userProfile?.createdAt {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                    Text("Member since \(createdAt.monthYear)")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        LiquidGlassContainer(spacing: 12) {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                StatCardView(title: "Games Played", value: "-", subtitle: "Coming soon", icon: "trophy", iconColor: .blue)
                StatCardView(title: "Win Rate", value: "-%", subtitle: "Coming soon", icon: "target", iconColor: .purple)
                StatCardView(title: "Total Wins", value: "-", subtitle: "Coming soon", icon: "arrow.up.right", iconColor: .green)
                StatCardView(title: "Total Losses", value: "-", subtitle: "Coming soon", icon: "arrow.down.right", iconColor: .red)
            }
        }
    }

    // MARK: - Personal Information

    private var personalInfoSection: some View {
        VStack(spacing: 0) {
            HStack {
                Label("Personal Information", systemImage: "person")
                    .font(.headline)
                Spacer()
                Button {
                    showEditSheet = true
                } label: {
                    Label("Edit", systemImage: "pencil")
                        .font(.subheadline)
                }
            }
            .padding(16)

            Divider().padding(.leading, 16)

            infoRow(icon: "person", label: "Name", value: authService.userProfile?.fullName ?? "Not provided")
            Divider().padding(.leading, 16)
            infoRow(icon: "envelope", label: "Email", value: authService.userProfile?.email ?? "Not provided")
            Divider().padding(.leading, 16)
            infoRow(icon: "phone", label: "Phone", value: authService.userProfile?.phone ?? "Not provided")
            Divider().padding(.leading, 16)

            if let skill = authService.userProfile?.skillLevel {
                infoRow(icon: "star", label: "Skill Level", value: String(format: "%.1f", skill))
                Divider().padding(.leading, 16)
            }

            infoRow(icon: "person.text.rectangle", label: "Gender", value: authService.userProfile?.gender?.capitalized ?? "Not provided")
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(.rect(cornerRadius: 10))
        .liquidGlassStatic(cornerRadius: 10)
    }

    // MARK: - Account Settings

    private var accountSettingsSection: some View {
        VStack(spacing: 0) {
            HStack {
                Label("Account Settings", systemImage: "shield")
                    .font(.headline)
                Spacer()
            }
            .padding(16)

            Divider().padding(.leading, 16)

            if clubService.isAdmin {
                NavigationLink {
                    PaymentsView()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "dollarsign.circle")
                            .foregroundStyle(.secondary)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Payments")
                                .font(.body)
                            Text("Manage session payments")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)

                Divider().padding(.leading, 16)
            }

            settingsRow(icon: "key", title: "Change Password", subtitle: "Update your account password") {
                Task {
                    if let email = authService.userProfile?.email {
                        try? await authService.resetPassword(email: email)
                    }
                }
            }

            Divider().padding(.leading, 16)

            settingsRow(icon: "rectangle.portrait.and.arrow.right", title: "Sign Out", subtitle: "Sign out of your account") {
                showSignOutConfirm = true
            }
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(.rect(cornerRadius: 10))
        .liquidGlassStatic(cornerRadius: 10)
    }

    // MARK: - Helpers

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.body)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func settingsRow(icon: String, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Action", action: action)
                .font(.subheadline)
                .labelStyle(.titleOnly)
                .buttonStyle(.bordered)
                .controlSize(.small)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
