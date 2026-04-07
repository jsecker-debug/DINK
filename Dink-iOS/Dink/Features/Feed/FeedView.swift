import SwiftUI

struct FeedView: View {
    @Environment(ClubService.self) private var clubService
    @Environment(AuthService.self) private var authService

    @State private var activities: [ActivityWithRelatedData] = []
    @State private var filterType: FeedFilter = .all
    @State private var isLoading = false
    @State private var showCreatePost = false

    enum FeedFilter: String, CaseIterable {
        case all = "All"
        case sessions = "Sessions"
        case members = "Members"
        case tournaments = "Tournaments"
        case announcements = "Announcements"
        case polls = "Polls"
    }

    var body: some View {
        Group {
            if isLoading && activities.isEmpty {
                LoadingView(message: "Loading activity...")
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        filterChips
                        feedList
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showCreatePost = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showCreatePost) {
            CreatePostSheet { await loadData() }
        }
        .refreshable { await loadData() }
        .task(id: clubService.selectedClubId) {
            activities = []
            await loadData()
        }
    }

    // MARK: - Filter Chips

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(FeedFilter.allCases, id: \.self) { filter in
                    Button {
                        filterType = filter
                    } label: {
                        Text(filter.rawValue)
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(filterType == filter ? Color.accentColor : Color(.secondarySystemBackground))
                            .foregroundStyle(filterType == filter ? .white : .primary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Filter: \(filter.rawValue)")
                    .accessibilityAddTraits(filterType == filter ? .isSelected : [])
                }
            }
        }
    }

    // MARK: - Feed List

    private var feedList: some View {
        LazyVStack(spacing: 12) {
            ForEach(filteredActivities) { item in
                FeedItemView(item: item)
            }

            if filteredActivities.isEmpty && !isLoading {
                Text("No activity yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
            }
        }
    }

    // MARK: - Computed

    private var filteredActivities: [ActivityWithRelatedData] {
        switch filterType {
        case .all: return activities
        case .sessions: return activities.filter { $0.activity.type.contains("session") }
        case .members: return activities.filter { $0.activity.type.contains("member") }
        case .tournaments: return activities.filter { $0.activity.type.contains("tournament") }
        case .announcements: return activities.filter { $0.activity.type == "announcement" }
        case .polls: return activities.filter { $0.activity.type.contains("poll") }
        }
    }

    private func loadData() async {
        guard let clubId = clubService.selectedClubId else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            activities = try await ActivityRepository().fetchClubActivities(clubId: clubId)
        } catch {
            print("Failed to load feed: \(error)")
        }
    }
}
