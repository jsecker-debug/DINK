import SwiftUI

struct CreateSessionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthService.self) private var authService
    @Environment(ClubService.self) private var clubService
    @Environment(ToastManager.self) private var toastManager

    @State private var sessionType: SessionType = .openPlay
    @State private var date = Date()
    @State private var venue = ""
    @State private var startTime = Date()
    @State private var endTime = Date().addingTimeInterval(7200)
    @State private var feePerPlayer = 10.0
    @State private var maxParticipants = 16
    @State private var isSaving = false

    // Recurring session fields
    @State private var isRecurring = false
    @State private var frequency = "weekly"
    @State private var endType = "occurrences"
    @State private var maxOccurrences = 8
    @State private var recurringEndDate = Date().addingTimeInterval(86400 * 90)

    // Tournament-specific fields
    @State private var tournamentName = ""
    @State private var teamSize = 2
    @State private var maxTeams = 16
    @State private var hasMaxTeams = false
    @State private var courtCount = 4  // For King of the Court

    var onSaved: () async -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Session Type") {
                    Picker("Type", selection: $sessionType) {
                        ForEach(SessionType.allCases) { type in
                            Label(type.displayName, systemImage: type.icon)
                                .tag(type)
                        }
                    }

                    if sessionType != .openPlay {
                        Text(sessionType.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Details") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    TextField("Venue", text: $venue)
                    DatePicker("Start Time", selection: $startTime, displayedComponents: .hourAndMinute)
                    DatePicker("End Time", selection: $endTime, displayedComponents: .hourAndMinute)
                }

                if sessionType.isTournament {
                    Section("Tournament Settings") {
                        TextField("Tournament Name", text: $tournamentName)
                        Stepper("Team Size: \(teamSize)", value: $teamSize, in: 1...4)

                        Toggle("Limit Teams", isOn: $hasMaxTeams)
                        if hasMaxTeams {
                            Stepper("Max Teams: \(maxTeams)", value: $maxTeams, in: 2...64)
                        }

                        if sessionType == .kingOfTheCourt {
                            Stepper("Courts: \(courtCount)", value: $courtCount, in: 1...10)
                        }
                    }
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
                    if !sessionType.isTournament {
                        Stepper("Max Participants: \(maxParticipants)", value: $maxParticipants, in: 4...40)
                    }
                }

                Section("Repeat") {
                    Toggle("Repeat this session", isOn: $isRecurring)
                    if isRecurring {
                        Picker("Frequency", selection: $frequency) {
                            Text("Weekly").tag("weekly")
                            Text("Biweekly").tag("biweekly")
                            Text("Monthly").tag("monthly")
                        }
                        Picker("End", selection: $endType) {
                            Text("After occurrences").tag("occurrences")
                            Text("Until date").tag("date")
                        }
                        if endType == "occurrences" {
                            Stepper("Occurrences: \(maxOccurrences)", value: $maxOccurrences, in: 2...52)
                        } else {
                            DatePicker("End Date", selection: $recurringEndDate, displayedComponents: .date)
                        }
                    }
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
            .onChange(of: sessionType) {
                if tournamentName.isEmpty {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "MMM d"
                    tournamentName = "\(sessionType.displayName) - \(formatter.string(from: date))"
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
            var tournamentId: UUID? = nil

            // Create tournament first if needed
            if sessionType.isTournament {
                guard let userId = authService.user?.id else { return }
                let formatString: String
                switch sessionType {
                case .roundRobin: formatString = "round_robin"
                case .singleElimination: formatString = "elimination"
                case .doubleElimination: formatString = "double_elimination"
                case .kingOfTheCourt: formatString = "king_of_the_court"
                default: formatString = "round_robin"
                }

                let tournament = try await TournamentRepository().createTournament(
                    clubId: clubId,
                    name: tournamentName.isEmpty ? "\(sessionType.displayName) - \(dateString)" : tournamentName,
                    description: nil,
                    format: formatString,
                    maxTeams: hasMaxTeams ? maxTeams : nil,
                    teamSize: teamSize,
                    startDate: dateString,
                    endDate: nil,
                    createdBy: userId
                )
                tournamentId = tournament.id
            }

            let effectiveMaxParticipants = sessionType.isTournament ? (hasMaxTeams ? maxTeams * teamSize : 64) : maxParticipants

            if isRecurring && !sessionType.isTournament {
                let dayOfWeek = Calendar.current.component(.weekday, from: date)
                let endDateString: String? = endType == "date" ? formatter.string(from: recurringEndDate) : nil
                let occurrences: Int? = endType == "occurrences" ? maxOccurrences : nil

                let config = RecurringConfig(
                    frequency: frequency,
                    dayOfWeek: dayOfWeek,
                    endDate: endDateString,
                    maxOccurrences: occurrences
                )

                _ = try await SessionRepository().createRecurringSession(
                    clubId: clubId,
                    date: dateString,
                    venue: venue,
                    feePerPlayer: feePerPlayer,
                    maxParticipants: effectiveMaxParticipants,
                    startTime: startTime,
                    endTime: endTime,
                    sessionType: sessionType.rawValue,
                    recurringConfig: config
                )
            } else {
                _ = try await SessionRepository().createSession(
                    clubId: clubId,
                    date: dateString,
                    venue: venue,
                    feePerPlayer: feePerPlayer,
                    maxParticipants: effectiveMaxParticipants,
                    startTime: startTime,
                    endTime: endTime,
                    sessionType: sessionType.rawValue,
                    tournamentId: tournamentId
                )
            }
            await onSaved()
            toastManager.show("Session created", type: .success)
            dismiss()
        } catch {
            toastManager.show("Failed to create session: \(error.localizedDescription)", type: .error)
        }
    }
}
