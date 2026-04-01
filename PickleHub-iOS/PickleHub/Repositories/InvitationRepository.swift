import Foundation
import Supabase

// MARK: - Internal Codable Helpers

private struct InvitationInsert: Codable {
    let clubId: UUID
    let email: String
    let token: String
    let status: String
    let invitedBy: UUID
    let personalMessage: String?
    let expiresAt: Date?

    enum CodingKeys: String, CodingKey {
        case clubId = "club_id"
        case email
        case token
        case status
        case invitedBy = "invited_by"
        case personalMessage = "personal_message"
        case expiresAt = "expires_at"
    }
}

private struct InvitationStatusUpdate: Codable {
    let status: String
}

// MARK: - Repository

struct InvitationRepository {

    // MARK: - Fetch Invitations

    func fetchInvitations(clubId: UUID) async throws -> [ClubInvitation] {
        let invitations: [ClubInvitation] = try await supabase
            .from("club_invitations")
            .select()
            .eq("club_id", value: clubId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value
        return invitations
    }

    // MARK: - Create Invitation

    func createInvitation(
        clubId: UUID,
        email: String,
        invitedBy: UUID,
        personalMessage: String? = nil,
        expiresAt: Date? = nil
    ) async throws -> ClubInvitation {
        let payload = InvitationInsert(
            clubId: clubId,
            email: email,
            token: UUID().uuidString,
            status: "pending",
            invitedBy: invitedBy,
            personalMessage: personalMessage,
            expiresAt: expiresAt
        )

        let invitation: ClubInvitation = try await supabase
            .from("club_invitations")
            .insert(payload)
            .select()
            .single()
            .execute()
            .value
        return invitation
    }

    // MARK: - Fetch Invitation By Token

    func fetchInvitationByToken(token: String) async throws -> ClubInvitation? {
        let invitation: ClubInvitation? = try? await supabase
            .from("club_invitations")
            .select()
            .eq("token", value: token)
            .single()
            .execute()
            .value
        return invitation
    }

    // MARK: - Update Invitation Status

    func updateInvitationStatus(id: UUID, status: String) async throws {
        let update = InvitationStatusUpdate(status: status)
        try await supabase
            .from("club_invitations")
            .update(update)
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - Delete Invitation

    func deleteInvitation(id: UUID) async throws {
        try await supabase
            .from("club_invitations")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
}
