import SwiftUI
import PhotosUI

struct ProfileView: View {
    @Environment(AuthService.self) private var authService
    @Environment(ClubService.self) private var clubService

    @State private var attendanceStats: AttendanceStats?
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
        .task {
            if let userId = authService.user?.id,
               let clubId = clubService.selectedClubId {
                attendanceStats = try? await AttendanceRepository().fetchAttendanceStats(userId: userId, clubId: clubId)
            }
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
                        .background(.dinkTeal)
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
        let profile = authService.userProfile
        let gamesPlayed = profile?.totalGamesPlayed ?? 0
        let wins = profile?.wins ?? 0
        let losses = profile?.losses ?? 0
        let winRate = gamesPlayed > 0 ? Double(wins) / Double(gamesPlayed) * 100 : 0

        return LiquidGlassContainer(spacing: 12) {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                StatCardView(title: "Games Played", value: "\(gamesPlayed)", subtitle: "Total", icon: "trophy", iconColor: .dinkTeal)
                StatCardView(title: "Win Rate", value: String(format: "%.0f%%", winRate), subtitle: gamesPlayed > 0 ? "Of \(gamesPlayed) games" : "No games yet", icon: "target", iconColor: .dinkNavy)
                StatCardView(title: "Total Wins", value: "\(wins)", subtitle: gamesPlayed > 0 ? "Keep it up!" : "No games yet", icon: "arrow.up.right", iconColor: .dinkGreen)
                StatCardView(title: "Total Losses", value: "\(losses)", subtitle: gamesPlayed > 0 ? "Room to grow" : "No games yet", icon: "arrow.down.right", iconColor: .red)
                StatCardView(title: "MVP Awards", value: "\(profile?.mvpCount ?? 0)", subtitle: (profile?.mvpCount ?? 0) > 0 ? "Player of the Match" : "No awards yet", icon: "trophy.fill", iconColor: .yellow)
                if let stats = attendanceStats {
                    StatCardView(title: "Attendance", value: "\(Int(stats.attendanceRate))%", subtitle: "\(stats.attendedSessions)/\(stats.totalSessions) sessions", icon: "checkmark.circle.fill", iconColor: .dinkGreen)
                }
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
