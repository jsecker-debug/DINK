import SwiftUI

struct CreatePostSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ClubService.self) private var clubService
    @Environment(AuthService.self) private var authService

    @State private var postType = "announcement"
    @State private var title = ""
    @State private var content = ""
    @State private var isSaving = false

    var onSaved: () async -> Void

    private let postTypes = [
        ("announcement", "Announcement"),
        ("general_update", "General Update"),
        ("event", "Event"),
        ("tournament_result", "Tournament Result")
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Type", selection: $postType) {
                        ForEach(postTypes, id: \.0) { type in
                            Text(type.1).tag(type.0)
                        }
                    }

                    TextField("Title", text: $title)

                    TextField("Content", text: $content, axis: .vertical)
                        .lineLimit(4...10)
                }
            }
            .navigationTitle("Create Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Post") {
                        Task { await createPost() }
                    }
                    .disabled(title.isEmpty || isSaving)
                }
            }
        }
    }

    private func createPost() async {
        guard let clubId = clubService.selectedClubId,
              let userId = authService.user?.id else { return }
        isSaving = true
        defer { isSaving = false }

        struct ActivityInsert: Codable {
            let clubId: UUID
            let type: String
            let actorId: UUID
            let data: DataPayload

            struct DataPayload: Codable {
                let title: String
                let message: String
            }

            enum CodingKeys: String, CodingKey {
                case clubId = "club_id"
                case type
                case actorId = "actor_id"
                case data
            }
        }

        let payload = ActivityInsert(
            clubId: clubId,
            type: postType,
            actorId: userId,
            data: .init(title: title, message: content)
        )

        do {
            try await supabase
                .from("activities")
                .insert(payload)
                .execute()
            await onSaved()
            dismiss()
        } catch {
            print("Failed to create post: \(error)")
        }
    }
}
