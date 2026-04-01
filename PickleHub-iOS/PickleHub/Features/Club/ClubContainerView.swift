import SwiftUI

struct ClubContainerView: View {
    @Environment(ClubService.self) private var clubService
    @Environment(AuthService.self) private var authService

    @State private var selectedSegment: Segment = .members
    @State private var showClubSettings = false

    enum Segment: String, CaseIterable, Identifiable {
        case members = "Members"
        case rankings = "Rankings"
        case payments = "Payments"

        var id: String { rawValue }
    }

    /// Segments visible to the current user (Payments is admin-only).
    private var visibleSegments: [Segment] {
        if clubService.isAdmin {
            return Segment.allCases
        }
        return [.members, .rankings]
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ClubHeaderView()

                Picker("Section", selection: $selectedSegment) {
                    ForEach(visibleSegments) { segment in
                        Text(segment.rawValue).tag(segment)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)

                segmentContent
            }
            .navigationTitle("Club")
            .navigationDestination(for: ClubMemberWithProfile.self) { member in
                MemberDetailView(member: member)
            }
            .toolbar {
                if clubService.isAdmin {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showClubSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                        }
                    }
                }
            }
            .sheet(isPresented: $showClubSettings) {
                ClubSettingsView()
            }
        }
    }

    // MARK: - Segment Content

    @ViewBuilder
    private var segmentContent: some View {
        switch selectedSegment {
        case .members:
            MembersView()
        case .rankings:
            RankingsView()
        case .payments:
            PaymentsView()
        }
    }
}
