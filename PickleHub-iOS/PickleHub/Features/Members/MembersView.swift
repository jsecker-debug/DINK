import SwiftUI

struct MembersView: View {
    @Environment(ClubService.self) private var clubService
    @Environment(AuthService.self) private var authService

    @State private var members: [ClubMemberWithProfile] = []
    @State private var searchText = ""
    @State private var isLoading = false
    @State private var showInviteSheet = false

    var body: some View {
        Group {
            if isLoading && members.isEmpty {
                LoadingView(message: "Loading members...")
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        statsRow
                        searchBar
                        membersList
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
        }
        .toolbar {
            if clubService.isAdmin {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showInviteSheet = true } label: {
                        Image(systemName: "person.badge.plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showInviteSheet) {
            InviteMemberSheet()
        }
        .refreshable { await loadData() }
        .task(id: clubService.selectedClubId) {
            members = []
            await loadData()
        }
    }

    // MARK: - Stats

    private var statsRow: some View {
        let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
        return LiquidGlassContainer(spacing: 12) {
            LazyVGrid(columns: columns, spacing: 12) {
                StatCardView(title: "Total Members", value: "\(members.count)", icon: "person.2.fill")
                StatCardView(title: "Active Players", value: "\(members.filter { $0.totalGamesPlayed >= 10 }.count)", icon: "figure.pickleball")
                StatCardView(title: "New (30d)", value: "\(recentMembers)", icon: "person.badge.clock")
                StatCardView(title: "Avg Level", value: avgLevel, icon: "chart.bar.fill")
            }
        }
    }

    // MARK: - Search

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search members...", text: $searchText)
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(.rect(cornerRadius: 10))
    }

    // MARK: - Members List

    private var membersList: some View {
        LazyVStack(spacing: 12) {
            ForEach(filteredMembers) { member in
                MemberCardView(member: member)
            }

            if filteredMembers.isEmpty && !isLoading {
                Text(searchText.isEmpty ? "No members yet" : "No results")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
            }
        }
    }

    // MARK: - Computed

    private var filteredMembers: [ClubMemberWithProfile] {
        guard !searchText.isEmpty else { return members }
        return members.filter { $0.fullName.localizedCaseInsensitiveContains(searchText) }
    }

    private var recentMembers: Int {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        return members.filter { ($0.joinedAt ?? .distantPast) > thirtyDaysAgo }.count
    }

    private var avgLevel: String {
        let levels = members.compactMap(\.skillLevel)
        guard !levels.isEmpty else { return "0.0" }
        return String(format: "%.1f", levels.reduce(0, +) / Double(levels.count))
    }

    private func loadData() async {
        guard let clubId = clubService.selectedClubId else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            members = try await MemberRepository().fetchClubMembers(clubId: clubId)
        } catch {
            print("Failed to load members: \(error)")
        }
    }
}
