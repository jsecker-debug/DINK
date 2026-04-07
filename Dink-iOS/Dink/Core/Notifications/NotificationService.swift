import Foundation
import Observation
import UserNotifications
import UIKit

@Observable
@MainActor
final class NotificationService {
    var unreadCount: Int = 0
    var notifications: [AppNotification] = []
    var hasPermission: Bool = false

    private let deviceTokenRepo = DeviceTokenRepository()
    private let notificationRepo = NotificationRepository()

    // MARK: - Permission

    func requestPermission() {
        Task {
            do {
                let granted = try await UNUserNotificationCenter.current()
                    .requestAuthorization(options: [.alert, .sound, .badge])
                hasPermission = granted
            } catch {
                print("[NotificationService] Permission request failed: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Register for Remote Notifications

    func registerForRemoteNotifications() {
        UIApplication.shared.registerForRemoteNotifications()
    }

    // MARK: - Handle Device Token

    func handleDeviceToken(_ tokenData: Data) {
        let token = tokenData.map { String(format: "%02x", $0) }.joined()

        Task {
            do {
                let session = try await supabase.auth.session
                try await deviceTokenRepo.upsertToken(userId: session.user.id, token: token)
            } catch {
                print("[NotificationService] Failed to register device token: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Fetch Notifications

    func fetchNotifications(userId: UUID) async {
        do {
            notifications = try await notificationRepo.fetchNotifications(userId: userId)
        } catch {
            print("[NotificationService] Failed to fetch notifications: \(error.localizedDescription)")
        }
    }

    // MARK: - Refresh Unread Count

    func refreshUnreadCount(userId: UUID) async {
        do {
            unreadCount = try await notificationRepo.fetchUnreadCount(userId: userId)
        } catch {
            print("[NotificationService] Failed to fetch unread count: \(error.localizedDescription)")
        }
    }

    // MARK: - Mark As Read

    func markAsRead(_ notificationId: UUID) async {
        do {
            try await notificationRepo.markAsRead(notificationId: notificationId)
            if unreadCount > 0 {
                unreadCount -= 1
            }
        } catch {
            print("[NotificationService] Failed to mark notification as read: \(error.localizedDescription)")
        }
    }

    // MARK: - Mark All As Read

    func markAllAsRead(userId: UUID) async {
        do {
            try await notificationRepo.markAllAsRead(userId: userId)
            unreadCount = 0
        } catch {
            print("[NotificationService] Failed to mark all notifications as read: \(error.localizedDescription)")
        }
    }

    // MARK: - Local Session Reminders

    func scheduleSessionReminder(for session: ClubSession, clubName: String?) {
        guard let dateStr = session.date, let startTime = session.startTime else { return }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        guard let sessionDate = dateFormatter.date(from: dateStr) else { return }

        // Combine date with start time
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: startTime)
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: sessionDate)
        dateComponents.hour = timeComponents.hour
        dateComponents.minute = timeComponents.minute
        guard let sessionDateTime = calendar.date(from: dateComponents) else { return }

        // Schedule 48 hours before
        let reminderDate = sessionDateTime.addingTimeInterval(-48 * 3600)
        guard reminderDate > Date() else { return } // Don't schedule past reminders

        let content = UNMutableNotificationContent()
        content.title = "Session Reminder"
        content.body = "Pickleball session at \(session.venue ?? "TBD") in 2 days. Don't forget to register!"
        content.sound = .default

        let triggerComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)

        let request = UNNotificationRequest(identifier: "session-reminder-\(session.id)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func cancelSessionReminder(for sessionId: Int) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["session-reminder-\(sessionId)"])
    }
}
