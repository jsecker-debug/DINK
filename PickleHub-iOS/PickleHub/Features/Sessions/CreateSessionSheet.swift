import SwiftUI

struct CreateSessionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ClubService.self) private var clubService
    @Environment(ToastManager.self) private var toastManager

    @State private var date = Date()
    @State private var venue = ""
    @State private var startTime = Date()
    @State private var endTime = Date().addingTimeInterval(7200)
    @State private var feePerPlayer = 10.0
    @State private var maxParticipants = 16
    @State private var isSaving = false

    var onSaved: () async -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    TextField("Venue", text: $venue)
                    DatePicker("Start Time", selection: $startTime, displayedComponents: .hourAndMinute)
                    DatePicker("End Time", selection: $endTime, displayedComponents: .hourAndMinute)
                }

                Section("Settings") {
                    HStack {
                        Text("Fee per Player")
                        Spacer()
                        TextField("Fee", value: $feePerPlayer, format: .currency(code: "USD"))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    Stepper("Max Participants: \(maxParticipants)", value: $maxParticipants, in: 4...40)
                }
            }
            .navigationTitle("New Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task { await createSession() }
                    }
                    .disabled(venue.isEmpty || isSaving)
                }
            }
        }
    }

    private func createSession() async {
        guard let clubId = clubService.selectedClubId else { return }
        isSaving = true
        defer { isSaving = false }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)

        do {
            _ = try await SessionRepository().createSession(
                clubId: clubId,
                date: dateString,
                venue: venue,
                feePerPlayer: feePerPlayer,
                maxParticipants: maxParticipants,
                startTime: startTime,
                endTime: endTime
            )
            await onSaved()
            toastManager.show("Session created", type: .success)
            dismiss()
        } catch {
            toastManager.show("Failed to create session: \(error.localizedDescription)", type: .error)
        }
    }
}
