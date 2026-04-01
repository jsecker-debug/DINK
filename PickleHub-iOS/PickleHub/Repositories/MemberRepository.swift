import Foundation
import Supabase

// MARK: - View Models

struct ClubMemberWithProfile: Identifiable {
    let id: UUID
    let userId: UUID
    let role: String
    let status: String
    let joinedAt: Date?
    let fullName: String
    let phone: String?
    let skillLevel: Double?
    let gender: String?
    let totalGamesPlayed: Int
    let wins: Int
    let losses: Int
    let avatarUrl: String?
}

struct ParticipantWithProfile: Identifiable {
    let id: UUID
    let name: String
    let phone: String?
    let skillLevel: Double?
    let gender: String?
    let totalGamesPlayed: Int
    let wins: Int
    let losses: Int
    let ratingConfidence: Double
    let ratingVolatility: Double
    let avatarUrl: String?
}

// MARK: - Internal Codable Helpers

/// Profile fields returned for member queries.
private struct MemberProfileRow: Codable {
    let id: UUID
    let firstName: String?
    let lastName: String?
    let phone: String?
    let skillLevel: Double?
    let gender: String?
    let totalGamesPlayed: Int?
    let wins: Int?
    let losses: Int?
    let avatarUrl: String?

    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case lastName = "last_name"
        case phone
        case skillLevel = "skill_level"
        case gender
        case totalGamesPlayed = "total_games_played"
        case wins
        case losses
        case avatarUrl = "avatar_url"
    }
}

/// Profile fields returned for participant queries (includes rating fields).
private struct ParticipantProfileRow: Codable {
    let id: UUID
    let firstName: String?
    let lastName: String?
    let phone: String?
    let skillLevel: Double?
    let gender: String?
    let totalGamesPlayed: Int?
    let wins: Int?
    let losses: Int?
    let ratingConfidence: Double?
    let ratingVolatility: Double?
    let avatarUrl: String?

    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case lastName = "last_name"
        case phone
        case skillLevel = "skill_level"
        case gender
        case totalGamesPlayed = "total_games_played"
        case wins
        case losses
        case ratingConfidence = "rating_confidence"
        case ratingVolatility = "rating_volatility"
        case avatarUrl = "avatar_url"
    }
}

// MARK: - Repository

struct MemberRepository {

    // MARK: - Fetch Club Members

    func fetchClubMembers(clubId: UUID) async throws -> [ClubMemberWithProfile] {
        // Step 1: Fetch active memberships
        let memberships: [ClubMembership] = try await supabase
            .from("club_memberships")
            .select("id, user_id, role, status, joined_at")
            .eq("club_id", value: clubId.uuidString)
            .eq("status", value: "active")
            .execute()
            .value

        guard !memberships.isEmpty else { return [] }

        let userIds = memberships.map { $0.userId.uuidString }

        // Step 2: Fetch profiles for those users
        let profiles: [MemberProfileRow] = try await supabase
            .from("user_profiles")
            .select("id, first_name, last_name, phone, skill_level, gender, total_games_played, wins, losses, avatar_url")
            .in("id", values: userIds)
            .execute()
            .value

        let profileMap = Dictionary(uniqueKeysWithValues: profiles.map { ($0.id, $0) })

        // Step 3: Combine
        return memberships.compactMap { membership in
            guard let profile = profileMap[membership.userId] else { return nil }
            let fullName = [profile.firstName, profile.lastName]
                .compactMap { $0 }
                .joined(separator: " ")
            return ClubMemberWithProfile(
                id: membership.id,
                userId: membership.userId,
                role: membership.role,
                status: membership.status,
                joinedAt: membership.joinedAt,
                fullName: fullName,
                phone: profile.phone,
                skillLevel: profile.skillLevel,
                gender: profile.gender,
                totalGamesPlayed: profile.totalGamesPlayed ?? 0,
                wins: profile.wins ?? 0,
                losses: profile.losses ?? 0,
                avatarUrl: profile.avatarUrl
            )
        }
    }

    // MARK: - Fetch Participants

    func fetchParticipants(clubId: UUID) async throws -> [ParticipantWithProfile] {
        // Step 1: Fetch active membership user IDs
        let memberships: [ClubMembership] = try await supabase
            .from("club_memberships")
            .select("id, user_id, role, status, joined_at")
            .eq("club_id", value: clubId.uuidString)
            .eq("status", value: "active")
            .execute()
            .value

        guard !memberships.isEmpty else { return [] }

        let userIds = memberships.map { $0.userId.uuidString }

        // Step 2: Fetch profiles with rating fields
        let profiles: [ParticipantProfileRow] = try await supabase
            .from("user_profiles")
            .select("id, first_name, last_name, phone, skill_level, gender, total_games_played, wins, losses, rating_confidence, rating_volatility, avatar_url")
            .in("id", values: userIds)
            .execute()
            .value

        // Step 3: Transform and sort by name
        return profiles
            .map { profile in
                let name = [profile.firstName, profile.lastName]
                    .compactMap { $0 }
                    .joined(separator: " ")
                return ParticipantWithProfile(
                    id: profile.id,
                    name: name,
                    phone: profile.phone,
                    skillLevel: profile.skillLevel,
                    gender: profile.gender,
                    totalGamesPlayed: profile.totalGamesPlayed ?? 0,
                    wins: profile.wins ?? 0,
                    losses: profile.losses ?? 0,
                    ratingConfidence: profile.ratingConfidence ?? 0,
                    ratingVolatility: profile.ratingVolatility ?? 0,
                    avatarUrl: profile.avatarUrl
                )
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}
