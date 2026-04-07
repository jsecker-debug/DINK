import Foundation

extension Date {
    /// "March 2025"
    var monthYear: String {
        formatted(.dateTime.month(.wide).year())
    }

    /// "Mar 15, 2025"
    var mediumDate: String {
        formatted(.dateTime.month(.abbreviated).day().year())
    }

    /// "3:00 PM"
    var shortTime: String {
        formatted(.dateTime.hour().minute())
    }

    /// "Mar 15, 2025 at 3:00 PM"
    var dateTime: String {
        formatted(.dateTime.month(.abbreviated).day().year().hour().minute())
    }

    /// Relative: "2 hours ago", "Yesterday", etc.
    var relativeDescription: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }

    /// Parse ISO8601 string to Date
    static func fromISO8601(_ string: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: string) {
            return date
        }
        // Try without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: string)
    }

    /// Parse session date string like "2025-03-15"
    static func fromSessionDate(_ string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.date(from: string)
    }
}
