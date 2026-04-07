import Foundation

enum ReminderService {
    /// Sends a nudge notification to all club members who haven't registered for a session
    static func nudgeNonRegistered(
        sessionId: Int,
        clubId: UUID,
        venue: String?,
        date: String?,
        registeredUserIds: Set<UUID>
    ) async throws -> Int {
        // 1. Fetch all club members
        let members = try await MemberRepository().fetchClubMembers(clubId: clubId)

        // 2. Filter out already registered (compare against userId, not membership id)
        let unregistered = members.filter { !registeredUserIds.contains($0.userId) }

        // 3. Insert notifications for each
        let notifRepo = NotificationRepository()
        for member in unregistered {
            try? await notifRepo.insertNotification(
                userId: member.userId,
                title: "Session Reminder",
                body: "Don't miss the session at \(venue ?? "TBD") on \(date ?? "TBD"). Register now!",
                type: "admin_nudge",
                data: NotificationData(sessionId: sessionId, clubId: clubId.uuidString)
            )
        }

        return unregistered.count
    }
}
