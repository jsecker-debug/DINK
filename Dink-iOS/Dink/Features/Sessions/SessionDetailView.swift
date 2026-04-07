import SwiftUI

struct SessionDetailView: View {
    let session: ClubSession

    @Environment(\.dismiss) private var dismiss
    @Environment(AuthService.self) private var authService
    @Environment(ClubService.self) private var clubService
    @Environment(ToastManager.self) private var toastManager

    @State private var registrations: [SessionRegistrationWithUser] = []
    @State private var temporaryParticipants: [TemporaryParticipant] = []
    @State private var userRegistration: SessionRegistration?
    @State private var scheduleData: SessionScheduleData?
    @State private var isLoading = false
    @State private var isRegistering = false
    @State private var showEditSheet = false
    @State private var showScheduleGenerator = false
    @State private var showTempParticipantSheet = false
    @State private var showCancelConfirmation = false
    @State private var showAttendanceCheckIn = false
    @State private var showMVPVoting = false
    @State private var gameScores: [GameScore] = []
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if session.resolvedSessionType.isTournament {
                TournamentSessionDetailView(session: session)
            } else if isLoading && registrations.isEmpty {
                LoadingView(message: "Loading session...")
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        sessionHeader
                        actionButtons
                        overviewCard
                        participantsSection
                        courtScheduleSection
                        mvpSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
        }
        .navigationTitle("Session Detail")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete Session?", isPresented: $showCancelConfirmation) {
            Button("Delete Session", role: .destructive) {
                Task { await deleteSession() }
            }
            Button("Keep Session", role: .cancel) { }
        } message: {
            Text("This will permanently delete the session and all associated data (registrations, rotations, scores).")
        }
        .sheet(isPresented: $showEditSheet) {
            EditSessionSheet(session: session) { await loadData() }
        }
        .sheet(isPresented: $showScheduleGenerator) {
            ScheduleGeneratorView(
                sessionId: session.id,
                participants: allParticipantNames
            ) { await loadData() }
        }
        .sheet(isPresented: $showTempParticipantSheet) {
            TemporaryParticipantSheet(sessionId: session.id) { await loadData() }
        }
        .sheet(isPresented: $showAttendanceCheckIn) {
            AttendanceCheckInView(
                sessionId: session.id,
                registrations: registrations.filter { $0.status == "registered" }
            )
        }
        .sheet(isPresented: $showMVPVoting) {
            if let userId = authService.user?.id {
                MVPVotingSheet(
                    sessionId: session.id,
                    participants: registrations,
                    currentUserId: userId
                )
            }
        }
        .refreshable { await loadData() }
        .task { await loadData() }
    }

    // MARK: - Header

    private var sessionHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(session.date ?? "No Date")
                    .font(.title2.bold())
                Spacer()
                if let status = session.status {
                    StatusBadge(status: status)
                }
            }

            HStack(spacing: 16) {
                if let venue = session.venue {
                    Label(venue, systemImage: "mappin")
                }
                if let fee = session.feePerPlayer, fee > 0 {
                    Label(String(format: "£%.2f", fee), systemImage: "sterlingsign.circle")
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 12) {
            if userRegistration != nil {
                Button(role: .destructive) {
                    Task { await unregister() }
                } label: {
                    Label("Unregister", systemImage: "xmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(isRegistering)

                Button {
                    Task { await addToCalendar() }
                } label: {
                    Label("Calendar", systemImage: "calendar.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.dinkTeal)
            } else {
                Button {
                    Task { await register() }
                } label: {
                    Label("Register", systemImage: "checkmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isRegistering)
            }

            if clubService.isAdmin {
                Menu {
                    Button { showEditSheet = true } label: {
                        Label("Edit Session", systemImage: "pencil")
                    }
                    Button { showScheduleGenerator = true } label: {
                        Label("Generate Schedule", systemImage: "sportscourt.fill")
                    }
                    Button { showAttendanceCheckIn = true } label: {
                        Label("Take Attendance", systemImage: "checklist")
                    }
                    SessionPDFExportButton(
                        session: session,
                        registrations: registrations,
                        temporaryParticipants: temporaryParticipants,
                        scheduleData: scheduleData,
                        gameScores: gameScores
                    )
                    Button(role: .destructive) { showCancelConfirmation = true } label: {
                        Label("Cancel Session", systemImage: "xmark.circle")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                }
            }
        }
    }

    // MARK: - Overview Card

    private var overviewCard: some View {
        VStack(spacing: 0) {
            overviewRow(label: "Date", value: session.date ?? "TBD")
            Divider().padding(.leading, 16)
            overviewRow(label: "Venue", value: session.venue ?? "TBD")
            Divider().padding(.leading, 16)
            overviewRow(label: "Participants", value: "\(registeredCount)/\(session.maxParticipants ?? 0)")
            Divider().padding(.leading, 16)
            overviewRow(label: "Fee", value: String(format: "£%.2f", session.feePerPlayer ?? 0))
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(.rect(cornerRadius: 10))
        .liquidGlassStatic(cornerRadius: 10)
    }

    private func overviewRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.subheadline)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Participants

    private var participantsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Participants")
                    .font(.headline)
                Spacer()
                if clubService.isAdmin {
                    Button { showTempParticipantSheet = true } label: {
                        Label("Add Guest", systemImage: "person.badge.plus")
                            .font(.subheadline)
                    }
                }
            }

            let registered = registrations.filter { $0.status == "registered" }
            let waitlisted = registrations.filter { $0.status == "waitlist" }

            if !registered.isEmpty {
                Text("Registered (\(registered.count))")
                    .font(.subheadline.bold())
                    .foregroundStyle(.secondary)

                ForEach(registered) { reg in
                    participantRow(reg)
                }
            }

            if !waitlisted.isEmpty {
                Text("Waitlist (\(waitlisted.count))")
                    .font(.subheadline.bold())
                    .foregroundStyle(.dinkOrange)
                    .padding(.top, 8)

                ForEach(waitlisted) { reg in
                    participantRow(reg)
                }
            }

            if !temporaryParticipants.isEmpty {
                Text("Guests (\(temporaryParticipants.count))")
                    .font(.subheadline.bold())
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)

                ForEach(temporaryParticipants) { tp in
                    HStack {
                        Circle()
                            .fill(Color(.tertiarySystemBackground))
                            .frame(width: 32, height: 32)
                            .overlay {
                                Text(String(tp.name.prefix(1)).uppercased())
                                    .font(.caption.bold())
                                    .foregroundStyle(.secondary)
                            }
                        Text(tp.name)
                            .font(.subheadline)
                        Spacer()
                        Text(String(format: "%.1f", tp.skillLevel))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
            }

            if registered.isEmpty && waitlisted.isEmpty && temporaryParticipants.isEmpty {
                Text("No participants yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func participantRow(_ reg: SessionRegistrationWithUser) -> some View {
        HStack(spacing: 12) {
            AvatarView(
                firstName: reg.userProfiles?.firstName,
                lastName: reg.userProfiles?.lastName,
                avatarUrl: reg.userProfiles?.avatarUrl,
                size: 32
            )

            Text(reg.userProfiles?.fullName ?? "Unknown")
                .font(.subheadline)

            Spacer()

            if let level = reg.userProfiles?.skillLevel {
                Text(String(format: "%.1f", level))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - Court Schedule

    private var courtScheduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Court Schedule")
                    .font(.headline)
                Spacer()
                if clubService.isAdmin && scheduleData == nil {
                    Button { showScheduleGenerator = true } label: {
                        Label("Generate", systemImage: "sportscourt.fill")
                            .font(.subheadline)
                    }
                }
            }

            if let data = scheduleData, !data.rotations.isEmpty {
                CourtDisplayView(
                    rotations: data.rotations,
                    sessionId: session.id,
                    isAdmin: clubService.isAdmin,
                    onRotationUpdated: { await loadData() }
                )
            } else {
                Text("No schedule generated yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
            }
        }
    }

    // MARK: - MVP Section

    @ViewBuilder
    private var mvpSection: some View {
        if session.status?.lowercased() == "completed" {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Player of the Match")
                        .font(.headline)
                    Spacer()
                    Button { showMVPVoting = true } label: {
                        Label("Vote", systemImage: "trophy.fill")
                            .font(.subheadline)
                    }
                    .tint(.yellow)
                }

                Text("Vote for the standout player from this session.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Computed

    private var registeredCount: Int {
        registrations.filter { $0.status == "registered" }.count
    }

    private var allParticipantNames: [String] {
        let regNames = registrations
            .filter { $0.status == "registered" }
            .map { $0.userProfiles?.fullName ?? "Unknown" }
        let tempNames = temporaryParticipants.map(\.name)
        return regNames + tempNames
    }

    // MARK: - Actions

    private func register() async {
        guard let userId = authService.user?.id else { return }
        isRegistering = true

        // Optimistic: set a placeholder registration so UI flips immediately
        let optimisticReg = SessionRegistration(id: UUID(), sessionId: session.id, userId: userId, status: "registered", registeredAt: Date(), feeAmount: session.feePerPlayer, calendarEventId: nil)
        let previousReg = userRegistration
        userRegistration = optimisticReg

        do {
            let result = try await RegistrationRepository().registerForSession(
                sessionId: session.id,
                userId: userId,
                maxParticipants: session.maxParticipants ?? 20,
                feePerPlayer: session.feePerPlayer ?? 0
            )
            if result.isWaitlist {
                toastManager.show("You're on the waitlist. We'll notify you when a spot opens.", type: .info)
            } else {
                toastManager.show("Registered successfully", type: .success)
            }
            await loadData()
        } catch {
            // Revert optimistic update
            userRegistration = previousReg
            toastManager.show("Registration failed: \(error.localizedDescription)", type: .error)
        }
        isRegistering = false
    }

    private func unregister() async {
        guard let userId = authService.user?.id else { return }
        isRegistering = true

        // Optimistic: clear registration so UI flips immediately
        let previousReg = userRegistration
        userRegistration = nil

        do {
            try await RegistrationRepository().unregisterFromSession(
                sessionId: session.id,
                userId: userId
            )
            toastManager.show("Unregistered from session", type: .success)
            await loadData()
        } catch {
            // Revert optimistic update
            userRegistration = previousReg
            toastManager.show("Failed to unregister: \(error.localizedDescription)", type: .error)
        }
        isRegistering = false
    }

    private func addToCalendar() async {
        guard let registration = userRegistration else { return }
        do {
            let eventId = try await CalendarService.addSessionToCalendar(
                date: session.date ?? "",
                venue: session.venue,
                startTime: session.startTime,
                endTime: session.endTime,
                clubName: clubService.selectedClub?.name
            )
            try await RegistrationRepository().updateCalendarEventId(
                registrationId: registration.id,
                eventId: eventId
            )
            toastManager.show("Added to calendar", type: .success)
        } catch {
            toastManager.show("Calendar error: \(error.localizedDescription)", type: .error)
        }
    }

    private func deleteSession() async {
        do {
            try await SessionRepository().deleteSession(id: session.id)
            toastManager.show("Session deleted", type: .success)
            dismiss()
        } catch {
            toastManager.show("Failed to delete session: \(error.localizedDescription)", type: .error)
        }
    }

    private func loadData() async {
        isLoading = true
        defer { isLoading = false }
        do {
            async let regs = RegistrationRepository().fetchSessionRegistrations(sessionId: session.id)
            async let temps = TemporaryParticipantRepository().fetchTemporaryParticipants(sessionId: session.id)
            async let schedule = RotationRepository().fetchSessionSchedule(sessionId: session.id)
            async let scores = GameScoreRepository().fetchSessionScores(sessionId: session.id)

            registrations = try await regs
            temporaryParticipants = try await temps
            scheduleData = try await schedule
            gameScores = try await scores

            if let userId = authService.user?.id {
                userRegistration = try await RegistrationRepository().fetchUserRegistration(
                    sessionId: session.id,
                    userId: userId
                )
            }
        } catch {
            print("Failed to load session detail: \(error)")
        }
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    let status: String

    var body: some View {
        Text(status.capitalized)
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
            .accessibilityLabel("Status: \(status.capitalized)")
    }

    private var color: Color {
        switch status.lowercased() {
        case "upcoming": return .dinkTeal
        case "completed": return .dinkGreen
        case "cancelled": return .red
        default: return .secondary
        }
    }
}
