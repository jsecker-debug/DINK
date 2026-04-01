import SwiftUI

// MARK: - Hashable Conformance for Navigation

extension ClubMemberWithProfile: Hashable {
    static func == (lhs: ClubMemberWithProfile, rhs: ClubMemberWithProfile) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct MemberDetailView: View {
    @Environment(ClubService.self) private var clubService
    @Environment(ToastManager.self) private var toastManager

    let member: ClubMemberWithProfile

    @State private var showRemoveConfirmation = false
    @State private var isUpdatingRole = false
    @State private var isRemoving = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                avatarSection
                skillBadge
                statsGrid
                if clubService.isAdmin {
                    adminSection
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .navigationTitle(member.fullName)
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Remove Member",
            isPresented: $showRemoveConfirmation,
            titleVisibility: .visible
        ) {
            Button("Remove from Club", role: .destructive) {
                Task { await removeMember() }
            }
        } message: {
            Text("Are you sure you want to remove \(member.fullName) from the club? This action cannot be undone.")
        }
    }

    // MARK: - Avatar Section

    private var avatarSection: some View {
        VStack(spacing: 12) {
            AvatarView(
                firstName: firstNameFromFull,
                lastName: lastNameFromFull,
                avatarUrl: member.avatarUrl,
                size: 96
            )

            Text(member.fullName)
                .font(.title2)
                .fontWeight(.semibold)

            if member.role.lowercased() == "admin" || member.role.lowercased() == "owner" {
                BadgeView(text: member.role.capitalized, style: .info)
            } else {
                BadgeView(text: "Member", style: .secondary)
            }

            VStack(spacing: 4) {
                if let phone = member.phone {
                    Label(phone, systemImage: "phone")
                }
                if let gender = member.gender {
                    Label(gender.capitalized, systemImage: "person.text.rectangle")
                }
                if let joinedAt = member.joinedAt {
                    Label("Joined \(joinedAt.monthYear)", systemImage: "calendar")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: - Skill Badge

    @ViewBuilder
    private var skillBadge: some View {
        if let level = member.skillLevel {
            HStack(spacing: 8) {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(.blue)
                Text("Skill Level")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(String(format: "%.1f", level))
                    .font(.title3.bold())
            }
            .padding(16)
            .background(Color(.secondarySystemBackground))
            .clipShape(.rect(cornerRadius: 10))
            .liquidGlassStatic(cornerRadius: 10)
        }
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        LiquidGlassContainer(spacing: 12) {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                StatCardView(title: "Games Played", value: "\(member.totalGamesPlayed)", icon: "sportscourt.fill", iconColor: .blue)
                StatCardView(title: "Wins", value: "\(member.wins)", icon: "arrow.up.right", iconColor: .green)
                StatCardView(title: "Losses", value: "\(member.losses)", icon: "arrow.down.right", iconColor: .red)
                StatCardView(title: "Win Rate", value: winRate, icon: "percent", iconColor: .purple)
            }
        }
    }

    // MARK: - Admin Section

    private var adminSection: some View {
        VStack(spacing: 0) {
            HStack {
                Label("Admin Actions", systemImage: "shield")
                    .font(.headline)
                Spacer()
            }
            .padding(16)

            Divider().padding(.leading, 16)

            // Change Role
            HStack(spacing: 12) {
                Image(systemName: "person.badge.key")
                    .foregroundStyle(.secondary)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Role")
                        .font(.body)
                    Text("Currently: \(member.role.capitalized)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    Task { await toggleRole() }
                } label: {
                    Text(member.role.lowercased() == "admin" ? "Set Member" : "Set Admin")
                        .font(.subheadline)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(isUpdatingRole || member.role.lowercased() == "owner")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider().padding(.leading, 16)

            // Remove from Club
            HStack(spacing: 12) {
                Image(systemName: "person.badge.minus")
                    .foregroundStyle(.red)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Remove from Club")
                        .font(.body)
                    Text("Permanently remove this member")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(role: .destructive) {
                    showRemoveConfirmation = true
                } label: {
                    Text("Remove")
                        .font(.subheadline)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(isRemoving || member.role.lowercased() == "owner")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(.rect(cornerRadius: 10))
        .liquidGlassStatic(cornerRadius: 10)
    }

    // MARK: - Computed

    private var winRate: String {
        guard member.totalGamesPlayed > 0 else { return "0%" }
        let rate = Double(member.wins) / Double(member.totalGamesPlayed) * 100
        return "\(Int(rate))%"
    }

    private var firstNameFromFull: String? {
        let parts = member.fullName.split(separator: " ")
        return parts.first.map(String.init)
    }

    private var lastNameFromFull: String? {
        let parts = member.fullName.split(separator: " ")
        return parts.count > 1 ? String(parts.last!) : nil
    }

    // MARK: - Actions

    private func toggleRole() async {
        guard let clubId = clubService.selectedClubId else { return }
        isUpdatingRole = true
        defer { isUpdatingRole = false }

        let newRole = member.role.lowercased() == "admin" ? "member" : "admin"
        do {
            try await supabase
                .from("club_memberships")
                .update(["role": newRole])
                .eq("club_id", value: clubId.uuidString)
                .eq("user_id", value: member.userId.uuidString)
                .execute()
            toastManager.show("Role updated to \(newRole.capitalized)", type: .success)
        } catch {
            toastManager.show("Failed to update role", type: .error)
        }
    }

    private func removeMember() async {
        guard let clubId = clubService.selectedClubId else { return }
        isRemoving = true
        defer { isRemoving = false }

        do {
            try await supabase
                .from("club_memberships")
                .update(["status": "removed"])
                .eq("club_id", value: clubId.uuidString)
                .eq("user_id", value: member.userId.uuidString)
                .execute()
            toastManager.show("\(member.fullName) removed from club", type: .success)
        } catch {
            toastManager.show("Failed to remove member", type: .error)
        }
    }
}
