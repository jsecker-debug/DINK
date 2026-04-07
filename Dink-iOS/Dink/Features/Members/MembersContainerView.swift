import SwiftUI

struct MembersContainerView: View {
    @State private var selectedSegment: Segment = .members

    enum Segment: String, CaseIterable {
        case members = "Members"
        case activity = "Activity"
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Section", selection: $selectedSegment) {
                ForEach(Segment.allCases, id: \.self) { segment in
                    Text(segment.rawValue).tag(segment)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)
            .padding(.vertical, 8)

            switch selectedSegment {
            case .members:
                MembersView()
            case .activity:
                FeedView()
            }
        }
        .navigationTitle(selectedSegment == .members ? "Members" : "Activity")
    }
}
