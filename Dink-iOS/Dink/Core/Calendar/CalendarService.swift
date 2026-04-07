import EventKit
import Foundation

enum CalendarService {
    private nonisolated(unsafe) static let store = EKEventStore()

    static func requestAccess() async -> Bool {
        if #available(iOS 17.0, *) {
            return (try? await store.requestFullAccessToEvents()) ?? false
        } else {
            return (try? await store.requestAccess(to: .event)) ?? false
        }
    }

    static func removeSessionFromCalendar(eventIdentifier: String) throws {
        guard let event = store.event(withIdentifier: eventIdentifier) else { return }
        try store.remove(event, span: .thisEvent)
    }

    static func addSessionToCalendar(
        date: String,
        venue: String?,
        startTime: Date?,
        endTime: Date?,
        clubName: String?
    ) async throws -> String {
        let granted = await requestAccess()
        guard granted else {
            throw CalendarError.accessDenied
        }

        let event = EKEvent(eventStore: store)
        event.title = "Pickleball - \(clubName ?? "Session")"
        event.location = venue
        event.calendar = store.defaultCalendarForNewEvents

        // Parse date and combine with times
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        if let parsedDate = dateFormatter.date(from: date) {
            if let start = startTime {
                // Combine the session date with the start time components
                let calendar = Calendar.current
                let timeComponents = calendar.dateComponents([.hour, .minute], from: start)
                var dateComponents = calendar.dateComponents([.year, .month, .day], from: parsedDate)
                dateComponents.hour = timeComponents.hour
                dateComponents.minute = timeComponents.minute
                event.startDate = calendar.date(from: dateComponents) ?? parsedDate
            } else {
                event.startDate = parsedDate
            }

            if let end = endTime {
                let calendar = Calendar.current
                let timeComponents = calendar.dateComponents([.hour, .minute], from: end)
                var dateComponents = calendar.dateComponents([.year, .month, .day], from: parsedDate)
                dateComponents.hour = timeComponents.hour
                dateComponents.minute = timeComponents.minute
                event.endDate = calendar.date(from: dateComponents) ?? parsedDate.addingTimeInterval(7200)
            } else {
                event.endDate = event.startDate.addingTimeInterval(7200) // 2 hours default
            }
        }

        event.notes = "Pickleball session at \(venue ?? "TBD")"

        try store.save(event, span: .thisEvent)
        return event.eventIdentifier
    }

    enum CalendarError: LocalizedError {
        case accessDenied

        var errorDescription: String? {
            switch self {
            case .accessDenied:
                return "Calendar access was denied. Please enable it in Settings."
            }
        }
    }
}
