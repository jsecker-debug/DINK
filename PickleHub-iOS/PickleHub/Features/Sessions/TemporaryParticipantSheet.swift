import SwiftUI

struct TemporaryParticipantSheet: View {
    let sessionId: Int

    @Environment(\.dismiss) private var dismiss
    @Environment(AuthService.self) private var authService

    @State private var name = ""
    @State private var skillLevel = 3.0
    @State private var phone = ""
    @State private var notes = ""
    @State private var existingParticipants: [TemporaryParticipant] = []
    @State private var isSaving = false

    var onSaved: () async -> Void

    private let skillLevels = stride(from: 2.0, through: 5.0, by: 0.5).map { $0 }

    var body: some View {
        NavigationStack {
            Form {
                Section("Add Guest Player") {
                    TextField("Name", text: $name)
                    Picker("Skill Level", selection: $skillLevel) {
                        ForEach(skillLevels, id: \.self) { level in
                            Text(String(format: "%.1f", level)).tag(level)
                        }
                    }
                    TextField("Phone (optional)", text: $phone)
                        .keyboardType(.phonePad)
                    TextField("Notes (optional)", text: $notes)
                }

                if !existingParticipants.isEmpty {
                    Section("Current Guests") {
                        ForEach(existingParticipants) { tp in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(tp.name).font(.subheadline)
                                    Text("Level \(String(format: "%.1f", tp.skillLevel))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                        }
                        .onDelete(perform: deleteParticipant)
                    }
                }
            }
            .navigationTitle("Guest Players")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task { await addParticipant() }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                }
            }
            .task { await loadExisting() }
        }
    }

    private func addParticipant() async {
        guard let userId = authService.user?.id else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            _ = try await TemporaryParticipantRepository().addTemporaryParticipant(
                sessionId: sessionId,
                name: name,
                skillLevel: skillLevel,
                phone: phone.isEmpty ? nil : phone,
                notes: notes.isEmpty ? nil : notes,
                createdBy: userId
            )
            name = ""
            phone = ""
            notes = ""
            await loadExisting()
            await onSaved()
        } catch {
            print("Failed to add temp participant: \(error)")
        }
    }

    private func deleteParticipant(at offsets: IndexSet) {
        for index in offsets {
            let participant = existingParticipants[index]
            Task {
                try? await TemporaryParticipantRepository().removeTemporaryParticipant(id: participant.id)
                await loadExisting()
                await onSaved()
            }
        }
    }

    private func loadExisting() async {
        do {
            existingParticipants = try await TemporaryParticipantRepository()
                .fetchTemporaryParticipants(sessionId: sessionId)
        } catch {
            print("Failed to load temp participants: \(error)")
        }
    }
}
