import SwiftUI

struct PollsListView: View {
    @Environment(ClubService.self) private var clubService
    @Environment(AuthService.self) private var authService
    @Environment(ToastManager.self) private var toastManager

    @State private var polls: [Poll] = []
    @State private var pollDetails: [UUID: (options: [PollOption], votes: [PollVote])] = [:]
    @State private var isLoading = false
    @State private var showCreatePoll = false

    var body: some View {
        NavigationStack {
            Group {
                if isLoading && polls.isEmpty {
                    LoadingView(message: "Loading polls...")
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(polls) { poll in
                                if let details = pollDetails[poll.id] {
                                    PollCardView(
                                        poll: poll,
                                        options: details.options,
                                        votes: details.votes,
                                        currentUserId: authService.user?.id ?? UUID(),
                                        onVote: { optionId in
                                            await handleVote(pollId: poll.id, optionId: optionId)
                                        },
                                        onRemoveVote: { optionId in
                                            await handleRemoveVote(pollId: poll.id, optionId: optionId)
                                        }
                                    )
                                }
                            }

                            if polls.isEmpty && !isLoading {
                                Text("No polls yet")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 32)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                }
            }
            .navigationTitle("Polls")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showCreatePoll = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCreatePoll) {
                CreatePollSheet { await loadData() }
            }
            .refreshable { await loadData() }
            .task(id: clubService.selectedClubId) {
                polls = []
                pollDetails = [:]
                await loadData()
            }
        }
    }

    // MARK: - Data Loading

    private func loadData() async {
        guard let clubId = clubService.selectedClubId else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let repo = PollRepository()
            polls = try await repo.fetchPolls(clubId: clubId)

            for poll in polls {
                let details = try await repo.fetchPollDetails(pollId: poll.id)
                pollDetails[poll.id] = (options: details.options, votes: details.votes)
            }
        } catch {
            toastManager.show("Failed to load polls", type: .error)
            print("Failed to load polls: \(error)")
        }
    }

    // MARK: - Voting

    private func handleVote(pollId: UUID, optionId: UUID) async {
        guard let userId = authService.user?.id else { return }
        do {
            try await PollRepository().vote(pollId: pollId, optionId: optionId, userId: userId)
            await refreshPollDetails(pollId: pollId)
        } catch {
            toastManager.show("Failed to vote", type: .error)
            print("Failed to vote: \(error)")
        }
    }

    private func handleRemoveVote(pollId: UUID, optionId: UUID) async {
        guard let userId = authService.user?.id else { return }
        do {
            try await PollRepository().removeVote(pollId: pollId, optionId: optionId, userId: userId)
            await refreshPollDetails(pollId: pollId)
        } catch {
            toastManager.show("Failed to remove vote", type: .error)
            print("Failed to remove vote: \(error)")
        }
    }

    private func refreshPollDetails(pollId: UUID) async {
        do {
            let details = try await PollRepository().fetchPollDetails(pollId: pollId)
            pollDetails[pollId] = (options: details.options, votes: details.votes)
        } catch {
            print("Failed to refresh poll details: \(error)")
        }
    }
}
