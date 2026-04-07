import Foundation
import Supabase

// MARK: - View Models

struct RegistrationWithProfile: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let status: String
    let feeAmount: Double?
    let userProfiles: PaymentUserProfile

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case status
        case feeAmount = "fee_amount"
        case userProfiles = "user_profiles"
    }
}

struct PaymentUserProfile: Codable {
    let firstName: String?
    let lastName: String?
    let email: String?

    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName = "last_name"
        case email
    }
}

struct PaymentStatusRecord: Codable {
    let registrationId: UUID
    let paid: Bool

    enum CodingKeys: String, CodingKey {
        case registrationId = "registration_id"
        case paid
    }
}

// MARK: - Repository

struct PaymentRepository {

    // MARK: - Insert / Upsert Payloads

    private struct PaymentUpsert: Codable {
        let sessionId: Int
        let registrationId: UUID
        let paid: Bool
        let updatedAt: String

        enum CodingKeys: String, CodingKey {
            case sessionId = "session_id"
            case registrationId = "registration_id"
            case paid
            case updatedAt = "updated_at"
        }
    }

    // MARK: - Fetch Sessions With Fees

    func fetchSessionsWithFees(clubId: UUID) async throws -> [ClubSession] {
        let sessions: [ClubSession] = try await supabase
            .from("sessions")
            .select()
            .eq("club_id", value: clubId.uuidString)
            .gt("fee_per_player", value: 0)
            .order("Date", ascending: false)
            .execute()
            .value
        return sessions
    }

    // MARK: - Fetch Registrations For Payment

    func fetchRegistrationsForPayment(sessionId: Int) async throws -> [RegistrationWithProfile] {
        let registrations: [RegistrationWithProfile] = try await supabase
            .from("session_registrations")
            .select("id, user_id, status, fee_amount, user_profiles!inner(first_name, last_name, email)")
            .eq("session_id", value: sessionId)
            .eq("status", value: "registered")
            .execute()
            .value
        return registrations
    }

    // MARK: - Fetch Payment Statuses

    func fetchPaymentStatuses(sessionId: Int) async throws -> [PaymentStatusRecord] {
        let statuses: [PaymentStatusRecord] = try await supabase
            .from("session_payments")
            .select("registration_id, paid")
            .eq("session_id", value: sessionId)
            .execute()
            .value
        return statuses
    }

    // MARK: - Update Payment Status

    func updatePaymentStatus(sessionId: Int, registrationId: UUID, paid: Bool) async throws {
        let formatter = ISO8601DateFormatter()
        let payload = PaymentUpsert(
            sessionId: sessionId,
            registrationId: registrationId,
            paid: paid,
            updatedAt: formatter.string(from: Date())
        )
        try await supabase
            .from("session_payments")
            .upsert(payload, onConflict: "session_id,registration_id")
            .execute()
    }
}
