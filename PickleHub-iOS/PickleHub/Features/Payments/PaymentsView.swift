import SwiftUI

struct PaymentsView: View {
    @Environment(ClubService.self) private var clubService
    @Environment(AuthService.self) private var authService

    @State private var sessions: [ClubSession] = []
    @State private var selectedSessionId: Int?
    @State private var registrations: [RegistrationWithProfile] = []
    @State private var paymentStatuses: [UUID: Bool] = [:]
    @Environment(ToastManager.self) private var toastManager
    @State private var isLoadingSessions = false
    @State private var isLoadingDetails = false

    private let repository = PaymentRepository()

    var body: some View {
        Group {
            if !clubService.isAdmin {
                adminGate
            } else {
                adminContent
            }
        }
        .navigationTitle("Payments")
        .refreshable { await loadSessions() }
        .task(id: clubService.selectedClubId) {
            sessions = []
            registrations = []
            paymentStatuses = [:]
            selectedSessionId = nil
            await loadSessions()
        }
    }

    // MARK: - Admin Gate

    private var adminGate: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .imageScale(.large)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text("Admin Access Required")
                .font(.title2)
                .fontWeight(.semibold)
            Text("You need admin privileges to access payment tracking.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Admin Content

    private var adminContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                sessionSelector
                if selectedSessionId != nil {
                    if isLoadingDetails {
                        LoadingView(message: "Loading payment details...")
                            .frame(height: 200)
                    } else {
                        summaryCards
                        sessionDetailsCard
                        playerPaymentsList
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }

    // MARK: - Session Selector

    private var sessionSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Select Session")
                .font(.headline)
            if sessions.isEmpty && !isLoadingSessions {
                Text("No sessions with fees found")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Picker("Session", selection: $selectedSessionId) {
                    Text("Choose a session...").tag(nil as Int?)
                    ForEach(sessions) { session in
                        Text(sessionLabel(session))
                            .tag(session.id as Int?)
                    }
                }
                .pickerStyle(.menu)
                .tint(.primary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(.rect(cornerRadius: 10))
        .liquidGlassStatic(cornerRadius: 10)
        .onChange(of: selectedSessionId) { _, newValue in
            if let id = newValue {
                Task { await loadPaymentDetails(sessionId: id) }
            }
        }
    }

    // MARK: - Summary Cards

    private var summaryCards: some View {
        let selectedSession = sessions.first { $0.id == selectedSessionId }
        let fee = selectedSession?.feePerPlayer ?? 0
        let total = fee * Double(registrations.count)
        let paidCount = paymentStatuses.values.filter { $0 }.count
        let collected = fee * Double(paidCount)
        let outstanding = total - collected

        return LiquidGlassContainer(spacing: 12) {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                StatCardView(
                    title: "Total Players",
                    value: "\(registrations.count)",
                    icon: "person.2",
                    iconColor: .blue
                )
                StatCardView(
                    title: "Expected Total",
                    value: String(format: "£%.2f", total),
                    icon: "sterlingsign.circle",
                    iconColor: .purple
                )
                StatCardView(
                    title: "Collected",
                    value: String(format: "£%.2f", collected),
                    icon: "checkmark.circle",
                    iconColor: .green
                )
                StatCardView(
                    title: "Outstanding",
                    value: String(format: "£%.2f", outstanding),
                    icon: "clock",
                    iconColor: .red
                )
            }
        }
    }

    // MARK: - Session Details

    private var sessionDetailsCard: some View {
        let selectedSession = sessions.first { $0.id == selectedSessionId }

        return VStack(spacing: 0) {
            HStack {
                Label("Session Details", systemImage: "calendar")
                    .font(.headline)
                Spacer()
            }
            .padding(16)

            Divider().padding(.leading, 16)

            HStack(spacing: 24) {
                detailColumn(label: "Date", value: selectedSession?.date ?? "-")
                detailColumn(label: "Venue", value: selectedSession?.venue ?? "-")
                detailColumn(label: "Fee", value: String(format: "£%.2f", selectedSession?.feePerPlayer ?? 0))
            }
            .padding(16)
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(.rect(cornerRadius: 10))
        .liquidGlassStatic(cornerRadius: 10)
    }

    private func detailColumn(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Player Payments

    private var playerPaymentsList: some View {
        let selectedSession = sessions.first { $0.id == selectedSessionId }

        return VStack(spacing: 0) {
            HStack {
                Text("Player Payments")
                    .font(.headline)
                Spacer()
            }
            .padding(16)

            Divider().padding(.leading, 16)

            if registrations.isEmpty {
                EmptyStateView(
                    icon: "person.slash",
                    title: "No Players",
                    message: "No registered players found for this session."
                )
                .frame(height: 160)
            } else {
                ForEach(registrations) { registration in
                    paymentRow(registration: registration, fee: selectedSession?.feePerPlayer ?? 0)
                    if registration.id != registrations.last?.id {
                        Divider().padding(.leading, 56)
                    }
                }
            }
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(.rect(cornerRadius: 10))
        .liquidGlassStatic(cornerRadius: 10)
    }

    private func paymentRow(registration: RegistrationWithProfile, fee: Double) -> some View {
        let isPaid = paymentStatuses[registration.id] ?? false
        let profile = registration.userProfiles
        let name = [profile.firstName, profile.lastName]
            .compactMap { $0 }
            .joined(separator: " ")

        return HStack(spacing: 12) {
            Button {
                togglePayment(registrationId: registration.id, paid: !isPaid)
            } label: {
                Image(systemName: isPaid ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isPaid ? .green : .secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isPaid ? "Mark as unpaid" : "Mark as paid")
            .accessibilityHint("Toggle payment status for \(name.isEmpty ? "Unknown" : name)")

            VStack(alignment: .leading, spacing: 2) {
                Text(name.isEmpty ? "Unknown" : name)
                    .font(.body)
                if let email = profile.email {
                    Text(email)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Text(String(format: "£%.2f", registration.feeAmount ?? fee))
                .font(.body)
                .fontWeight(.medium)

            BadgeView(
                text: isPaid ? "Paid" : "Pending",
                style: isPaid ? .success : .warning
            )
            .accessibilityValue(isPaid ? "Paid" : "Pending")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Data Loading

    private func loadSessions() async {
        guard clubService.isAdmin, let clubId = clubService.selectedClubId else { return }
        isLoadingSessions = true
        defer { isLoadingSessions = false }

        do {
            sessions = try await repository.fetchSessionsWithFees(clubId: clubId)
        } catch {
            print("Failed to load sessions: \(error)")
        }
    }

    private func loadPaymentDetails(sessionId: Int) async {
        isLoadingDetails = true
        defer { isLoadingDetails = false }

        do {
            async let regs = repository.fetchRegistrationsForPayment(sessionId: sessionId)
            async let statuses = repository.fetchPaymentStatuses(sessionId: sessionId)

            let (loadedRegs, loadedStatuses) = try await (regs, statuses)
            registrations = loadedRegs

            var statusMap: [UUID: Bool] = [:]
            for reg in loadedRegs {
                let existing = loadedStatuses.first { $0.registrationId == reg.id }
                statusMap[reg.id] = existing?.paid ?? false
            }
            paymentStatuses = statusMap
        } catch {
            print("Failed to load payment details: \(error)")
        }
    }

    private func togglePayment(registrationId: UUID, paid: Bool) {
        guard let sessionId = selectedSessionId else { return }
        // Optimistic update
        paymentStatuses[registrationId] = paid
        Task {
            do {
                try await repository.updatePaymentStatus(
                    sessionId: sessionId,
                    registrationId: registrationId,
                    paid: paid
                )
                toastManager.show(paid ? "Payment recorded" : "Payment unmarked", type: .success)
            } catch {
                // Revert on failure
                paymentStatuses[registrationId] = !paid
                toastManager.show("Failed to update payment: \(error.localizedDescription)", type: .error)
            }
        }
    }

    // MARK: - Helpers

    private func sessionLabel(_ session: ClubSession) -> String {
        let date = session.date ?? "Unknown date"
        let venue = session.venue ?? "Unknown venue"
        let fee = String(format: "£%.2f", session.feePerPlayer ?? 0)
        return "\(date) - \(venue) (\(fee))"
    }
}
