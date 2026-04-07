import Foundation

struct UserProfile: Identifiable, Codable, Hashable {
    let id: UUID
    let firstName: String?
    let lastName: String?
    let email: String?
    let phone: String?
    let skillLevel: Double?
    let gender: String?
    let avatarUrl: String?
    let totalGamesPlayed: Int?
    let wins: Int?
    let losses: Int?
    let mvpCount: Int?
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case lastName = "last_name"
        case email
        case phone
        case skillLevel = "skill_level"
        case gender
        case avatarUrl = "avatar_url"
        case totalGamesPlayed = "total_games_played"
        case wins
        case losses
        case mvpCount = "mvp_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var fullName: String {
        let name = [firstName, lastName]
            .compactMap { $0?.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        return name.isEmpty ? (email ?? "Unknown") : name
    }

    var initials: String {
        let first = firstName?.first.map(String.init) ?? ""
        let last = lastName?.first.map(String.init) ?? ""
        let result = (first + last).uppercased()
        if !result.isEmpty { return result }
        // Fallback to first character of email
        if let emailChar = email?.first { return String(emailChar).uppercased() }
        return "?"
    }
}
