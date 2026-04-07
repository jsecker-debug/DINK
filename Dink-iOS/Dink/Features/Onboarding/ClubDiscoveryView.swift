import SwiftUI

struct ClubDiscoveryView: View {
    @Environment(AuthService.self) private var authService
    @Environment(ClubService.self) private var clubService

    @State private var searchText = ""
    @State private var clubs: [DiscoverableClub] = []
    @State private var pendingRequests: Set<UUID> = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    // Join request sheet
    @State private var selectedClub: DiscoverableClub?
    @State private var joinMessage = ""
    @State private var isSendingRequest = false

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading clubs...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if clubs.isEmpty && searchText.isEmpty {
                emptyState
            } else {
                clubList
            }
        }
        .navigationTitle("Join a Club")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search clubs")
        .task {
            await loadClubs()
            await loadPendingRequests()
        }
        .onChange(of: searchText) { _, newValue in
            Task { await search(query: newValue) }
        }
        .sheet(item: $selectedClub) { club in
            JoinRequestSheet(
                club: club,
                message: $joinMessage,
                isSending: isSendingRequest,
                onSend: { await sendJoinRequest(club: club) }
            )
            .presentationDetents([.medium])
        }
    }

    // MARK: - Club List

    private var clubList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if clubs.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    ForEach(clubs) { club in
                        ClubRow(
                            club: club,
                            hasPendingRequest: pendingRequests.contains(club.id),
                            onJoinTapped: { selectedClub = club }
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Clubs Yet", systemImage: "building.2")
        } description: {
            Text("There are no clubs to join right now. Why not create one?")
        }
    }

    // MARK: - Data Loading

    private func loadClubs() async {
        isLoading = true
        defer { isLoading = false }
        do {
            clubs = try await clubService.fetchDiscoverableClubs()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadPendingRequests() async {
        guard let userId = authService.user?.id else { return }
        do {
            let requests = try await clubService.fetchPendingJoinRequests(userId: userId)
            pendingRequests = Set(requests.map(\.clubId))
        } catch {
            // Non-critical, just won't show pending badges
        }
    }

    private func search(query: String) async {
        do {
            if query.trimmingCharacters(in: .whitespaces).isEmpty {
                clubs = try await clubService.fetchDiscoverableClubs()
            } else {
                clubs = try await clubService.searchClubs(query: query)
            }
        } catch {
            // Keep existing results on search error
        }
    }

    private func sendJoinRequest(club: DiscoverableClub) async {
        guard let userId = authService.user?.id else { return }
        isSendingRequest = true
        defer { isSendingRequest = false }

        do {
            try await clubService.requestToJoinClub(
                clubId: club.id,
                userId: userId,
                message: joinMessage.isEmpty ? nil : joinMessage
            )
            pendingRequests.insert(club.id)
            joinMessage = ""
            selectedClub = nil
        } catch {
            errorMessage = "Failed to send request: \(error.localizedDescription)"
        }
    }
}

// MARK: - Club Row

private struct ClubRow: View {
    let club: DiscoverableClub
    let hasPendingRequest: Bool
    let onJoinTapped: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            // Club icon
            Image(systemName: "building.2.fill")
                .font(.title3)
                .foregroundStyle(.dinkTeal)
                .frame(width: 40, height: 40)
                .background(Color.dinkTeal.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            // Club info
            VStack(alignment: .leading, spacing: 4) {
                Text(club.name)
                    .font(.headline)
                if let description = club.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                if let location = club.locationDisplay {
                    Label(location, systemImage: "mappin")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            // Action
            if hasPendingRequest {
                Text("Pending")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.dinkOrange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.dinkOrange.opacity(0.1))
                    .clipShape(Capsule())
            } else {
                Button("Join") {
                    onJoinTapped()
                }
                .font(.subheadline.weight(.medium))
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding(14)
        .background {
            if #available(iOS 26, *) {
                Color.clear
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            }
        }
        .liquidGlassStatic(cornerRadius: 12)
    }
}

// MARK: - Join Request Sheet

private struct JoinRequestSheet: View {
    let club: DiscoverableClub
    @Binding var message: String
    let isSending: Bool
    let onSend: () async -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Image(systemName: "person.badge.plus")
                        .font(.largeTitle)
                        .foregroundStyle(.dinkTeal)

                    Text("Join \(club.name)")
                        .font(.title3.bold())

                    Text("Send a request to the club admin. They'll review and approve your membership.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                TextField("Add a message (optional)", text: $message, axis: .vertical)
                    .lineLimit(3...5)
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                Button {
                    Task { await onSend() }
                } label: {
                    Group {
                        if isSending {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Send Request")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                .controlSize(.large)
                .buttonStyle(.borderedProminent)
                .disabled(isSending)

                Spacer()
            }
            .padding(20)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - DiscoverableClub Hashable conformance for sheet

extension DiscoverableClub: Hashable {
    static func == (lhs: DiscoverableClub, rhs: DiscoverableClub) -> Bool {
        lhs.id == rhs.id
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
