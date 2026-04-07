import Foundation
import Supabase

struct SessionRepository {

    // MARK: - Insert / Update Payloads

    private struct SessionInsertPayload: Codable {
        let clubId: UUID
        let date: String
        let venue: String
        let status: String
        let feePerPlayer: Double
        let maxParticipants: Int
        let registrationDeadline: Date?
        let startTime: Date?
        let endTime: Date?
        let sessionType: String
        let tournamentId: UUID?

        enum CodingKeys: String, CodingKey {
            case clubId = "club_id"
            case date = "Date"
            case venue = "Venue"
            case status = "Status"
            case feePerPlayer = "fee_per_player"
            case maxParticipants = "max_participants"
            case registrationDeadline = "registration_deadline"
            case startTime = "start_time"
            case endTime = "end_time"
            case sessionType = "session_type"
            case tournamentId = "tournament_id"
        }
    }

    private struct RecurringSessionInsertPayload: Codable {
        let clubId: UUID
        let date: String
        let venue: String
        let status: String
        let feePerPlayer: Double
        let maxParticipants: Int
        let startTime: Date?
        let endTime: Date?
        let sessionType: String
        let isTemplate: Bool
        let recurringConfig: RecurringConfig

        enum CodingKeys: String, CodingKey {
            case clubId = "club_id"
            case date = "Date"
            case venue = "Venue"
            case status = "Status"
            case feePerPlayer = "fee_per_player"
            case maxParticipants = "max_participants"
            case startTime = "start_time"
            case endTime = "end_time"
            case sessionType = "session_type"
            case isTemplate = "is_template"
            case recurringConfig = "recurring_config"
        }
    }

    private struct SessionUpdatePayload: Codable {
        let date: String?
        let venue: String?
        let feePerPlayer: Double?
        let maxParticipants: Int?
        let registrationDeadline: Date?
        let startTime: Date?
        let endTime: Date?

        enum CodingKeys: String, CodingKey {
            case date = "Date"
            case venue = "Venue"
            case feePerPlayer = "fee_per_player"
            case maxParticipants = "max_participants"
            case registrationDeadline = "registration_deadline"
            case startTime = "start_time"
            case endTime = "end_time"
        }
    }

    // MARK: - Fetch

    func fetchSessions(clubId: UUID) async throws -> [ClubSession] {
        let response: [ClubSession] = try await supabase
            .from("sessions")
            .select()
            .eq("club_id", value: clubId.uuidString)
            .order("Date", ascending: true)
            .execute()
            .value
        return response
    }

    // MARK: - Create

    func createSession(
        clubId: UUID,
        date: String,
        venue: String,
        feePerPlayer: Double,
        maxParticipants: Int,
        registrationDeadline: Date? = nil,
        startTime: Date? = nil,
        endTime: Date? = nil,
        sessionType: String = "open_play",
        tournamentId: UUID? = nil
    ) async throws -> ClubSession {
        let payload = SessionInsertPayload(
            clubId: clubId,
            date: date,
            venue: venue,
            status: "upcoming",
            feePerPlayer: feePerPlayer,
            maxParticipants: maxParticipants,
            registrationDeadline: registrationDeadline,
            startTime: startTime,
            endTime: endTime,
            sessionType: sessionType,
            tournamentId: tournamentId
        )
        let result: ClubSession = try await supabase
            .from("sessions")
            .insert(payload)
            .select()
            .single()
            .execute()
            .value
        return result
    }

    // MARK: - Update

    func updateSession(
        id: Int,
        date: String? = nil,
        venue: String? = nil,
        feePerPlayer: Double? = nil,
        maxParticipants: Int? = nil,
        registrationDeadline: Date? = nil,
        startTime: Date? = nil,
        endTime: Date? = nil
    ) async throws -> ClubSession {
        let payload = SessionUpdatePayload(
            date: date,
            venue: venue,
            feePerPlayer: feePerPlayer,
            maxParticipants: maxParticipants,
            registrationDeadline: registrationDeadline,
            startTime: startTime,
            endTime: endTime
        )
        let result: ClubSession = try await supabase
            .from("sessions")
            .update(payload)
            .eq("id", value: id)
            .select()
            .single()
            .execute()
            .value
        return result
    }

    // MARK: - Recurring

    func createRecurringSession(
        clubId: UUID,
        date: String,
        venue: String,
        feePerPlayer: Double,
        maxParticipants: Int,
        startTime: Date?,
        endTime: Date?,
        sessionType: String,
        recurringConfig: RecurringConfig
    ) async throws -> ClubSession {
        let payload = RecurringSessionInsertPayload(
            clubId: clubId,
            date: date,
            venue: venue,
            status: "upcoming",
            feePerPlayer: feePerPlayer,
            maxParticipants: maxParticipants,
            startTime: startTime,
            endTime: endTime,
            sessionType: sessionType,
            isTemplate: true,
            recurringConfig: recurringConfig
        )
        let templateSession: ClubSession = try await supabase
            .from("sessions")
            .insert(payload)
            .select()
            .single()
            .execute()
            .value

        try await supabase.functions.invoke(
            "generate-recurring-sessions",
            options: .init(body: ["session_id": templateSession.id])
        )

        return templateSession
    }

    func deleteSessionSeries(parentSessionId: Int) async throws {
        try await supabase
            .from("sessions")
            .delete()
            .eq("parent_session_id", value: parentSessionId)
            .execute()
        try await supabase
            .from("sessions")
            .delete()
            .eq("id", value: parentSessionId)
            .execute()
    }

    // MARK: - Delete

    func deleteSession(id: Int) async throws {
        try await supabase
            .from("sessions")
            .delete()
            .eq("id", value: id)
            .execute()
    }
}
