import Foundation

// MARK: - Schedule Generator
// Generates rotation schedules for pickleball sessions with fair rest distribution
// and minimized repeat partnerships.

// MARK: - Types
// Court and ScheduleRotation are defined in Models/ScheduleTypes.swift

struct SessionPlayer {
    let id: String
    let name: String
    let skillLevel: Double?
}

struct ScheduleSettings {
    var courts: Int
    var rounds: Int
}

// MARK: - Generation Result

struct ScheduleGenerationResult {
    let rotations: [ScheduleRotation]
    let totalPlayers: Int
    let courtsUsed: Int
    let roundsGenerated: Int
}

// MARK: - Errors

enum ScheduleGenerationError: Error, LocalizedError {
    case notEnoughPlayers(minimum: Int)
    case notEnoughPlayersForCourts(needed: Int, available: Int)

    var errorDescription: String? {
        switch self {
        case .notEnoughPlayers(let minimum):
            return "Need at least \(minimum) registered players to generate a schedule"
        case .notEnoughPlayersForCourts(let needed, let available):
            return "Not enough players. Need at least \(needed) players for the configured courts, but only \(available) available"
        }
    }
}

// MARK: - Schedule Generator

enum ScheduleGenerator {

    /// Generate a full session schedule with fair rest distribution and minimized repeat partnerships.
    static func generate(
        players: [SessionPlayer],
        settings: ScheduleSettings
    ) throws -> ScheduleGenerationResult {
        guard players.count >= 4 else {
            throw ScheduleGenerationError.notEnoughPlayers(minimum: 4)
        }

        let maxPlayersPerRound = settings.courts * 4 // 4 players per court
        let totalPlayers = players.count

        guard totalPlayers >= maxPlayersPerRound else {
            throw ScheduleGenerationError.notEnoughPlayersForCourts(
                needed: maxPlayersPerRound,
                available: totalPlayers
            )
        }

        var generatedRotations: [ScheduleRotation] = []
        var restCounts = [Int](repeating: 0, count: totalPlayers)
        var restHistory = [Int](repeating: -1, count: totalPlayers) // Track last rotation each player rested

        // Track partnerships: partnershipCounts[i][j] = number of times player i partnered with player j
        var partnershipCounts = [[Int]](repeating: [Int](repeating: 0, count: totalPlayers), count: totalPlayers)

        for roundNum in 0..<settings.rounds {
            let playersThisRound = min(maxPlayersPerRound, totalPlayers)
            let restersCount = max(0, totalPlayers - playersThisRound)

            var resterIndices: [Int] = []
            var playingIndices: [Int] = []

            if restersCount == 0 {
                // No resters needed - all players play
                playingIndices = Array(0..<totalPlayers)
            } else {
                // Calculate rest priority for each player - LOWER priority means more likely to rest
                var playersWithPriority: [(idx: Int, restCount: Int, lastRested: Int, priority: Int)] = []
                for idx in 0..<totalPlayers {
                    playersWithPriority.append((
                        idx: idx,
                        restCount: restCounts[idx],
                        lastRested: restHistory[idx],
                        priority: 0
                    ))
                }

                // Calculate priority: players who haven't rested get LOWEST priority (should rest first)
                for i in 0..<playersWithPriority.count {
                    if playersWithPriority[i].restCount == 0 {
                        // Players who haven't rested should rest first - give them LOW priority
                        playersWithPriority[i].priority = 0
                    } else {
                        // Players who have rested get higher priority (less likely to rest again)
                        // The more they've rested and the more recently they rested, the higher their priority
                        let timeSinceRest = playersWithPriority[i].lastRested == -1
                            ? settings.rounds
                            : (roundNum - playersWithPriority[i].lastRested)
                        playersWithPriority[i].priority = playersWithPriority[i].restCount * 1000 + (settings.rounds - timeSinceRest) * 100
                    }
                }

                // Sort by priority (lowest first for resting selection)
                playersWithPriority.sort { a, b in
                    let priorityDiff = a.priority - b.priority
                    if priorityDiff != 0 { return priorityDiff < 0 }

                    // If priorities are equal, prioritize by:
                    // 1. Who rested least recently (longer time since last rest)
                    let aTimeSinceRest = a.lastRested == -1 ? settings.rounds : (roundNum - a.lastRested)
                    let bTimeSinceRest = b.lastRested == -1 ? settings.rounds : (roundNum - b.lastRested)
                    let timeDiff = bTimeSinceRest - aTimeSinceRest
                    if timeDiff != 0 { return timeDiff < 0 }

                    // Deterministic tiebreaker using player index
                    return a.idx < b.idx
                }

                // Select resters (lowest priority players - those who should rest)
                resterIndices = playersWithPriority.prefix(restersCount).map { $0.idx }

                // Update rest counts and history for resters
                for idx in resterIndices {
                    restCounts[idx] += 1
                    restHistory[idx] = roundNum
                }

                // Get playing players (not resting) - those with higher priority
                playingIndices = playersWithPriority.dropFirst(restersCount).map { $0.idx }
            }

            // Create optimal pairings to minimize repeated partnerships
            let roundCourts = createOptimalPairings(
                playingIndices: playingIndices,
                partnershipCounts: partnershipCounts,
                players: players
            )

            // Update partnership counts
            for court in roundCourts {
                let team1Indices = court.team1.map { name in players.firstIndex(where: { $0.name == name }) ?? -1 }
                let team2Indices = court.team2.map { name in players.firstIndex(where: { $0.name == name }) ?? -1 }

                // Update partnership counts for team 1
                if team1Indices.count == 2 && team1Indices[0] != -1 && team1Indices[1] != -1 {
                    partnershipCounts[team1Indices[0]][team1Indices[1]] += 1
                    partnershipCounts[team1Indices[1]][team1Indices[0]] += 1
                }

                // Update partnership counts for team 2
                if team2Indices.count == 2 && team2Indices[0] != -1 && team2Indices[1] != -1 {
                    partnershipCounts[team2Indices[0]][team2Indices[1]] += 1
                    partnershipCounts[team2Indices[1]][team2Indices[0]] += 1
                }
            }

            // Add rotation
            generatedRotations.append(ScheduleRotation(
                courts: roundCourts,
                resters: resterIndices.map { players[$0].name }
            ))
        }

        return ScheduleGenerationResult(
            rotations: generatedRotations,
            totalPlayers: totalPlayers,
            courtsUsed: settings.courts,
            roundsGenerated: settings.rounds
        )
    }

    // MARK: - Optimal Pairings

    /// Create optimal pairings that minimize repeated partnerships.
    private static func createOptimalPairings(
        playingIndices: [Int],
        partnershipCounts: [[Int]],
        players: [SessionPlayer]
    ) -> [Court] {
        var courts: [Court] = []
        var availablePlayers = playingIndices

        // Create courts (4 players per court)
        while availablePlayers.count >= 4 {
            var bestPairing: (players: [Int], teams: (team1: [Int], team2: [Int]))? = nil
            var lowestScore = Int.max

            // Try all possible combinations of 4 players from available players
            for i in 0..<(availablePlayers.count - 3) {
                for j in (i + 1)..<(availablePlayers.count - 2) {
                    for k in (j + 1)..<(availablePlayers.count - 1) {
                        for l in (k + 1)..<availablePlayers.count {
                            let fourPlayers = [availablePlayers[i], availablePlayers[j], availablePlayers[k], availablePlayers[l]]

                            // Try different team combinations for these 4 players
                            let teamCombinations: [(team1: [Int], team2: [Int])] = [
                                (team1: [fourPlayers[0], fourPlayers[1]], team2: [fourPlayers[2], fourPlayers[3]]),
                                (team1: [fourPlayers[0], fourPlayers[2]], team2: [fourPlayers[1], fourPlayers[3]]),
                                (team1: [fourPlayers[0], fourPlayers[3]], team2: [fourPlayers[1], fourPlayers[2]])
                            ]

                            for combination in teamCombinations {
                                let score = calculatePartnershipScore(teamCombination: combination, partnershipCounts: partnershipCounts)
                                if score < lowestScore {
                                    lowestScore = score
                                    bestPairing = (players: fourPlayers, teams: combination)
                                }
                            }
                        }
                    }
                }
            }

            if let pairing = bestPairing {
                // Remove selected players from available pool
                for playerIdx in pairing.players {
                    if let index = availablePlayers.firstIndex(of: playerIdx) {
                        availablePlayers.remove(at: index)
                    }
                }

                // Add court with player names
                courts.append(Court(
                    team1: pairing.teams.team1.map { players[$0].name },
                    team2: pairing.teams.team2.map { players[$0].name }
                ))
            } else {
                // Fallback: just group remaining players
                if availablePlayers.count >= 4 {
                    let courtPlayers = Array(availablePlayers.prefix(4))
                    availablePlayers.removeFirst(4)
                    courts.append(Court(
                        team1: [players[courtPlayers[0]].name, players[courtPlayers[1]].name],
                        team2: [players[courtPlayers[2]].name, players[courtPlayers[3]].name]
                    ))
                }
            }
        }

        return courts
    }

    // MARK: - Partnership Scoring

    /// Calculate partnership score (lower is better - fewer repeated partnerships).
    private static func calculatePartnershipScore(
        teamCombination: (team1: [Int], team2: [Int]),
        partnershipCounts: [[Int]]
    ) -> Int {
        var score = 0

        // Score for team 1 partnership
        if teamCombination.team1.count == 2 {
            score += partnershipCounts[teamCombination.team1[0]][teamCombination.team1[1]]
        }

        // Score for team 2 partnership
        if teamCombination.team2.count == 2 {
            score += partnershipCounts[teamCombination.team2[0]][teamCombination.team2[1]]
        }

        return score
    }
}
