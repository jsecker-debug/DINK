import SwiftUI

struct SubgroupManagementView: View {
    @Environment(ClubService.self) private var clubService
    @Environment(ToastManager.self) private var toastManager

    @State private var subgroups: [Subgroup] = []
    @State private var memberCounts: [UUID: Int] = [:]
    @State private var isLoading = false
    @State private var showCreateSheet = false
    @State private var subgroupToEdit: Subgroup?

    var body: some View {
        Group {
            if isLoading && subgroups.isEmpty {
                LoadingView(message: "Loading subgroups...")
            } else if subgroups.isEmpty {
                EmptyStateView(
                    icon: "person.3.slash",
                    title: "No Subgroups",
                    message: "Create a subgroup to organize your members."
                )
            } else {
                List {
                    ForEach(subgroups) { subgroup in
                        NavigationLink {
                            SubgroupDetailView(subgroup: subgroup) {
                                await loadSubgroups()
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(Color(hex: subgroup.color))
                                    .frame(width: 12, height: 12)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(subgroup.name)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    if let desc = subgroup.description, !desc.isEmpty {
                                        Text(desc)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }
                                }
                                Spacer()
                                Text("\(memberCounts[subgroup.id] ?? 0)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Image(systemName: "person.2")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(
                            Color.clear
                                .liquidGlassStatic(cornerRadius: 10)
                        )
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                Task { await deleteSubgroup(subgroup) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Subgroups")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showCreateSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            CreateSubgroupSheet { await loadSubgroups() }
        }
        .refreshable { await loadSubgroups() }
        .task(id: clubService.selectedClubId) { await loadSubgroups() }
    }

    // MARK: - Actions

    private func loadSubgroups() async {
        guard let clubId = clubService.selectedClubId else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let repo = SubgroupRepository()
            subgroups = try await repo.fetchSubgroups(clubId: clubId)

            var counts: [UUID: Int] = [:]
            for subgroup in subgroups {
                let members = try await repo.fetchSubgroupMembers(subgroupId: subgroup.id)
                counts[subgroup.id] = members.count
            }
            memberCounts = counts
        } catch {
            toastManager.show("Failed to load subgroups: \(error.localizedDescription)", type: .error)
        }
    }

    private func deleteSubgroup(_ subgroup: Subgroup) async {
        do {
            try await SubgroupRepository().deleteSubgroup(id: subgroup.id)
            subgroups.removeAll { $0.id == subgroup.id }
            memberCounts.removeValue(forKey: subgroup.id)
            toastManager.show("Subgroup deleted", type: .success)
        } catch {
            toastManager.show("Failed to delete subgroup: \(error.localizedDescription)", type: .error)
        }
    }
}
