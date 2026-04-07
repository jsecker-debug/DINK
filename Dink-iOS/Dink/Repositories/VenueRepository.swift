import Foundation
import Supabase

struct VenueRepository {

    // MARK: - Payloads

    private struct VenueInsertPayload: Codable {
        let clubId: UUID
        let name: String
        let address: String?
        let numberOfCourts: Int

        enum CodingKeys: String, CodingKey {
            case clubId = "club_id"
            case name, address
            case numberOfCourts = "number_of_courts"
        }
    }

    private struct VenueUpdatePayload: Codable {
        let name: String
        let address: String?
        let numberOfCourts: Int

        enum CodingKeys: String, CodingKey {
            case name, address
            case numberOfCourts = "number_of_courts"
        }
    }

    private struct VenueDeactivatePayload: Codable {
        let isActive: Bool

        enum CodingKeys: String, CodingKey {
            case isActive = "is_active"
        }
    }

    // MARK: - Fetch

    func fetchVenues(clubId: UUID) async throws -> [Venue] {
        let response: [Venue] = try await supabase
            .from("venues")
            .select()
            .eq("club_id", value: clubId.uuidString)
            .eq("is_active", value: true)
            .order("name", ascending: true)
            .execute()
            .value
        return response
    }

    // MARK: - Create

    func createVenue(clubId: UUID, name: String, address: String?, numberOfCourts: Int) async throws -> Venue {
        let payload = VenueInsertPayload(
            clubId: clubId,
            name: name,
            address: address,
            numberOfCourts: numberOfCourts
        )
        let result: Venue = try await supabase
            .from("venues")
            .insert(payload)
            .select()
            .single()
            .execute()
            .value
        return result
    }

    // MARK: - Update

    func updateVenue(id: UUID, name: String, address: String?, numberOfCourts: Int) async throws -> Venue {
        let payload = VenueUpdatePayload(
            name: name,
            address: address,
            numberOfCourts: numberOfCourts
        )
        let result: Venue = try await supabase
            .from("venues")
            .update(payload)
            .eq("id", value: id.uuidString)
            .select()
            .single()
            .execute()
            .value
        return result
    }

    // MARK: - Delete (soft)

    func deleteVenue(id: UUID) async throws {
        let payload = VenueDeactivatePayload(isActive: false)
        try await supabase
            .from("venues")
            .update(payload)
            .eq("id", value: id.uuidString)
            .execute()
    }
}
