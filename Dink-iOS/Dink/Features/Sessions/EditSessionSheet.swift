import SwiftUI

struct EditSessionSheet: View {
    let session: ClubSession

    @Environment(\.dismiss) private var dismiss
    @Environment(ToastManager.self) private var toastManager

    @State private var venue: String
    @State private var feePerPlayer: Double
    @State private var maxParticipants: Int
    @State private var isSaving = false

    var onSaved: () async -> Void

    init(session: ClubSession, onSaved: @escaping () async -> Void) {
        self.session = session
        self.onSaved = onSaved
        _venue = State(initialValue: session.venue ?? "")
        _feePerPlayer = State(initialValue: session.feePerPlayer ?? 0)
        _maxParticipants = State(initialValue: session.maxParticipants ?? 16)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Venue", text: $venue)
                }

                Section("Settings") {
                    HStack {
                        Text("Fee per Player")
                        Spacer()
                        TextField("Fee", value: $feePerPlayer, format: .currency(code: "GBP"))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    Stepper("Max Participants: \(maxParticipants)", value: $maxParticipants, in: 4...40)
                }
            }
            .navigationTitle("Edit Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await save() }
                    }
                    .disabled(venue.isEmpty || isSaving)
                }
            }
        }
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        do {
            _ = try await SessionRepository().updateSession(
                id: session.id,
                venue: venue,
                feePerPlayer: feePerPlayer,
                maxParticipants: maxParticipants
            )
            await onSaved()
            toastManager.show("Session updated", type: .success)
            dismiss()
        } catch {
            toastManager.show("Failed to update session: \(error.localizedDescription)", type: .error)
        }
    }
}
