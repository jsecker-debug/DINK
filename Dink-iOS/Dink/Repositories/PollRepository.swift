import Foundation
import Supabase

struct PollRepository {

    // MARK: - Insert Payloads

    private struct PollInsertPayload: Codable {
        let clubId: UUID
        let question: String
        let type: String
        let createdBy: UUID
        let expiresAt: Date?
        let allowMultiple: Bool
        let status: String

        enum CodingKeys: String, CodingKey {
            case question, type, status
            case clubId = "club_id"
            case createdBy = "created_by"
            case expiresAt = "expires_at"
            case allowMultiple = "allow_multiple"
        }
    }

    private struct PollOptionInsertPayload: Codable {
        let pollId: UUID
        let text: String
        let sortOrder: Int

        enum CodingKeys: String, CodingKey {
            case text
            case pollId = "poll_id"
            case sortOrder = "sort_order"
        }
    }

    private struct PollVoteInsertPayload: Codable {
        let pollId: UUID
        let optionId: UUID
        let userId: UUID

        enum CodingKeys: String, CodingKey {
            case pollId = "poll_id"
            case optionId = "option_id"
            case userId = "user_id"
        }
    }

    private struct PollStatusUpdatePayload: Codable {
        let status: String
    }

    // MARK: - Fetch

    func fetchPolls(clubId: UUID) async throws -> [Poll] {
        let response: [Poll] = try await supabase
            .from("polls")
            .select()
            .eq("club_id", value: clubId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value
        return response
    }

    func fetchPollDetails(pollId: UUID) async throws -> (poll: Poll, options: [PollOption], votes: [PollVote]) {
        async let pollRequest: Poll = supabase
            .from("polls")
            .select()
            .eq("id", value: pollId.uuidString)
            .single()
            .execute()
            .value

        async let optionsRequest: [PollOption] = supabase
            .from("poll_options")
            .select()
            .eq("poll_id", value: pollId.uuidString)
            .order("sort_order", ascending: true)
            .execute()
            .value

        async let votesRequest: [PollVote] = supabase
            .from("poll_votes")
            .select()
            .eq("poll_id", value: pollId.uuidString)
            .execute()
            .value

        let (poll, options, votes) = try await (pollRequest, optionsRequest, votesRequest)
        return (poll, options, votes)
    }

    // MARK: - Create

    func createPoll(
        clubId: UUID,
        question: String,
        type: String,
        options: [String],
        expiresAt: Date?,
        allowMultiple: Bool,
        createdBy: UUID
    ) async throws -> Poll {
        let payload = PollInsertPayload(
            clubId: clubId,
            question: question,
            type: type,
            createdBy: createdBy,
            expiresAt: expiresAt,
            allowMultiple: allowMultiple,
            status: "active"
        )
        let poll: Poll = try await supabase
            .from("polls")
            .insert(payload)
            .select()
            .single()
            .execute()
            .value

        let optionPayloads = options.enumerated().map { index, text in
            PollOptionInsertPayload(pollId: poll.id, text: text, sortOrder: index)
        }
        try await supabase
            .from("poll_options")
            .insert(optionPayloads)
            .execute()

        return poll
    }

    // MARK: - Vote

    func vote(pollId: UUID, optionId: UUID, userId: UUID) async throws {
        let payload = PollVoteInsertPayload(
            pollId: pollId,
            optionId: optionId,
            userId: userId
        )
        try await supabase
            .from("poll_votes")
            .insert(payload)
            .execute()
    }

    func removeVote(pollId: UUID, optionId: UUID, userId: UUID) async throws {
        try await supabase
            .from("poll_votes")
            .delete()
            .eq("poll_id", value: pollId.uuidString)
            .eq("option_id", value: optionId.uuidString)
            .eq("user_id", value: userId.uuidString)
            .execute()
    }

    // MARK: - Close

    func closePoll(pollId: UUID) async throws {
        try await supabase
            .from("polls")
            .update(PollStatusUpdatePayload(status: "closed"))
            .eq("id", value: pollId.uuidString)
            .execute()
    }
}
