import Foundation
import Supabase

struct AttendanceRepository {

    func markAttendance(sessionId: Int, userId: UUID, attended: Bool) async throws {
        let status = attended ? "attended" : "no_show"
        try await supabase.from("session_registrations")
            .update(["status": status])
            .eq("session_id", value: sessionId)
            .eq("user_id", value: userId.uuidString)
            .execute()
    }

    func bulkMarkAttendance(sessionId: Int, attendedUserIds: [UUID], noShowUserIds: [UUID]) async throws {
        for userId in attendedUserIds {
            try await markAttendance(sessionId: sessionId, userId: userId, attended: true)
        }
        for userId in noShowUserIds {
            try await markAttendance(sessionId: sessionId, userId: userId, attended: false)
        }
    }

    func fetchAttendanceStats(userId: UUID, clubId: UUID) async throws -> AttendanceStats {
        let result: [AttendanceStats] = try await supabase
            .rpc("get_member_attendance_stats", params: ["p_user_id": userId.uuidString, "p_club_id": clubId.uuidString])
            .execute()
            .value
        return result.first ?? AttendanceStats(totalSessions: 0, attendedSessions: 0, attendanceRate: 0)
    }
}
