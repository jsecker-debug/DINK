import SwiftUI

struct NewConversationSheet: View {
    @Environment(ClubService.self) private var clubService
    @Environment(AuthService.self) private var authService
    @Environment(ToastManager.self) private var toastManager
    @Environment(\.dismiss) private var dismiss

    var onCreated: ((ChatConversation) -> Void)?

    @State private var members: [ClubMemberWithProfile] = []
    @State private var selectedMemberIds: Set<UUID> = []
    @State private var conversationName = ""
    @State private var isLoading = false
    @State private var isCreating = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Conversation Name (Optional)") {
                    TextField("Group name", text: $conversationName)
                }

                Section("Select Members") {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else if members.isEmpty {
                        Text("No members found")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(members) { member in
                            Button {
                                toggleSelection(member)
                            } label: {
                                HStack {
                                    AvatarView(
                                        firstName: member.fullName.components(separatedBy: " ").first,
                                        lastName: member.fullName.components(separatedBy: " ").dropFirst().first.map { String($0) },
                                        avatarUrl: member.avatarUrl,
                                        size: 36
                                    )

                                    Text(member.fullName)
                                        .foregroundStyle(.primary)

                                    Spacer()

                                    if selectedMemberIds.contains(member.userId) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(Color.accentColor)
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Conversation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task { await createConversation() }
                    }
                    .disabled(selectedMemberIds.isEmpty || isCreating)
                }
            }
            .task {
                await loadMembers()
            }
        }
    }

    // MARK: - Selection

    private func toggleSelection(_ member: ClubMemberWithProfile) {
        if selectedMemberIds.contains(member.userId) {
            selectedMemberIds.remove(member.userId)
        } else {
            selectedMemberIds.insert(member.userId)
        }
    }

    // MARK: - Data

    private func loadMembers() async {
        guard let clubId = clubService.selectedClubId else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let allMembers = try await MemberRepository().fetchClubMembers(clubId: clubId)
            // Exclude the current user from the list
            if let currentUserId = authService.user?.id {
                members = allMembers.filter { $0.userId != currentUserId }
            } else {
                members = allMembers
            }
        } catch {
            toastManager.show("Failed to load members", type: .error)
        }
    }

    private func createConversation() async {
        guard let clubId = clubService.selectedClubId,
              let currentUserId = authService.user?.id else { return }

        isCreating = true
        defer { isCreating = false }

        // Include the current user as a participant
        var participantIds = Array(selectedMemberIds)
        participantIds.append(currentUserId)

        let name = conversationName.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            let conversation = try await ChatRepository().createConversation(
                clubId: clubId,
                name: name.isEmpty ? nil : name,
                participantIds: participantIds
            )
            onCreated?(conversation)
            toastManager.show("Conversation created", type: .success)
            dismiss()
        } catch {
            toastManager.show("Failed to create conversation", type: .error)
        }
    }
}
