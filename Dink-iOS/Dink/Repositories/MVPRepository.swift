import Foundation
import Supabase

struct MVPRepository {

    // MARK: - Insert Payload

    private struct VoteInsertPayload: Encodable {
        let sessionId: Int
        let voterId: String
        let nomineeId: String

        enum CodingKeys: String, CodingKey {
            case sessionId = "session_id"
            case voterId = "voter_id"
            case nomineeId = "nominee_id"
        }
    }

    // MARK: - Cast Vote

    func castVote(sessionId: Int, voterId: UUID, nomineeId: UUID) async throws {
        try await supabase.from("mvp_votes")
            .insert(VoteInsertPayload(
                sessionId: sessionId,
                voterId: voterId.uuidString,
                nomineeId: nomineeId.uuidString
            ))
            .execute()
    }

    // MARK: - Has Voted

    func hasVoted(sessionId: Int, userId: UUID) async throws -> Bool {
        let votes: [MVPVote] = try await supabase.from("mvp_votes")
            .select()
            .eq("session_id", value: sessionId)
            .eq("voter_id", value: userId.uuidString)
            .execute()
            .value
        return !votes.isEmpty
    }

    // MARK: - Fetch Results

    func fetchResults(sessionId: Int) async throws -> [MVPResult] {
        try await supabase.rpc("get_session_mvp", params: ["p_session_id": sessionId])
            .execute()
            .value
    }
}
