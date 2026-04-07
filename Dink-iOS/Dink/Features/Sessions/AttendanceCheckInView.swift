import SwiftUI

struct AttendanceCheckInView: View {
    let sessionId: Int
    let registrations: [SessionRegistrationWithUser]

    @Environment(\.dismiss) private var dismiss
    @Environment(ToastManager.self) private var toastManager

    @State private var attendanceMap: [UUID: Bool] = [:]
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        markAllPresent()
                    } label: {
                        Label("Mark All Present", systemImage: "checkmark.circle.fill")
                    }
                }

                Section("Participants") {
                    ForEach(registrations) { reg in
                        participantRow(reg)
                    }
                }
            }
            .navigationTitle("Take Attendance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await saveAttendance() }
                    }
                    .disabled(isSaving)
                }
            }
            .onAppear {
                // Default all participants to attended
                for reg in registrations {
                    attendanceMap[reg.userId] = true
                }
            }
        }
    }

    // MARK: - Participant Row

    private func participantRow(_ reg: SessionRegistrationWithUser) -> some View {
        let attended = attendanceMap[reg.userId] ?? true

        return Button {
            attendanceMap[reg.userId] = !attended
        } label: {
            HStack(spacing: 12) {
                AvatarView(
                    firstName: reg.userProfiles?.firstName,
                    lastName: reg.userProfiles?.lastName,
                    avatarUrl: reg.userProfiles?.avatarUrl,
                    size: 36
                )

                Text(reg.userProfiles?.fullName ?? "Unknown")
                    .font(.body)
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: attended ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(attended ? .green : .red)
            }
        }
    }

    // MARK: - Actions

    private func markAllPresent() {
        for reg in registrations {
            attendanceMap[reg.userId] = true
        }
    }

    private func saveAttendance() async {
        isSaving = true
        defer { isSaving = false }

        var attendedIds: [UUID] = []
        var noShowIds: [UUID] = []

        for reg in registrations {
            if attendanceMap[reg.userId] == true {
                attendedIds.append(reg.userId)
            } else {
                noShowIds.append(reg.userId)
            }
        }

        do {
            try await AttendanceRepository().bulkMarkAttendance(
                sessionId: sessionId,
                attendedUserIds: attendedIds,
                noShowUserIds: noShowIds
            )
            toastManager.show("Attendance saved", type: .success)
            dismiss()
        } catch {
            toastManager.show("Failed to save attendance: \(error.localizedDescription)", type: .error)
        }
    }
}
