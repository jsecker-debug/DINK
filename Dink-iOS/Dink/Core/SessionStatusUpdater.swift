import Foundation
import Observation
import Supabase
import UIKit

/// Automatically transitions sessions whose date has passed from "Upcoming" to "Completed".
///
/// Mirrors the web app's `useSessionStatusUpdater.ts` behaviour: runs on app-become-active
/// and every hour while foregrounded.
@Observable
@MainActor
final class SessionStatusUpdater {

    private var timer: Timer?
    private var notificationObserver: NSObjectProtocol?

    // MARK: - Lifecycle

    /// Start observing app lifecycle and schedule the hourly timer.
    func start(clubId: UUID) {
        stop()

        // Run immediately
        Task { await updateExpiredSessions(clubId: clubId) }

        // Run every hour
        let hourlyTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                await self.updateExpiredSessions(clubId: clubId)
            }
        }
        timer = hourlyTimer

        // Run when app becomes active
        notificationObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                await self.updateExpiredSessions(clubId: clubId)
            }
        }
    }

    /// Tear down timer and notification observer.
    func stop() {
        timer?.invalidate()
        timer = nil
        if let observer = notificationObserver {
            NotificationCenter.default.removeObserver(observer)
            notificationObserver = nil
        }
    }

    // MARK: - Core Logic

    /// Queries upcoming sessions for the club and marks any whose date has passed as "Completed".
    func updateExpiredSessions(clubId: UUID) async {
        do {
            let sessions: [ClubSession] = try await supabase
                .from("sessions")
                .select()
                .eq("Status", value: "Upcoming")
                .eq("club_id", value: clubId.uuidString)
                .execute()
                .value

            let today = Calendar.current.startOfDay(for: Date())
            let dateFormatter = DateFormatter()
            // Support common date formats from the DB
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")

            let formats = ["yyyy-MM-dd", "MM/dd/yyyy", "dd/MM/yyyy", "yyyy-MM-dd'T'HH:mm:ss"]

            for session in sessions {
                guard let dateString = session.date else { continue }

                var sessionDate: Date?
                for format in formats {
                    dateFormatter.dateFormat = format
                    if let parsed = dateFormatter.date(from: dateString) {
                        sessionDate = parsed
                        break
                    }
                }

                guard let parsedDate = sessionDate else { continue }
                let sessionDay = Calendar.current.startOfDay(for: parsedDate)

                if sessionDay < today {
                    try await supabase
                        .from("sessions")
                        .update(["Status": "Completed"])
                        .eq("id", value: session.id)
                        .execute()
                }
            }
        } catch {
            print("[SessionStatusUpdater] Failed to update expired sessions: \(error)")
        }
    }
}
