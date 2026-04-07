import XCTest
@testable import Dink

final class ScheduleGeneratorTests: XCTestCase {

    // MARK: - Helpers

    private func makePlayers(_ count: Int) -> [SessionPlayer] {
        (0..<count).map { SessionPlayer(id: "p\($0)", name: "Player\($0)", skillLevel: 4.0) }
    }

    // MARK: - Basic Generation

    func testFourPlayersOneCourtOneRound() throws {
        let players = makePlayers(4)
        let settings = ScheduleSettings(courts: 1, rounds: 1)
        let result = try ScheduleGenerator.generate(players: players, settings: settings)

        XCTAssertEqual(result.rotations.count, 1)
        let rotation = result.rotations[0]
        XCTAssertEqual(rotation.courts.count, 1)
        XCTAssertTrue(rotation.resters.isEmpty, "No resters with exactly 4 players and 1 court")

        let court = rotation.courts[0]
        XCTAssertEqual(court.team1.count, 2)
        XCTAssertEqual(court.team2.count, 2)
    }

    func testFivePlayersOneCourtOneRound() throws {
        let players = makePlayers(5)
        let settings = ScheduleSettings(courts: 1, rounds: 1)
        let result = try ScheduleGenerator.generate(players: players, settings: settings)

        let rotation = result.rotations[0]
        XCTAssertEqual(rotation.courts.count, 1)
        XCTAssertEqual(rotation.resters.count, 1, "One player should rest with 5 players and 1 court")
    }

    func testEightPlayersTwoCourtsOneRound() throws {
        let players = makePlayers(8)
        let settings = ScheduleSettings(courts: 2, rounds: 1)
        let result = try ScheduleGenerator.generate(players: players, settings: settings)

        let rotation = result.rotations[0]
        XCTAssertEqual(rotation.courts.count, 2)
        XCTAssertTrue(rotation.resters.isEmpty, "No resters with 8 players and 2 courts")
    }

    func testEightPlayersTwoCourtsThreeRounds() throws {
        let players = makePlayers(8)
        let settings = ScheduleSettings(courts: 2, rounds: 3)
        let result = try ScheduleGenerator.generate(players: players, settings: settings)

        XCTAssertEqual(result.rotations.count, 3)
        XCTAssertEqual(result.totalPlayers, 8)
        XCTAssertEqual(result.courtsUsed, 2)
        XCTAssertEqual(result.roundsGenerated, 3)
    }

    // MARK: - Rest Fairness

    func testRestFairnessOverMultipleRounds() throws {
        let players = makePlayers(5)
        let settings = ScheduleSettings(courts: 1, rounds: 10)
        let result = try ScheduleGenerator.generate(players: players, settings: settings)

        // Count rest occurrences per player
        var restCounts: [String: Int] = [:]
        for rotation in result.rotations {
            for rester in rotation.resters {
                restCounts[rester, default: 0] += 1
            }
        }

        // Each player should rest approximately 2 times (10 rounds, 1 rester per round, 5 players)
        let counts = restCounts.values
        let minRest = counts.min() ?? 0
        let maxRest = counts.max() ?? 0
        XCTAssertLessThanOrEqual(maxRest - minRest, 1, "Rest distribution should be fair (difference <= 1)")
    }

    // MARK: - Partnership Minimization

    func testPartnershipMinimization() throws {
        let players = makePlayers(8)
        let settings = ScheduleSettings(courts: 2, rounds: 6)
        let result = try ScheduleGenerator.generate(players: players, settings: settings)

        // Track partnerships
        var partnerships: [String: Int] = [:]
        for rotation in result.rotations {
            for court in rotation.courts {
                let key1 = [court.team1[0], court.team1[1]].sorted().joined(separator: "-")
                partnerships[key1, default: 0] += 1
                let key2 = [court.team2[0], court.team2[1]].sorted().joined(separator: "-")
                partnerships[key2, default: 0] += 1
            }
        }

        // No pair should play together an excessive number of times
        let maxPartnership = partnerships.values.max() ?? 0
        // With 8 players over 6 rounds, there are 28 possible pairs but only 12 partnership slots,
        // so no pair should partner more than a few times
        XCTAssertLessThanOrEqual(maxPartnership, 4, "No pair should partner excessively")
    }

    // MARK: - Larger Groups

    func testSixteenPlayersFourCourts() throws {
        let players = makePlayers(16)
        let settings = ScheduleSettings(courts: 4, rounds: 3)
        let result = try ScheduleGenerator.generate(players: players, settings: settings)

        XCTAssertEqual(result.rotations.count, 3)
        for rotation in result.rotations {
            XCTAssertEqual(rotation.courts.count, 4)
            XCTAssertTrue(rotation.resters.isEmpty, "No resters with 16 players and 4 courts")
        }
    }

    // MARK: - Minimum Players

    func testFewerThanFourPlayersThrows() {
        let players = makePlayers(3)
        let settings = ScheduleSettings(courts: 1, rounds: 1)
        XCTAssertThrowsError(try ScheduleGenerator.generate(players: players, settings: settings)) { error in
            XCTAssertTrue(error is ScheduleGenerationError)
        }
    }

    // MARK: - Player Count Not Divisible by 4

    func testPlayerCountNotDivisibleByFour() throws {
        let players = makePlayers(6)
        let settings = ScheduleSettings(courts: 1, rounds: 3)
        let result = try ScheduleGenerator.generate(players: players, settings: settings)

        for rotation in result.rotations {
            XCTAssertEqual(rotation.resters.count, 2, "2 players should rest with 6 players and 1 court")
        }
    }

    // MARK: - Structural Invariants

    func testEachRotationHasCorrectCourtCount() throws {
        let players = makePlayers(12)
        let settings = ScheduleSettings(courts: 3, rounds: 5)
        let result = try ScheduleGenerator.generate(players: players, settings: settings)

        for rotation in result.rotations {
            XCTAssertEqual(rotation.courts.count, settings.courts)
        }
    }

    func testEachCourtHasExactlyTwoTeamsOfTwo() throws {
        let players = makePlayers(8)
        let settings = ScheduleSettings(courts: 2, rounds: 3)
        let result = try ScheduleGenerator.generate(players: players, settings: settings)

        for rotation in result.rotations {
            for court in rotation.courts {
                XCTAssertEqual(court.team1.count, 2, "Team 1 should have exactly 2 players")
                XCTAssertEqual(court.team2.count, 2, "Team 2 should have exactly 2 players")
            }
        }
    }

    func testNoPlayerAppearsTwiceInSameRotation() throws {
        let players = makePlayers(10)
        let settings = ScheduleSettings(courts: 2, rounds: 5)
        let result = try ScheduleGenerator.generate(players: players, settings: settings)

        for (index, rotation) in result.rotations.enumerated() {
            var allPlayersInRotation: [String] = []
            for court in rotation.courts {
                allPlayersInRotation.append(contentsOf: court.team1)
                allPlayersInRotation.append(contentsOf: court.team2)
            }
            allPlayersInRotation.append(contentsOf: rotation.resters)

            let uniquePlayers = Set(allPlayersInRotation)
            XCTAssertEqual(uniquePlayers.count, allPlayersInRotation.count, "Duplicate player in rotation \(index)")
        }
    }

    func testAllPlayersAccountedForInEachRotation() throws {
        let players = makePlayers(10)
        let settings = ScheduleSettings(courts: 2, rounds: 3)
        let result = try ScheduleGenerator.generate(players: players, settings: settings)

        let playerNames = Set(players.map { $0.name })

        for (index, rotation) in result.rotations.enumerated() {
            var allInRotation: Set<String> = []
            for court in rotation.courts {
                allInRotation.formUnion(court.team1)
                allInRotation.formUnion(court.team2)
            }
            allInRotation.formUnion(rotation.resters)

            XCTAssertEqual(allInRotation, playerNames, "Not all players accounted for in rotation \(index)")
        }
    }

    // MARK: - Not Enough Players For Courts

    func testNotEnoughPlayersForCourtsThrows() {
        let players = makePlayers(6)
        let settings = ScheduleSettings(courts: 2, rounds: 1) // needs 8
        XCTAssertThrowsError(try ScheduleGenerator.generate(players: players, settings: settings)) { error in
            if let scheduleError = error as? ScheduleGenerationError {
                if case .notEnoughPlayersForCourts(let needed, let available) = scheduleError {
                    XCTAssertEqual(needed, 8)
                    XCTAssertEqual(available, 6)
                } else {
                    XCTFail("Wrong error case: \(scheduleError)")
                }
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }
    }
}
