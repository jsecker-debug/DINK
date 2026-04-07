import SwiftUI

struct SubgroupDetailView: View {
    @Environment(ClubService.self) private var clubService
    @Environment(ToastManager.self) private var toastManager

    let subgroup: Subgroup
    var onChanged: () async -> Void

    @State private var subgroupMembers: [SubgroupMember] = []
    @State private var clubMembers: [ClubMemberWithProfile] = []
    @State private var isLoading = false
    @State private var showAddMemberSheet = false

    /// User IDs of current subgroup members for fast lookup.
    private var memberUserIds: Set<UUID> {
        Set(subgroupMembers.map(\.userId))
    }

    /// Club members who are already in this subgroup.
    private var currentMembers: [ClubMemberWithProfile] {
        clubMembers.filter { memberUserIds.contains($0.userId) }
    }

    /// Club members who are NOT yet in this subgroup.
    private var availableMembers: [ClubMemberWithProfile] {
        clubMembers.filter { !memberUserIds.contains($0.userId) }
    }

    var body: some View {
        Group {
            if isLoading && subgroupMembers.isEmpty {
                LoadingView(message: "Loading members...")
            } else if currentMembers.isEmpty {
                EmptyStateView(
                    icon: "person.3.slash",
                    title: "No Members",
                    message: "Add members to this subgroup."
                )
            } else {
                List {
                    ForEach(currentMembers) { member in
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color(hex: subgroup.color))
                                .frame(width: 8, height: 8)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(member.fullName)
                                    .font(.headline)
                                if let level = member.skillLevel {
                                    Text("Level \(String(format: "%.1f", level))")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                        .listRowBackground(
                            Color.clear
                                .liquidGlassStatic(cornerRadius: 10)
                        )
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                Task { await removeMember(userId: member.userId) }
                            } label: {
                                Label("Remove", systemImage: "person.badge.minus")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(subgroup.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddMemberSheet = true
                } label: {
                    Image(systemName: "person.badge.plus")
                }
            }
        }
        .sheet(isPresented: $showAddMemberSheet) {
            addMemberSheet
        }
        .refreshable { await loadData() }
        .task { await loadData() }
    }

    // MARK: - Add Member Sheet

    private var addMemberSheet: some View {
        NavigationStack {
            Group {
                if availableMembers.isEmpty {
                    EmptyStateView(
                        icon: "person.3.fill",
                        title: "All Members Added",
                        message: "Every club member is already in this subgroup."
                    )
                } else {
                    List {
                        ForEach(availableMembers) { member in
                            Button {
                                Task {
                                    await addMember(userId: member.userId)
                                    showAddMemberSheet = false
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(member.fullName)
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                        if let level = member.skillLevel {
                                            Text("Level \(String(format: "%.1f", level))")
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    Spacer()
                                    Image(systemName: "plus.circle")
                                        .foregroundStyle(.dinkTeal)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showAddMemberSheet = false }
                }
            }
        }
    }

    // MARK: - Actions

    private func loadData() async {
        guard let clubId = clubService.selectedClubId else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            async let fetchMembers = SubgroupRepository().fetchSubgroupMembers(subgroupId: subgroup.id)
            async let fetchClub = MemberRepository().fetchClubMembers(clubId: clubId)
            subgroupMembers = try await fetchMembers
            clubMembers = try await fetchClub
        } catch {
            toastManager.show("Failed to load members: \(error.localizedDescription)", type: .error)
        }
    }

    private func addMember(userId: UUID) async {
        do {
            try await SubgroupRepository().addMember(subgroupId: subgroup.id, userId: userId)
            await loadData()
            await onChanged()
            toastManager.show("Member added", type: .success)
        } catch {
            toastManager.show("Failed to add member: \(error.localizedDescription)", type: .error)
        }
    }

    private func removeMember(userId: UUID) async {
        do {
            try await SubgroupRepository().removeMember(subgroupId: subgroup.id, userId: userId)
            subgroupMembers.removeAll { $0.userId == userId }
            await onChanged()
            toastManager.show("Member removed", type: .success)
        } catch {
            toastManager.show("Failed to remove member: \(error.localizedDescription)", type: .error)
        }
    }
}
