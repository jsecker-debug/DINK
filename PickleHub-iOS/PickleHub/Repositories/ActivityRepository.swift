import Foundation
import Supabase

// MARK: - View Models

struct ActivityWithRelatedData: Identifiable {
    let activity: Activity
    let actorProfile: ActorProfile?
    let targetSession: TargetSession?
    let targetMember: TargetMember?

    var id: UUID { activity.id }
}

struct ActorProfile: Codable {
    let firstName: String?
    let lastName: String?
    let avatarUrl: String?

    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName = "last_name"
        case avatarUrl = "avatar_url"
    }
}

struct TargetSession: Codable {
    let date: String?
    let venue: String?
    let status: String?

    enum CodingKeys: String, CodingKey {
        case date = "Date"
        case venue = "Venue"
        case status = "Status"
    }
}

struct TargetMember: Codable {
    let firstName: String?
    let lastName: String?
    let skillLevel: Double?

    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName = "last_name"
        case skillLevel = "skill_level"
    }
}

struct RecentMember: Identifiable {
    let id: UUID
    let userId: UUID
    let joinedAt: Date?
    let firstName: String?
    let lastName: String?
    let skillLevel: Double?
    let avatarUrl: String?
}

// MARK: - Internal Codable Helpers

private struct RecentMemberProfileRow: Codable {
    let id: UUID
    let firstName: String?
    let lastName: String?
    let skillLevel: Double?
    let avatarUrl: String?

    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case lastName = "last_name"
        case skillLevel = "skill_level"
        case avatarUrl = "avatar_url"
    }
}

// MARK: - Repository

struct ActivityRepository {

    // MARK: - Fetch Club Activities

    func fetchClubActivities(clubId: UUID, limit: Int = 20) async throws -> [ActivityWithRelatedData] {
        let activities: [Activity] = try await supabase
            .from("activities")
            .select()
            .eq("club_id", value: clubId.uuidString)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value

        guard !activities.isEmpty else { return [] }

        // Collect unique actor IDs, session target IDs, and participant target IDs
        var actorIds = Set<UUID>()
        var sessionTargetIds = Set<Int>()
        var participantTargetIds = Set<UUID>()

        for activity in activities {
            if let actorId = activity.actorId {
                actorIds.insert(actorId)
            }
            if let targetId = activity.targetId {
                if activity.targetType == "session", let intId = Int(targetId) {
                    sessionTargetIds.insert(intId)
                } else if activity.targetType == "participant", let uuid = UUID(uuidString: targetId) {
                    participantTargetIds.insert(uuid)
                }
            }
        }

        // Fetch related data in parallel
        async let actorProfiles = actorIds.isEmpty ? [:] : fetchActorProfiles(ids: Array(actorIds))
        async let targetSessions = sessionTargetIds.isEmpty ? [:] : fetchTargetSessions(ids: Array(sessionTargetIds))
        async let targetMembers = participantTargetIds.isEmpty ? [:] : fetchTargetMembers(ids: Array(participantTargetIds))

        let actors = try await actorProfiles
        let sessions = try await targetSessions
        let members = try await targetMembers

        // Combine
        return activities.map { activity in
            let actor = activity.actorId.flatMap { actors[$0] }

            var session: TargetSession?
            var member: TargetMember?

            if let targetId = activity.targetId {
                if activity.targetType == "session", let intId = Int(targetId) {
                    session = sessions[intId]
                } else if activity.targetType == "participant", let uuid = UUID(uuidString: targetId) {
                    member = members[uuid]
                }
            }

            return ActivityWithRelatedData(
                activity: activity,
                actorProfile: actor,
                targetSession: session,
                targetMember: member
            )
        }
    }

    // MARK: - Fetch Recent Sessions

    func fetchRecentSessions(clubId: UUID, limit: Int = 10) async throws -> [ClubSession] {
        let sessions: [ClubSession] = try await supabase
            .from("sessions")
            .select()
            .eq("club_id", value: clubId.uuidString)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
        return sessions
    }

    // MARK: - Fetch Recent Members

    func fetchRecentMembers(clubId: UUID, limit: Int = 10) async throws -> [RecentMember] {
        let memberships: [ClubMembership] = try await supabase
            .from("club_memberships")
            .select("id, user_id, role, status, joined_at")
            .eq("club_id", value: clubId.uuidString)
            .eq("status", value: "active")
            .order("joined_at", ascending: false)
            .limit(limit)
            .execute()
            .value

        guard !memberships.isEmpty else { return [] }

        let userIds = memberships.map { $0.userId.uuidString }

        let profiles: [RecentMemberProfileRow] = try await supabase
            .from("user_profiles")
            .select("id, first_name, last_name, skill_level, avatar_url")
            .in("id", values: userIds)
            .execute()
            .value

        let profileMap = Dictionary(uniqueKeysWithValues: profiles.map { ($0.id, $0) })

        return memberships.compactMap { membership in
            let profile = profileMap[membership.userId]
            return RecentMember(
                id: membership.id,
                userId: membership.userId,
                joinedAt: membership.joinedAt,
                firstName: profile?.firstName,
                lastName: profile?.lastName,
                skillLevel: profile?.skillLevel,
                avatarUrl: profile?.avatarUrl
            )
        }
    }

    // MARK: - Private Helpers

    private func fetchActorProfiles(ids: [UUID]) async throws -> [UUID: ActorProfile] {
        let profiles: [ActorProfileRow] = try await supabase
            .from("user_profiles")
            .select("id, first_name, last_name, avatar_url")
            .in("id", values: ids.map { $0.uuidString })
            .execute()
            .value

        return Dictionary(uniqueKeysWithValues: profiles.map { row in
            (row.id, ActorProfile(firstName: row.firstName, lastName: row.lastName, avatarUrl: row.avatarUrl))
        })
    }

    private func fetchTargetSessions(ids: [Int]) async throws -> [Int: TargetSession] {
        let sessions: [TargetSessionRow] = try await supabase
            .from("sessions")
            .select("id, Date, Venue, Status")
            .in("id", values: ids)
            .execute()
            .value

        return Dictionary(uniqueKeysWithValues: sessions.map { row in
            (row.id, TargetSession(date: row.date, venue: row.venue, status: row.status))
        })
    }

    private func fetchTargetMembers(ids: [UUID]) async throws -> [UUID: TargetMember] {
        let members: [TargetMemberRow] = try await supabase
            .from("user_profiles")
            .select("id, first_name, last_name, skill_level")
            .in("id", values: ids.map { $0.uuidString })
            .execute()
            .value

        return Dictionary(uniqueKeysWithValues: members.map { row in
            (row.id, TargetMember(firstName: row.firstName, lastName: row.lastName, skillLevel: row.skillLevel))
        })
    }
}

// MARK: - Private Row Types

private struct ActorProfileRow: Codable {
    let id: UUID
    let firstName: String?
    let lastName: String?
    let avatarUrl: String?

    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case lastName = "last_name"
        case avatarUrl = "avatar_url"
    }
}

private struct TargetSessionRow: Codable {
    let id: Int
    let date: String?
    let venue: String?
    let status: String?

    enum CodingKeys: String, CodingKey {
        case id
        case date = "Date"
        case venue = "Venue"
        case status = "Status"
    }
}

private struct TargetMemberRow: Codable {
    let id: UUID
    let firstName: String?
    let lastName: String?
    let skillLevel: Double?

    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case lastName = "last_name"
        case skillLevel = "skill_level"
    }
}
