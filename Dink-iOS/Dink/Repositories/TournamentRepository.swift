import Foundation
import Supabase

struct TournamentRepository {

    // MARK: - Insert / Update Payloads

    private struct TournamentInsertPayload: Codable {
        let clubId: UUID
        let name: String
        let description: String?
        let format: String
        let maxTeams: Int?
        let teamSize: Int
        let startDate: String?
        let endDate: String?
        let createdBy: UUID

        enum CodingKeys: String, CodingKey {
            case clubId = "club_id"
            case name, description, format
            case maxTeams = "max_teams"
            case teamSize = "team_size"
            case startDate = "start_date"
            case endDate = "end_date"
            case createdBy = "created_by"
        }
    }

    private struct StatusUpdatePayload: Codable {
        let status: String
    }

    private struct RegistrationInsertPayload: Codable {
        let tournamentId: UUID
        let userId: UUID
        let teamName: String?
        let partnerId: UUID?

        enum CodingKeys: String, CodingKey {
            case tournamentId = "tournament_id"
            case userId = "user_id"
            case teamName = "team_name"
            case partnerId = "partner_id"
        }
    }

    private struct ScoreUpdatePayload: Codable {
        let scoreA: Int
        let scoreB: Int
        let winnerId: UUID?
        let status: String

        enum CodingKeys: String, CodingKey {
            case scoreA = "score_a"
            case scoreB = "score_b"
            case winnerId = "winner_id"
            case status
        }
    }

    // MARK: - Tournaments

    func fetchTournaments(clubId: UUID) async throws -> [Tournament] {
        try await supabase
            .from("tournaments")
            .select()
            .eq("club_id", value: clubId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    func createTournament(
        clubId: UUID,
        name: String,
        description: String?,
        format: String,
        maxTeams: Int?,
        teamSize: Int,
        startDate: String?,
        endDate: String?,
        createdBy: UUID
    ) async throws -> Tournament {
        let payload = TournamentInsertPayload(
            clubId: clubId,
            name: name,
            description: description,
            format: format,
            maxTeams: maxTeams,
            teamSize: teamSize,
            startDate: startDate,
            endDate: endDate,
            createdBy: createdBy
        )

        return try await supabase
            .from("tournaments")
            .insert(payload)
            .select()
            .single()
            .execute()
            .value
    }

    func updateTournamentStatus(id: UUID, status: String) async throws {
        try await supabase
            .from("tournaments")
            .update(StatusUpdatePayload(status: status))
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - Registrations

    func registerForTournament(
        tournamentId: UUID,
        userId: UUID,
        teamName: String?,
        partnerId: UUID?
    ) async throws -> TournamentRegistration {
        let payload = RegistrationInsertPayload(
            tournamentId: tournamentId,
            userId: userId,
            teamName: teamName,
            partnerId: partnerId
        )

        return try await supabase
            .from("tournament_registrations")
            .insert(payload)
            .select()
            .single()
            .execute()
            .value
    }

    func fetchRegistrations(tournamentId: UUID) async throws -> [TournamentRegistration] {
        try await supabase
            .from("tournament_registrations")
            .select()
            .eq("tournament_id", value: tournamentId.uuidString)
            .execute()
            .value
    }

    // MARK: - Matches

    func fetchMatches(tournamentId: UUID) async throws -> [TournamentMatch] {
        try await supabase
            .from("tournament_matches")
            .select()
            .eq("tournament_id", value: tournamentId.uuidString)
            .order("round")
            .order("match_number")
            .execute()
            .value
    }

    func updateMatchScore(matchId: UUID, scoreA: Int, scoreB: Int, winnerId: UUID?) async throws {
        let payload = ScoreUpdatePayload(
            scoreA: scoreA,
            scoreB: scoreB,
            winnerId: winnerId,
            status: "completed"
        )

        try await supabase
            .from("tournament_matches")
            .update(payload)
            .eq("id", value: matchId.uuidString)
            .execute()
    }

    // MARK: - Standings

    func fetchStandings(tournamentId: UUID) async throws -> [TournamentStanding] {
        try await supabase
            .from("tournament_standings")
            .select()
            .eq("tournament_id", value: tournamentId.uuidString)
            .order("rank")
            .execute()
            .value
    }

    // MARK: - Batch Match Insert

    func insertMatches(_ matches: [TournamentMatch]) async throws {
        struct MatchInsertPayload: Codable {
            let id: UUID
            let tournamentId: UUID
            let round: Int
            let matchNumber: Int
            let teamAId: UUID?
            let teamBId: UUID?
            let scoreA: Int?
            let scoreB: Int?
            let winnerId: UUID?
            let status: String
            let bracketType: String?
            let courtNumber: Int?

            enum CodingKeys: String, CodingKey {
                case id
                case tournamentId = "tournament_id"
                case round
                case matchNumber = "match_number"
                case teamAId = "team_a_id"
                case teamBId = "team_b_id"
                case scoreA = "score_a"
                case scoreB = "score_b"
                case winnerId = "winner_id"
                case status
                case bracketType = "bracket_type"
                case courtNumber = "court_number"
            }
        }

        let payloads = matches.map { match in
            MatchInsertPayload(
                id: match.id,
                tournamentId: match.tournamentId,
                round: match.round,
                matchNumber: match.matchNumber,
                teamAId: match.teamAId,
                teamBId: match.teamBId,
                scoreA: match.scoreA,
                scoreB: match.scoreB,
                winnerId: match.winnerId,
                status: match.status,
                bracketType: match.bracketType,
                courtNumber: match.courtNumber
            )
        }

        try await supabase
            .from("tournament_matches")
            .insert(payloads)
            .execute()
    }

    func updateMatchAdvancement(matchId: UUID, teamAId: UUID?, teamBId: UUID?) async throws {
        struct AdvancementPayload: Codable {
            let teamAId: UUID?
            let teamBId: UUID?

            enum CodingKeys: String, CodingKey {
                case teamAId = "team_a_id"
                case teamBId = "team_b_id"
            }
        }

        try await supabase
            .from("tournament_matches")
            .update(AdvancementPayload(teamAId: teamAId, teamBId: teamBId))
            .eq("id", value: matchId.uuidString)
            .execute()
    }

    // MARK: - King of the Court

    func fetchKingOfCourtState(tournamentId: UUID) async throws -> [KingOfCourtState] {
        try await supabase
            .from("king_of_court_state")
            .select()
            .eq("tournament_id", value: tournamentId.uuidString)
            .order("court_number")
            .execute()
            .value
    }

    func upsertKingOfCourtState(_ states: [KingOfCourtState]) async throws {
        try await supabase
            .from("king_of_court_state")
            .upsert(states)
            .execute()
    }

    func fetchKingOfCourtQueue(tournamentId: UUID) async throws -> [KingOfCourtQueue] {
        try await supabase
            .from("king_of_court_queue")
            .select()
            .eq("tournament_id", value: tournamentId.uuidString)
            .order("queue_position")
            .execute()
            .value
    }

    func replaceKingOfCourtQueue(tournamentId: UUID, queue: [KingOfCourtQueue]) async throws {
        try await supabase
            .from("king_of_court_queue")
            .delete()
            .eq("tournament_id", value: tournamentId.uuidString)
            .execute()

        if !queue.isEmpty {
            try await supabase
                .from("king_of_court_queue")
                .insert(queue)
                .execute()
        }
    }
}
