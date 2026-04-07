import XCTest
@testable import Dink

final class PlayerSwapServiceTests: XCTestCase {

    // MARK: - Helpers

    private func makeRotation(
        courts: [Court] = [
            Court(team1: ["Alice", "Bob"], team2: ["Carol", "Dave"]),
            Court(team1: ["Eve", "Frank"], team2: ["Grace", "Heidi"])
        ],
        resters: [String] = ["Ivan", "Judy"]
    ) -> ScheduleRotation {
        ScheduleRotation(id: UUID(), courts: courts, resters: resters)
    }

    // MARK: - Find Player Position

    func testFindPlayerPositionOnCourt() {
        let rotation = makeRotation()
        let position = PlayerSwapService.findPlayerPosition(player: "Alice", rotation: rotation)

        XCTAssertNotNil(position)
        XCTAssertFalse(position!.isResting)
        XCTAssertEqual(position!.courtIndex, 0)
        XCTAssertEqual(position!.teamType, .team1)
    }

    func testFindPlayerPositionOnTeam2() {
        let rotation = makeRotation()
        let position = PlayerSwapService.findPlayerPosition(player: "Carol", rotation: rotation)

        XCTAssertNotNil(position)
        XCTAssertFalse(position!.isResting)
        XCTAssertEqual(position!.courtIndex, 0)
        XCTAssertEqual(position!.teamType, .team2)
    }

    func testFindPlayerPositionResting() {
        let rotation = makeRotation()
        let position = PlayerSwapService.findPlayerPosition(player: "Ivan", rotation: rotation)

        XCTAssertNotNil(position)
        XCTAssertTrue(position!.isResting)
        XCTAssertNil(position!.courtIndex)
        XCTAssertNil(position!.teamType)
    }

    func testFindPlayerPositionNotFound() {
        let rotation = makeRotation()
        let position = PlayerSwapService.findPlayerPosition(player: "Unknown", rotation: rotation)
        XCTAssertNil(position)
    }

    // MARK: - Valid Swaps

    func testValidSwapTwoCourtPlayersOnDifferentTeams() throws {
        let rotation = makeRotation()
        let result = try PlayerSwapService.handlePlayerSwap(
            selectedPlayer: "Alice",
            targetPlayer: "Carol",
            rotation: rotation
        )

        // Alice should now be on team2, Carol on team1
        XCTAssertTrue(result.courts[0].team2.contains("Alice"))
        XCTAssertTrue(result.courts[0].team1.contains("Carol"))
    }

    func testValidSwapCourtPlayerAndRestingPlayer() throws {
        let rotation = makeRotation()
        let result = try PlayerSwapService.handlePlayerSwap(
            selectedPlayer: "Alice",
            targetPlayer: "Ivan",
            rotation: rotation
        )

        // Ivan should now be on court 0 team1, Alice should be resting
        XCTAssertTrue(result.courts[0].team1.contains("Ivan"))
        XCTAssertTrue(result.resters.contains("Alice"))
        XCTAssertFalse(result.resters.contains("Ivan"))
    }

    func testValidSwapRestingPlayerToCourtPlayer() throws {
        let rotation = makeRotation()
        let result = try PlayerSwapService.handlePlayerSwap(
            selectedPlayer: "Ivan",
            targetPlayer: "Bob",
            rotation: rotation
        )

        // Ivan should now be on court, Bob should be resting
        XCTAssertTrue(result.courts[0].team1.contains("Ivan"))
        XCTAssertTrue(result.resters.contains("Bob"))
        XCTAssertFalse(result.resters.contains("Ivan"))
    }

    func testValidSwapTwoRestingPlayers() throws {
        let rotation = makeRotation()
        let result = try PlayerSwapService.handlePlayerSwap(
            selectedPlayer: "Ivan",
            targetPlayer: "Judy",
            rotation: rotation
        )

        // When both are resting, the implementation removes both, then adds selected back.
        // The target player ("Judy") ends up removed — this matches the TS source behavior.
        // Effectively: selected stays resting, target disappears from resters.
        XCTAssertTrue(result.resters.contains("Ivan"))
        XCTAssertFalse(result.resters.contains("Judy"))
    }

    // MARK: - Invalid Swaps

    func testInvalidSwapSamePlayer() {
        let rotation = makeRotation()
        XCTAssertThrowsError(try PlayerSwapService.handlePlayerSwap(
            selectedPlayer: "Alice",
            targetPlayer: "Alice",
            rotation: rotation
        )) { error in
            XCTAssertTrue(error is SwapError)
            if let swapError = error as? SwapError {
                XCTAssertEqual(swapError, SwapError.cannotSwapWithSelf)
            }
        }
    }

    func testInvalidSwapSameTeam() {
        let rotation = makeRotation()
        XCTAssertThrowsError(try PlayerSwapService.handlePlayerSwap(
            selectedPlayer: "Alice",
            targetPlayer: "Bob",
            rotation: rotation
        )) { error in
            XCTAssertTrue(error is SwapError)
            if let swapError = error as? SwapError {
                XCTAssertEqual(swapError, SwapError.cannotSwapSameTeam)
            }
        }
    }

    func testInvalidSwapPlayerNotFound() {
        let rotation = makeRotation()
        XCTAssertThrowsError(try PlayerSwapService.handlePlayerSwap(
            selectedPlayer: "Unknown",
            targetPlayer: "Alice",
            rotation: rotation
        )) { error in
            XCTAssertTrue(error is SwapError)
            if let swapError = error as? SwapError {
                XCTAssertEqual(swapError, SwapError.sourcePlayerNotFound)
            }
        }
    }

    func testInvalidSwapTargetNotFound() {
        let rotation = makeRotation()
        XCTAssertThrowsError(try PlayerSwapService.handlePlayerSwap(
            selectedPlayer: "Alice",
            targetPlayer: "Unknown",
            rotation: rotation
        )) { error in
            XCTAssertTrue(error is SwapError)
            if let swapError = error as? SwapError {
                XCTAssertEqual(swapError, SwapError.targetPlayerNotFound)
            }
        }
    }

    // MARK: - Swap Result Correctness

    func testSwapCourtToCourtCorrectness() throws {
        let rotation = makeRotation()
        // Swap Alice (court 0, team1) with Grace (court 1, team2)
        let result = try PlayerSwapService.handlePlayerSwap(
            selectedPlayer: "Alice",
            targetPlayer: "Grace",
            rotation: rotation
        )

        XCTAssertTrue(result.courts[1].team2.contains("Alice"), "Alice should be in Grace's old position")
        XCTAssertTrue(result.courts[0].team1.contains("Grace"), "Grace should be in Alice's old position")
    }

    func testSwapCourtToRestCorrectness() throws {
        let rotation = makeRotation()
        let result = try PlayerSwapService.handlePlayerSwap(
            selectedPlayer: "Eve",
            targetPlayer: "Judy",
            rotation: rotation
        )

        XCTAssertTrue(result.courts[1].team1.contains("Judy"), "Judy should be in Eve's old court position")
        XCTAssertTrue(result.resters.contains("Eve"), "Eve should now be resting")
        XCTAssertFalse(result.resters.contains("Judy"), "Judy should no longer be resting")
    }

    // MARK: - Swap Preserves Other Players

    func testSwapPreservesOtherPlayers() throws {
        let rotation = makeRotation()
        let result = try PlayerSwapService.handlePlayerSwap(
            selectedPlayer: "Alice",
            targetPlayer: "Carol",
            rotation: rotation
        )

        // Bob should still be on court 0 team1
        XCTAssertTrue(result.courts[0].team1.contains("Bob"))
        // Dave should still be on court 0 team2
        XCTAssertTrue(result.courts[0].team2.contains("Dave"))
        // Court 1 should be unchanged
        XCTAssertEqual(Set(result.courts[1].team1), Set(["Eve", "Frank"]))
        XCTAssertEqual(Set(result.courts[1].team2), Set(["Grace", "Heidi"]))
        // Resters should be unchanged
        XCTAssertEqual(Set(result.resters), Set(["Ivan", "Judy"]))
    }

    // MARK: - Swap Preserves Court Count

    func testSwapPreservesCourtCount() throws {
        let rotation = makeRotation()

        let result1 = try PlayerSwapService.handlePlayerSwap(
            selectedPlayer: "Alice",
            targetPlayer: "Grace",
            rotation: rotation
        )
        XCTAssertEqual(result1.courts.count, rotation.courts.count)

        let result2 = try PlayerSwapService.handlePlayerSwap(
            selectedPlayer: "Alice",
            targetPlayer: "Ivan",
            rotation: rotation
        )
        XCTAssertEqual(result2.courts.count, rotation.courts.count)
    }

    // MARK: - Cross-Court Swap on Different Courts

    func testSwapPlayersBetweenDifferentCourts() throws {
        let rotation = makeRotation()
        // Swap Bob (court 0, team1) with Frank (court 1, team1)
        let result = try PlayerSwapService.handlePlayerSwap(
            selectedPlayer: "Bob",
            targetPlayer: "Frank",
            rotation: rotation
        )

        XCTAssertTrue(result.courts[0].team1.contains("Frank"))
        XCTAssertTrue(result.courts[1].team1.contains("Bob"))
    }
}
