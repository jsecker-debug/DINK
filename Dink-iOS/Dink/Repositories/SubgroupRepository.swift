import Foundation
import Supabase

struct SubgroupRepository {

    // MARK: - Payloads

    private struct SubgroupInsertPayload: Codable {
        let clubId: UUID
        let name: String
        let color: String
        let description: String?

        enum CodingKeys: String, CodingKey {
            case clubId = "club_id"
            case name, color, description
        }
    }

    private struct SubgroupUpdatePayload: Codable {
        let name: String
        let color: String
        let description: String?

        enum CodingKeys: String, CodingKey {
            case name, color, description
        }
    }

    private struct SubgroupMemberInsertPayload: Codable {
        let subgroupId: UUID
        let userId: UUID

        enum CodingKeys: String, CodingKey {
            case subgroupId = "subgroup_id"
            case userId = "user_id"
        }
    }

    // MARK: - Fetch

    func fetchSubgroups(clubId: UUID) async throws -> [Subgroup] {
        let response: [Subgroup] = try await supabase
            .from("subgroups")
            .select()
            .eq("club_id", value: clubId.uuidString)
            .order("name", ascending: true)
            .execute()
            .value
        return response
    }

    // MARK: - Create

    func createSubgroup(clubId: UUID, name: String, color: String, description: String?) async throws -> Subgroup {
        let payload = SubgroupInsertPayload(
            clubId: clubId,
            name: name,
            color: color,
            description: description
        )
        let result: Subgroup = try await supabase
            .from("subgroups")
            .insert(payload)
            .select()
            .single()
            .execute()
            .value
        return result
    }

    // MARK: - Update

    func updateSubgroup(id: UUID, name: String, color: String, description: String?) async throws {
        let payload = SubgroupUpdatePayload(
            name: name,
            color: color,
            description: description
        )
        try await supabase
            .from("subgroups")
            .update(payload)
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - Delete

    func deleteSubgroup(id: UUID) async throws {
        try await supabase
            .from("subgroups")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - Members

    func fetchSubgroupMembers(subgroupId: UUID) async throws -> [SubgroupMember] {
        let response: [SubgroupMember] = try await supabase
            .from("subgroup_members")
            .select()
            .eq("subgroup_id", value: subgroupId.uuidString)
            .execute()
            .value
        return response
    }

    func addMember(subgroupId: UUID, userId: UUID) async throws {
        let payload = SubgroupMemberInsertPayload(
            subgroupId: subgroupId,
            userId: userId
        )
        try await supabase
            .from("subgroup_members")
            .insert(payload)
            .execute()
    }

    func removeMember(subgroupId: UUID, userId: UUID) async throws {
        try await supabase
            .from("subgroup_members")
            .delete()
            .eq("subgroup_id", value: subgroupId.uuidString)
            .eq("user_id", value: userId.uuidString)
            .execute()
    }
}
