import Foundation
import Supabase

struct TemporaryParticipantRepository {

    // MARK: - Payloads

    private struct InsertPayload: Codable {
        let sessionId: Int
        let name: String
        let skillLevel: Double
        let phone: String?
        let notes: String?
        let createdBy: UUID

        enum CodingKeys: String, CodingKey {
            case sessionId = "session_id"
            case name
            case skillLevel = "skill_level"
            case phone
            case notes
            case createdBy = "created_by"
        }
    }

    private struct UpdatePayload: Codable {
        let name: String?
        let skillLevel: Double?
        let phone: String?
        let notes: String?

        enum CodingKeys: String, CodingKey {
            case name
            case skillLevel = "skill_level"
            case phone
            case notes
        }
    }

    // MARK: - Fetch

    func fetchTemporaryParticipants(sessionId: Int) async throws -> [TemporaryParticipant] {
        let response: [TemporaryParticipant] = try await supabase
            .from("temporary_session_participants")
            .select()
            .eq("session_id", value: sessionId)
            .order("created_at", ascending: true)
            .execute()
            .value
        return response
    }

    // MARK: - Add

    func addTemporaryParticipant(
        sessionId: Int,
        name: String,
        skillLevel: Double,
        phone: String? = nil,
        notes: String? = nil,
        createdBy: UUID
    ) async throws -> TemporaryParticipant {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPhone = phone?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        let trimmedNotes = notes?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty

        let payload = InsertPayload(
            sessionId: sessionId,
            name: trimmedName,
            skillLevel: skillLevel,
            phone: trimmedPhone,
            notes: trimmedNotes,
            createdBy: createdBy
        )

        let result: TemporaryParticipant = try await supabase
            .from("temporary_session_participants")
            .insert(payload)
            .select()
            .single()
            .execute()
            .value
        return result
    }

    // MARK: - Remove

    func removeTemporaryParticipant(id: UUID) async throws {
        try await supabase
            .from("temporary_session_participants")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - Update

    func updateTemporaryParticipant(
        id: UUID,
        name: String? = nil,
        skillLevel: Double? = nil,
        phone: String? = nil,
        notes: String? = nil
    ) async throws -> TemporaryParticipant {
        let trimmedName = name?.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPhone = phone?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        let trimmedNotes = notes?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty

        let payload = UpdatePayload(
            name: trimmedName,
            skillLevel: skillLevel,
            phone: trimmedPhone,
            notes: trimmedNotes
        )

        let result: TemporaryParticipant = try await supabase
            .from("temporary_session_participants")
            .update(payload)
            .eq("id", value: id.uuidString)
            .select()
            .single()
            .execute()
            .value
        return result
    }
}

// MARK: - String Helper

private extension String {
    /// Returns nil if the string is empty after trimming, otherwise returns self.
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
