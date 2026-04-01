import Foundation
import Supabase

// MARK: - Public Types

struct GameScore: Identifiable, Codable, Hashable {
    let id: UUID?
    let sessionId: Int
    let courtNumber: Int
    let rotationNumber: Int
    let team1Players: [String]
    let team2Players: [String]
    let gameNumber: Int
    let team1Score: Int
    let team2Score: Int
    let createdAt: Date?
    let createdBy: UUID?

    enum CodingKeys: String, CodingKey {
        case id
        case sessionId = "session_id"
        case courtNumber = "court_number"
        case rotationNumber = "rotation_number"
        case team1Players = "team1_players"
        case team2Players = "team2_players"
        case gameNumber = "game_number"
        case team1Score = "team1_score"
        case team2Score = "team2_score"
        case createdAt = "created_at"
        case createdBy = "created_by"
    }
}

// MARK: - Repository

struct GameScoreRepository {

    // MARK: - Fetch

    func fetchSessionScores(sessionId: Int) async throws -> [GameScore] {
        let response: [GameScore] = try await supabase
            .from("game_scores")
            .select()
            .eq("session_id", value: sessionId)
            .order("court_number", ascending: true)
            .order("rotation_number", ascending: true)
            .order("game_number", ascending: true)
            .execute()
            .value
        return response
    }

    func fetchCourtScores(
        sessionId: Int,
        courtNumber: Int,
        rotationNumber: Int
    ) async throws -> [GameScore] {
        let response: [GameScore] = try await supabase
            .from("game_scores")
            .select()
            .eq("session_id", value: sessionId)
            .eq("court_number", value: courtNumber)
            .eq("rotation_number", value: rotationNumber)
            .order("game_number", ascending: true)
            .execute()
            .value
        return response
    }

    // MARK: - Save

    func saveGameScores(
        sessionId: Int,
        courtNumber: Int,
        rotationNumber: Int,
        team1Players: [String],
        team2Players: [String],
        scores: [(gameNumber: Int, team1Score: Int, team2Score: Int)],
        createdBy: UUID
    ) async throws -> [GameScore] {
        // Delete existing scores for this court/rotation
        try await supabase
            .from("game_scores")
            .delete()
            .eq("session_id", value: sessionId)
            .eq("court_number", value: courtNumber)
            .eq("rotation_number", value: rotationNumber)
            .execute()

        // Insert new scores
        let insertPayloads = scores.map { score in
            GameScoreInsert(
                sessionId: sessionId,
                courtNumber: courtNumber,
                rotationNumber: rotationNumber,
                team1Players: team1Players,
                team2Players: team2Players,
                gameNumber: score.gameNumber,
                team1Score: score.team1Score,
                team2Score: score.team2Score,
                createdBy: createdBy
            )
        }

        let savedScores: [GameScore] = try await supabase
            .from("game_scores")
            .insert(insertPayloads)
            .select()
            .execute()
            .value

        // Call RPC to update game ratings
        let ratingParams = RatingUpdateParams(
            pSessionId: sessionId,
            pCourtNumber: courtNumber,
            pRotationNumber: rotationNumber,
            pTeam1Players: team1Players,
            pTeam2Players: team2Players,
            pTeam1Scores: scores.map { $0.team1Score },
            pTeam2Scores: scores.map { $0.team2Score }
        )

        try await supabase
            .rpc("update_game_ratings", params: ratingParams)
            .execute()

        return savedScores
    }

    // MARK: - Rating Updates

    func triggerSessionRatingUpdates(sessionId: Int) async throws {
        try await supabase
            .rpc("update_session_ratings", params: SessionRatingParams(sessionId: sessionId))
            .execute()
    }

    // MARK: - Private Types

    private struct GameScoreInsert: Codable {
        let sessionId: Int
        let courtNumber: Int
        let rotationNumber: Int
        let team1Players: [String]
        let team2Players: [String]
        let gameNumber: Int
        let team1Score: Int
        let team2Score: Int
        let createdBy: UUID

        enum CodingKeys: String, CodingKey {
            case sessionId = "session_id"
            case courtNumber = "court_number"
            case rotationNumber = "rotation_number"
            case team1Players = "team1_players"
            case team2Players = "team2_players"
            case gameNumber = "game_number"
            case team1Score = "team1_score"
            case team2Score = "team2_score"
            case createdBy = "created_by"
        }
    }

    private struct RatingUpdateParams: Codable {
        let pSessionId: Int
        let pCourtNumber: Int
        let pRotationNumber: Int
        let pTeam1Players: [String]
        let pTeam2Players: [String]
        let pTeam1Scores: [Int]
        let pTeam2Scores: [Int]

        enum CodingKeys: String, CodingKey {
            case pSessionId = "p_session_id"
            case pCourtNumber = "p_court_number"
            case pRotationNumber = "p_rotation_number"
            case pTeam1Players = "p_team1_players"
            case pTeam2Players = "p_team2_players"
            case pTeam1Scores = "p_team1_scores"
            case pTeam2Scores = "p_team2_scores"
        }
    }

    private struct SessionRatingParams: Codable {
        let sessionId: Int

        enum CodingKeys: String, CodingKey {
            case sessionId = "session_id"
        }
    }
}
