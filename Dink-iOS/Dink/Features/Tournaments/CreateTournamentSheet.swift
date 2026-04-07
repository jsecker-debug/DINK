import SwiftUI

struct CreateTournamentSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ClubService.self) private var clubService
    @Environment(AuthService.self) private var authService
    @Environment(ToastManager.self) private var toastManager

    @State private var name = ""
    @State private var description = ""
    @State private var format = "round_robin"
    @State private var teamSize = 2
    @State private var maxTeams = 8
    @State private var useMaxTeams = false
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var useStartDate = false
    @State private var useEndDate = false
    @State private var isCreating = false

    private let repository = TournamentRepository()
    var onCreated: (() async -> Void)?

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Tournament Name", text: $name)

                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section("Format") {
                    Picker("Format", selection: $format) {
                        Text("Round Robin").tag("round_robin")
                        Text("Elimination").tag("elimination")
                    }

                    Stepper("Team Size: \(teamSize)", value: $teamSize, in: 1...4)
                }

                Section("Limits") {
                    Toggle("Set Max Teams", isOn: $useMaxTeams)
                    if useMaxTeams {
                        Stepper("Max Teams: \(maxTeams)", value: $maxTeams, in: 2...64)
                    }
                }

                Section("Dates") {
                    Toggle("Set Start Date", isOn: $useStartDate)
                    if useStartDate {
                        DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    }

                    Toggle("Set End Date", isOn: $useEndDate)
                    if useEndDate {
                        DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("New Tournament")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task { await createTournament() }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isCreating)
                }
            }
        }
    }

    private func createTournament() async {
        guard let clubId = clubService.selectedClubId,
              let userId = authService.userProfile?.id else { return }

        isCreating = true
        defer { isCreating = false }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        do {
            _ = try await repository.createTournament(
                clubId: clubId,
                name: name.trimmingCharacters(in: .whitespaces),
                description: description.isEmpty ? nil : description,
                format: format,
                maxTeams: useMaxTeams ? maxTeams : nil,
                teamSize: teamSize,
                startDate: useStartDate ? dateFormatter.string(from: startDate) : nil,
                endDate: useEndDate ? dateFormatter.string(from: endDate) : nil,
                createdBy: userId
            )
            toastManager.show("Tournament created", type: .success)
            await onCreated?()
            dismiss()
        } catch {
            toastManager.show("Failed to create tournament: \(error.localizedDescription)", type: .error)
        }
    }
}
