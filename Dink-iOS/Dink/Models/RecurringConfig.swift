import Foundation

struct RecurringConfig: Codable, Hashable {
    let frequency: String?
    let dayOfWeek: Int?
    let endDate: String?
    let maxOccurrences: Int?

    enum CodingKeys: String, CodingKey {
        case frequency
        case dayOfWeek = "day_of_week"
        case endDate = "end_date"
        case maxOccurrences = "max_occurrences"
    }
}
