import Foundation

struct AttendanceStats: Codable {
    let totalSessions: Int
    let attendedSessions: Int
    let attendanceRate: Double

    enum CodingKeys: String, CodingKey {
        case totalSessions = "total_sessions"
        case attendedSessions = "attended_sessions"
        case attendanceRate = "attendance_rate"
    }
}
