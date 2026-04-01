import Foundation
import Supabase

// MARK: - Public Types

struct SessionScheduleData {
    let rotations: [ScheduleRotation]
    let randomRotations: [ScheduleRotation]
    let kingCourtRotation: ScheduleRotation?
}

// MARK: - Repository

struct RotationRepository {

    // MARK: - Fetch

    func fetchSessionSchedule(sessionId: Int) async throws -> SessionScheduleData? {
        let response: [RotationResponse] = try await supabase
            .from("rotations")
            .select("id, is_king_court, rotation_number, court_assignments(court_number, team1_players, team2_players), rotation_resters(resting_players)")
            .eq("session_id", value: sessionId)
            .order("rotation_number", ascending: true)
            .execute()
            .value

        guard !response.isEmpty else { return nil }

        var rotations: [ScheduleRotation] = []
        var kingCourtRotation: ScheduleRotation?

        for item in response {
            let courts = item.courtAssignments
                .sorted { ($0.courtNumber ?? 0) < ($1.courtNumber ?? 0) }
                .map { assignment in
                    Court(
                        team1: assignment.team1Players ?? [],
                        team2: assignment.team2Players ?? []
                    )
                }

            let resters = item.rotationResters.flatMap { $0.restingPlayers ?? [] }

            let scheduleRotation = ScheduleRotation(
                id: item.id,
                courts: courts,
                resters: resters
            )

            if item.isKingCourt == true {
                kingCourtRotation = scheduleRotation
            } else {
                rotations.append(scheduleRotation)
            }
        }

        return SessionScheduleData(
            rotations: rotations,
            randomRotations: rotations,
            kingCourtRotation: kingCourtRotation
        )
    }

    // MARK: - Save

    func saveSchedule(sessionId: Int, rotations: [ScheduleRotation]) async throws {
        // Step 1: Delete existing schedule
        try await deleteSchedule(sessionId: sessionId)

        // Step 2: Insert new rotations with their assignments and resters
        for (index, rotation) in rotations.enumerated() {
            let insertPayload = RotationInsert(
                sessionId: sessionId,
                rotationNumber: index + 1,
                isKingCourt: false
            )

            let savedRotation: Rotation = try await supabase
                .from("rotations")
                .insert(insertPayload)
                .select()
                .single()
                .execute()
                .value

            let rotationId = savedRotation.id

            // Insert court assignments
            for (courtIdx, court) in rotation.courts.enumerated() {
                let courtPayload = CourtAssignmentInsert(
                    rotationId: rotationId,
                    courtNumber: courtIdx + 1,
                    team1Players: court.team1,
                    team2Players: court.team2
                )
                try await supabase
                    .from("court_assignments")
                    .insert(courtPayload)
                    .execute()
            }

            // Insert resters if any
            if !rotation.resters.isEmpty {
                let resterPayload = ResterInsert(
                    rotationId: rotationId,
                    restingPlayers: rotation.resters
                )
                try await supabase
                    .from("rotation_resters")
                    .insert(resterPayload)
                    .execute()
            }
        }
    }

    // MARK: - Delete

    func deleteSchedule(sessionId: Int) async throws {
        // Get existing rotation IDs for this session
        let existingRotations: [Rotation] = try await supabase
            .from("rotations")
            .select("id")
            .eq("session_id", value: sessionId)
            .execute()
            .value

        let rotationIds = existingRotations.map { $0.id }

        guard !rotationIds.isEmpty else { return }

        let rotationIdStrings = rotationIds.map { $0.uuidString }

        // Delete court_assignments by rotation_id
        try await supabase
            .from("court_assignments")
            .delete()
            .in("rotation_id", values: rotationIdStrings)
            .execute()

        // Delete rotation_resters by rotation_id
        try await supabase
            .from("rotation_resters")
            .delete()
            .in("rotation_id", values: rotationIdStrings)
            .execute()

        // Delete rotations by session_id
        try await supabase
            .from("rotations")
            .delete()
            .eq("session_id", value: sessionId)
            .execute()
    }

    // MARK: - Update

    func updateRotation(rotation: ScheduleRotation, sessionId: Int) async throws {
        guard let rotationId = rotation.id else { return }

        // Update court assignments
        for (courtIdx, court) in rotation.courts.enumerated() {
            let courtNumber = courtIdx + 1
            try await supabase
                .from("court_assignments")
                .update(CourtAssignmentUpdate(
                    team1Players: court.team1,
                    team2Players: court.team2
                ))
                .eq("rotation_id", value: rotationId.uuidString)
                .eq("court_number", value: courtNumber)
                .execute()
        }

        // Update resters: delete existing and re-insert
        try await supabase
            .from("rotation_resters")
            .delete()
            .eq("rotation_id", value: rotationId.uuidString)
            .execute()

        if !rotation.resters.isEmpty {
            let resterPayload = ResterInsert(
                rotationId: rotationId,
                restingPlayers: rotation.resters
            )
            try await supabase
                .from("rotation_resters")
                .insert(resterPayload)
                .execute()
        }

        // Mark rotation as manually modified
        try await supabase
            .from("rotations")
            .update(ManuallyModifiedUpdate(manuallyModified: true))
            .eq("id", value: rotationId.uuidString)
            .execute()
    }

    // MARK: - Private Response Types

    private struct RotationResponse: Codable {
        let id: UUID
        let isKingCourt: Bool?
        let rotationNumber: Int?
        let courtAssignments: [CourtAssignmentResponse]
        let rotationResters: [ResterResponse]

        enum CodingKeys: String, CodingKey {
            case id
            case isKingCourt = "is_king_court"
            case rotationNumber = "rotation_number"
            case courtAssignments = "court_assignments"
            case rotationResters = "rotation_resters"
        }
    }

    private struct CourtAssignmentResponse: Codable {
        let courtNumber: Int?
        let team1Players: [String]?
        let team2Players: [String]?

        enum CodingKeys: String, CodingKey {
            case courtNumber = "court_number"
            case team1Players = "team1_players"
            case team2Players = "team2_players"
        }
    }

    private struct ResterResponse: Codable {
        let restingPlayers: [String]?

        enum CodingKeys: String, CodingKey {
            case restingPlayers = "resting_players"
        }
    }

    // MARK: - Private Insert / Update Types

    private struct RotationInsert: Codable {
        let sessionId: Int
        let rotationNumber: Int
        let isKingCourt: Bool

        enum CodingKeys: String, CodingKey {
            case sessionId = "session_id"
            case rotationNumber = "rotation_number"
            case isKingCourt = "is_king_court"
        }
    }

    private struct CourtAssignmentInsert: Codable {
        let rotationId: UUID
        let courtNumber: Int
        let team1Players: [String]
        let team2Players: [String]

        enum CodingKeys: String, CodingKey {
            case rotationId = "rotation_id"
            case courtNumber = "court_number"
            case team1Players = "team1_players"
            case team2Players = "team2_players"
        }
    }

    private struct CourtAssignmentUpdate: Codable {
        let team1Players: [String]
        let team2Players: [String]

        enum CodingKeys: String, CodingKey {
            case team1Players = "team1_players"
            case team2Players = "team2_players"
        }
    }

    private struct ResterInsert: Codable {
        let rotationId: UUID
        let restingPlayers: [String]

        enum CodingKeys: String, CodingKey {
            case rotationId = "rotation_id"
            case restingPlayers = "resting_players"
        }
    }

    private struct ManuallyModifiedUpdate: Codable {
        let manuallyModified: Bool

        enum CodingKeys: String, CodingKey {
            case manuallyModified = "manually_modified"
        }
    }
}
