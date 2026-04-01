import Foundation
import Observation
import Supabase

@Observable
@MainActor
final class ClubService {
    var selectedClub: Club?
    var userClubs: [Club] = []
    var isLoading = false

    var selectedClubId: UUID? {
        selectedClub?.id
    }

    /// Whether the current user is an admin or owner of the selected club.
    var isAdmin: Bool {
        guard let role = selectedClub?.role?.lowercased() else { return false }
        return role == "admin" || role == "owner"
    }

    // MARK: - Fetch User Clubs

    func fetchUserClubs(userId: String) async throws {
        isLoading = true
        defer { isLoading = false }

        let memberships: [ClubMembershipResponse] = try await supabase
            .from("club_memberships")
            .select("club_id, role, status, clubs(id, name, description, location, status)")
            .eq("user_id", value: userId)
            .eq("status", value: "active")
            .execute()
            .value

        userClubs = memberships.compactMap { membership -> Club? in
            guard let club = membership.clubs, club.status == "active" else { return nil }
            return Club(
                id: club.id,
                name: club.name,
                description: club.description,
                location: club.location,
                status: club.status,
                role: membership.role,
                memberCount: nil,
                createdAt: nil,
                createdBy: nil
            )
        }
        .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

        // Auto-select first club alphabetically if none selected
        if selectedClub == nil, let first = userClubs.first {
            selectedClub = first
        }

        // Clear selection if the selected club is no longer in the list
        if let current = selectedClub, !userClubs.contains(where: { $0.id == current.id }) {
            selectedClub = userClubs.first
        }
    }

    // MARK: - Refresh

    func refreshClubs(userId: String) async {
        try? await fetchUserClubs(userId: userId)
    }

    // MARK: - Selection

    func setSelectedClub(_ club: Club) {
        selectedClub = club
    }

    func setSelectedClubById(_ id: UUID) {
        selectedClub = userClubs.first { $0.id == id }
    }

    // MARK: - Create Club

    /// Creates a new club and adds the current user as its admin.
    func createClub(
        name: String,
        description: String?,
        location: String?,
        userId: String
    ) async throws {
        // Insert the club
        let clubResponse: ClubInsertResponse = try await supabase
            .from("clubs")
            .insert([
                "name": name,
                "description": description ?? "",
                "location": location ?? "",
                "status": "active"
            ])
            .select("id, name, description, location, status")
            .single()
            .execute()
            .value

        // Add user as admin of the new club
        try await supabase
            .from("club_memberships")
            .insert([
                "club_id": clubResponse.id.uuidString,
                "user_id": userId,
                "role": "admin",
                "status": "active"
            ])
            .execute()

        // Refresh the club list and select the new club
        try await fetchUserClubs(userId: userId)
        if let newClub = userClubs.first(where: { $0.id == clubResponse.id }) {
            selectedClub = newClub
        }
    }

    // MARK: - Club Discovery

    /// Searches for active clubs by name. Returns clubs the user is NOT already a member of.
    func searchClubs(query: String) async throws -> [DiscoverableClub] {
        let pattern = "%\(query)%"
        let results: [DiscoverableClub] = try await supabase
            .from("clubs")
            .select("id, name, description, location")
            .eq("status", value: "active")
            .ilike("name", pattern: pattern)
            .limit(20)
            .execute()
            .value

        // Filter out clubs the user is already in
        let memberClubIds = Set(userClubs.map(\.id))
        return results.filter { !memberClubIds.contains($0.id) }
    }

    /// Fetches all active clubs (for browsing when no search query).
    func fetchDiscoverableClubs() async throws -> [DiscoverableClub] {
        let results: [DiscoverableClub] = try await supabase
            .from("clubs")
            .select("id, name, description, location")
            .eq("status", value: "active")
            .order("name")
            .limit(50)
            .execute()
            .value

        let memberClubIds = Set(userClubs.map(\.id))
        return results.filter { !memberClubIds.contains($0.id) }
    }

    // MARK: - Join Requests

    /// Sends a request to join a club.
    func requestToJoinClub(clubId: UUID, userId: UUID, message: String?) async throws {
        try await supabase
            .from("club_join_requests")
            .insert([
                "club_id": clubId.uuidString,
                "user_id": userId.uuidString,
                "message": message ?? "",
                "status": "pending"
            ])
            .execute()
    }

    /// Fetches the current user's pending join requests.
    func fetchPendingJoinRequests(userId: UUID) async throws -> [JoinRequest] {
        try await supabase
            .from("club_join_requests")
            .select("id, club_id, status, created_at, clubs(name)")
            .eq("user_id", value: userId.uuidString)
            .eq("status", value: "pending")
            .execute()
            .value
    }

    // MARK: - Clear State (for logout)

    func clearState() {
        userClubs = []
        selectedClub = nil
        isLoading = false
    }
}

// MARK: - Discoverable Club

struct DiscoverableClub: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String?
    let location: String?
}

// MARK: - Join Request

struct JoinRequest: Identifiable, Codable {
    let id: UUID
    let clubId: UUID
    let status: String
    let createdAt: Date?
    let clubs: JoinRequestClub?

    enum CodingKeys: String, CodingKey {
        case id
        case clubId = "club_id"
        case status
        case createdAt = "created_at"
        case clubs
    }
}

struct JoinRequestClub: Codable {
    let name: String
}

// MARK: - Response types for Supabase joins

private struct ClubMembershipResponse: Codable {
    let clubId: UUID
    let role: String
    let status: String
    let clubs: ClubResponse?

    enum CodingKeys: String, CodingKey {
        case clubId = "club_id"
        case role
        case status
        case clubs
    }
}

private struct ClubResponse: Codable {
    let id: UUID
    let name: String
    let description: String?
    let location: String?
    let status: String?
}

private struct ClubInsertResponse: Codable {
    let id: UUID
    let name: String
    let description: String?
    let location: String?
    let status: String?
}
