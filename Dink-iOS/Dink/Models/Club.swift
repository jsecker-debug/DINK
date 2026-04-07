import Foundation

struct Club: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let description: String?
    let location: [String]?
    let status: String?
    var role: String?
    let memberCount: Int?
    let createdAt: Date?
    let createdBy: UUID?

    /// Returns the location array joined as a display string, or nil if empty.
    var locationDisplay: String? {
        guard let location, !location.isEmpty else { return nil }
        return location.joined(separator: ", ")
    }

    enum CodingKeys: String, CodingKey {
        case id, name, description, location, status, role
        case memberCount = "member_count"
        case createdAt = "created_at"
        case createdBy = "created_by"
    }
}
