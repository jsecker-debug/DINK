import Foundation
import Supabase

// MARK: - Supporting Types

struct SessionRegistrationWithUser: Identifiable, Codable {
    let id: UUID
    let sessionId: Int
    let userId: UUID
    let status: String
    let registeredAt: Date?
    let feeAmount: Double?
    let userProfiles: UserProfile?

    enum CodingKeys: String, CodingKey {
        case id
        case sessionId = "session_id"
        case userId = "user_id"
        case status
        case registeredAt = "registered_at"
        case feeAmount = "fee_amount"
        case userProfiles = "user_profiles"
    }
}

enum RegistrationError: LocalizedError {
    case alreadyRegistered
    case permissionDenied
    case notFound
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .alreadyRegistered:
            return "You are already registered for this session."
        case .permissionDenied:
            return "You do not have permission to perform this action."
        case .notFound:
            return "Registration not found."
        case .unknown(let message):
            return message
        }
    }
}

// MARK: - Repository

struct RegistrationRepository {

    // MARK: - Insert Payload

    private struct RegistrationInsertPayload: Codable {
        let sessionId: Int
        let userId: UUID
        let status: String
        let feeAmount: Double

        enum CodingKeys: String, CodingKey {
            case sessionId = "session_id"
            case userId = "user_id"
            case status
            case feeAmount = "fee_amount"
        }
    }

    // MARK: - Fetch User Registration

    /// Returns the current user's registration for a session, or nil if not found.
    func fetchUserRegistration(sessionId: Int, userId: UUID) async throws -> SessionRegistration? {
        do {
            let result: SessionRegistration = try await supabase
                .from("session_registrations")
                .select()
                .eq("session_id", value: sessionId)
                .eq("user_id", value: userId.uuidString)
                .single()
                .execute()
                .value
            return result
        } catch {
            // PGRST116 = "The result contains 0 rows" from PostgREST .single()
            if let postgrestError = error as? PostgrestError,
               postgrestError.code == "PGRST116" {
                return nil
            }
            throw error
        }
    }

    // MARK: - Fetch Session Registrations (with joined profile)

    func fetchSessionRegistrations(sessionId: Int) async throws -> [SessionRegistrationWithUser] {
        let response: [SessionRegistrationWithUser] = try await supabase
            .from("session_registrations")
            .select("*, user_profiles(first_name, last_name, skill_level, avatar_url)")
            .eq("session_id", value: sessionId)
            .in("status", values: ["registered", "waitlist"])
            .order("registered_at", ascending: true)
            .execute()
            .value
        return response
    }

    // MARK: - Register for Session

    func registerForSession(
        sessionId: Int,
        userId: UUID,
        maxParticipants: Int,
        feePerPlayer: Double
    ) async throws -> (registration: SessionRegistration, isWaitlist: Bool) {
        // Check current registered count to determine status
        let currentCount = try await fetchRegistrationCount(sessionId: sessionId)
        let isWaitlist = currentCount >= maxParticipants
        let status = isWaitlist ? "waitlist" : "registered"

        let payload = RegistrationInsertPayload(
            sessionId: sessionId,
            userId: userId,
            status: status,
            feeAmount: feePerPlayer
        )

        do {
            let result: SessionRegistration = try await supabase
                .from("session_registrations")
                .insert(payload)
                .select()
                .single()
                .execute()
                .value
            return (registration: result, isWaitlist: isWaitlist)
        } catch {
            if let postgrestError = error as? PostgrestError {
                if postgrestError.code == "23505" {
                    throw RegistrationError.alreadyRegistered
                }
                if postgrestError.code == "42501" {
                    throw RegistrationError.permissionDenied
                }
            }
            throw error
        }
    }

    // MARK: - Unregister from Session

    func unregisterFromSession(sessionId: Int, userId: UUID) async throws {
        // Fetch current registration to check status
        guard let registration = try await fetchUserRegistration(sessionId: sessionId, userId: userId) else {
            throw RegistrationError.notFound
        }

        // Delete the registration
        try await supabase
            .from("session_registrations")
            .delete()
            .eq("session_id", value: sessionId)
            .eq("user_id", value: userId.uuidString)
            .execute()

        // If the user was registered (not waitlisted), promote the first waitlisted user
        if registration.status == "registered" {
            do {
                let waitlisted: [SessionRegistration] = try await supabase
                    .from("session_registrations")
                    .select()
                    .eq("session_id", value: sessionId)
                    .eq("status", value: "waitlist")
                    .order("registered_at", ascending: true)
                    .limit(1)
                    .execute()
                    .value

                if let first = waitlisted.first {
                    try await supabase
                        .from("session_registrations")
                        .update(["status": "registered"])
                        .eq("id", value: first.id.uuidString)
                        .execute()
                }
            } catch {
                // Log but don't throw — main deregistration already succeeded
                print("[RegistrationRepository] Waitlist promotion failed: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Fetch Registration Count

    func fetchRegistrationCount(sessionId: Int) async throws -> Int {
        let count = try await supabase
            .from("session_registrations")
            .select("*", head: true, count: .exact)
            .eq("session_id", value: sessionId)
            .eq("status", value: "registered")
            .execute()
            .count ?? 0
        return count
    }
}
