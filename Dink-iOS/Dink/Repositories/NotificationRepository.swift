import Foundation
import Supabase

struct NotificationRepository {

    // MARK: - Fetch Notifications

    func fetchNotifications(userId: UUID, limit: Int = 50) async throws -> [AppNotification] {
        let result: [AppNotification] = try await supabase
            .from("notifications")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
        return result
    }

    // MARK: - Fetch Unread Count

    func fetchUnreadCount(userId: UUID) async throws -> Int {
        let count = try await supabase
            .from("notifications")
            .select("*", head: true, count: .exact)
            .eq("user_id", value: userId.uuidString)
            .eq("read", value: false)
            .execute()
            .count ?? 0
        return count
    }

    // MARK: - Mark As Read

    func markAsRead(notificationId: UUID) async throws {
        try await supabase
            .from("notifications")
            .update(["read": true])
            .eq("id", value: notificationId.uuidString)
            .execute()
    }

    // MARK: - Insert Notification

    func insertNotification(userId: UUID, title: String, body: String, type: String, data: NotificationData?) async throws {
        struct NotificationInsert: Encodable {
            let userId: String
            let title: String
            let body: String
            let type: String
            let data: NotificationData?
            let read: Bool

            enum CodingKeys: String, CodingKey {
                case userId = "user_id"
                case title, body, type, data, read
            }
        }

        try await supabase.from("notifications")
            .insert(NotificationInsert(userId: userId.uuidString, title: title, body: body, type: type, data: data, read: false))
            .execute()
    }

    // MARK: - Mark All As Read

    func markAllAsRead(userId: UUID) async throws {
        try await supabase
            .from("notifications")
            .update(["read": true])
            .eq("user_id", value: userId.uuidString)
            .eq("read", value: false)
            .execute()
    }
}
