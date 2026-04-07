import Foundation
import Supabase

struct DeviceTokenRepository {

    // MARK: - Insert Payload

    private struct DeviceTokenUpsertPayload: Codable {
        let userId: UUID
        let token: String
        let platform: String
        let isActive: Bool

        enum CodingKeys: String, CodingKey {
            case userId = "user_id"
            case token
            case platform
            case isActive = "is_active"
        }
    }

    // MARK: - Upsert Token

    func upsertToken(userId: UUID, token: String) async throws {
        let payload = DeviceTokenUpsertPayload(
            userId: userId,
            token: token,
            platform: "ios",
            isActive: true
        )

        try await supabase
            .from("device_tokens")
            .upsert(payload, onConflict: "user_id,token")
            .execute()
    }

    // MARK: - Deactivate Token

    func deactivateToken(userId: UUID, token: String) async throws {
        try await supabase
            .from("device_tokens")
            .update(["is_active": false])
            .eq("user_id", value: userId.uuidString)
            .eq("token", value: token)
            .execute()
    }
}
