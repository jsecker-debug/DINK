import SwiftUI

struct JoinRequestsView: View {
    @Environment(ClubService.self) private var clubService
    @Environment(ToastManager.self) private var toastManager

    @State private var requests: [AdminJoinRequest] = []
    @State private var isLoading = false

    var body: some View {
        Group {
            if isLoading {
                LoadingView(message: "Loading join requests...")
            } else if requests.isEmpty {
                EmptyStateView(
                    icon: "person.badge.clock",
                    title: "No Pending Requests",
                    message: "There are no pending join requests for this club."
                )
            } else {
                requestList
            }
        }
        .navigationTitle("Join Requests")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await loadRequests() }
        .task(id: clubService.selectedClubId) {
            await loadRequests()
        }
    }

    // MARK: - Request List

    private var requestList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(requests) { request in
                    requestCard(request)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }

    private func requestCard(_ request: AdminJoinRequest) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.circle")
                    .font(.title2)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 2) {
                    let name = request.userData?.fullName ?? "Unknown User"
                    Text(name.isEmpty ? "Unknown User" : name)
                        .font(.headline)

                    if let email = request.userData?.email {
                        Text(email)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if let skillLevel = request.userData?.skillLevel {
                    Text(String(format: "%.1f", skillLevel))
                        .font(.caption.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.dinkTeal.opacity(0.15))
                        .foregroundStyle(.dinkTeal)
                        .clipShape(Capsule())
                }
            }

            if let message = request.message, !message.isEmpty {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if let createdAt = request.createdAt {
                Text(createdAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            HStack(spacing: 12) {
                Button {
                    Task { await approveRequest(request) }
                } label: {
                    Label("Approve", systemImage: "checkmark.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.dinkGreen)

                Button {
                    Task { await rejectRequest(request) }
                } label: {
                    Label("Reject", systemImage: "xmark.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(.rect(cornerRadius: 10))
        .liquidGlassStatic(cornerRadius: 10)
    }

    // MARK: - Data Loading

    private func loadRequests() async {
        guard let clubId = clubService.selectedClubId else { return }
        isLoading = requests.isEmpty
        defer { isLoading = false }

        do {
            requests = try await clubService.fetchClubJoinRequests(clubId: clubId)
        } catch {
            toastManager.show("Failed to load join requests", type: .error)
        }
    }

    private func approveRequest(_ request: AdminJoinRequest) async {
        guard let clubId = clubService.selectedClubId else { return }

        do {
            try await clubService.approveJoinRequest(
                requestId: request.id,
                clubId: clubId,
                userId: request.userId
            )
            requests.removeAll { $0.id == request.id }
            toastManager.show("Request approved", type: .success)
        } catch {
            toastManager.show("Failed to approve: \(error.localizedDescription)", type: .error)
        }
    }

    private func rejectRequest(_ request: AdminJoinRequest) async {
        do {
            try await clubService.rejectJoinRequest(requestId: request.id)
            requests.removeAll { $0.id == request.id }
            toastManager.show("Request rejected", type: .success)
        } catch {
            toastManager.show("Failed to reject: \(error.localizedDescription)", type: .error)
        }
    }
}
