import SwiftUI

struct MVPVotingSheet: View {
    let sessionId: Int
    let participants: [SessionRegistrationWithUser]
    let currentUserId: UUID

    @Environment(ToastManager.self) private var toastManager
    @Environment(\.dismiss) private var dismiss

    @State private var selectedNomineeId: UUID?
    @State private var isSubmitting = false
    @State private var hasVoted = false
    @State private var results: [MVPResult] = []
    @State private var isLoading = true

    private var eligibleParticipants: [SessionRegistrationWithUser] {
        participants.filter { $0.userId != currentUserId && $0.status == "registered" }
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    LoadingView(message: "Loading...")
                } else if hasVoted {
                    MVPResultsView(results: results, participants: participants)
                } else {
                    votingContent
                }
            }
            .navigationTitle("Player of the Match")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .task { await checkVoteStatus() }
        }
    }

    // MARK: - Voting Content

    private var votingContent: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Vote for the player who stood out this session")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                    VStack(spacing: 0) {
                        ForEach(eligibleParticipants) { participant in
                            nomineeRow(participant)

                            if participant.id != eligibleParticipants.last?.id {
                                Divider().padding(.leading, 68)
                            }
                        }
                    }
                    .background(Color(.secondarySystemBackground))
                    .clipShape(.rect(cornerRadius: 10))
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 16)
            }

            submitButton
        }
    }

    private func nomineeRow(_ participant: SessionRegistrationWithUser) -> some View {
        let isSelected = selectedNomineeId == participant.userId

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedNomineeId = participant.userId
            }
        } label: {
            HStack(spacing: 12) {
                AvatarView(
                    firstName: participant.userProfiles?.firstName,
                    lastName: participant.userProfiles?.lastName,
                    avatarUrl: participant.userProfiles?.avatarUrl,
                    size: 40
                )

                Text(participant.userProfiles?.fullName ?? "Unknown")
                    .font(.body)
                    .foregroundStyle(.primary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.dinkTeal)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var submitButton: some View {
        VStack {
            Divider()
            Button {
                Task { await submitVote() }
            } label: {
                Text("Submit Vote")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedNomineeId == nil || isSubmitting)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Actions

    private func checkVoteStatus() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let alreadyVoted = try await MVPRepository().hasVoted(sessionId: sessionId, userId: currentUserId)
            if alreadyVoted {
                results = try await MVPRepository().fetchResults(sessionId: sessionId)
                hasVoted = true
            }
        } catch {
            print("Failed to check MVP vote status: \(error)")
        }
    }

    private func submitVote() async {
        guard let nomineeId = selectedNomineeId else { return }
        isSubmitting = true

        do {
            try await MVPRepository().castVote(sessionId: sessionId, voterId: currentUserId, nomineeId: nomineeId)
            results = try await MVPRepository().fetchResults(sessionId: sessionId)
            withAnimation {
                hasVoted = true
            }
            toastManager.show("Vote submitted!", type: .success)
        } catch {
            toastManager.show("Failed to submit vote: \(error.localizedDescription)", type: .error)
        }

        isSubmitting = false
    }
}
