import Foundation

enum DoubleEliminationEngine {

    static func generate(registrations: [TournamentRegistration]) -> [TournamentMatch] {
        let teams = registrations.shuffled()
        guard teams.count >= 2 else { return [] }

        let tournamentId = teams[0].tournamentId

        // Pad to nearest power of 2
        var bracketSize = 1
        while bracketSize < teams.count { bracketSize *= 2 }
        let winnersRounds = Int(log2(Double(bracketSize)))

        var matches: [TournamentMatch] = []
        var matchNumber = 1

        // === WINNERS BRACKET ===
        // Round 1
        for i in stride(from: 0, to: bracketSize, by: 2) {
            let teamA = i < teams.count ? teams[i].id : nil
            let teamB = (i + 1) < teams.count ? teams[i + 1].id : nil
            let isBye = teamA == nil || teamB == nil
            matches.append(TournamentMatch(
                id: UUID(), tournamentId: tournamentId,
                round: 1, matchNumber: matchNumber,
                teamAId: teamA, teamBId: teamB,
                scoreA: nil, scoreB: nil,
                winnerId: isBye ? (teamA ?? teamB) : nil,
                status: isBye ? "completed" : "scheduled",
                scheduledAt: nil, completedAt: nil,
                bracketType: "winners", courtNumber: nil
            ))
            matchNumber += 1
        }

        // Winners rounds 2+
        for round in 2...winnersRounds {
            let matchesInRound = bracketSize / Int(pow(2.0, Double(round)))
            for _ in 0..<matchesInRound {
                matches.append(TournamentMatch(
                    id: UUID(), tournamentId: tournamentId,
                    round: round, matchNumber: matchNumber,
                    teamAId: nil, teamBId: nil,
                    scoreA: nil, scoreB: nil, winnerId: nil,
                    status: "scheduled",
                    scheduledAt: nil, completedAt: nil,
                    bracketType: "winners", courtNumber: nil
                ))
                matchNumber += 1
            }
        }

        // === LOSERS BRACKET ===
        // Losers bracket has 2 * (winnersRounds - 1) rounds, organized in pairs:
        //   Odd rounds: drop-down rounds (losers from winners bracket enter)
        //   Even rounds: internal elimination rounds
        // Winners R1 losers -> Losers R1 (play each other)
        // Losers R1 winners -> Losers R2 (internal elimination)
        // Winners R2 losers -> Losers R3 (play against Losers R2 survivors)
        // Losers R3 winners -> Losers R4 (internal elimination)
        // etc.
        let losersRounds = 2 * (winnersRounds - 1)
        for round in 1...losersRounds {
            // Losers rounds come in pairs: odd = drop-down, even = internal
            let pairIndex = (round - 1) / 2 // which pair (0-based)
            // Matches halve every pair
            let matchesInRound = max(1, bracketSize / Int(pow(2.0, Double(pairIndex + 2))))

            for _ in 0..<matchesInRound {
                matches.append(TournamentMatch(
                    id: UUID(), tournamentId: tournamentId,
                    round: round, matchNumber: matchNumber,
                    teamAId: nil, teamBId: nil,
                    scoreA: nil, scoreB: nil, winnerId: nil,
                    status: "scheduled",
                    scheduledAt: nil, completedAt: nil,
                    bracketType: "losers", courtNumber: nil
                ))
                matchNumber += 1
            }
        }

        // === GRAND FINAL ===
        matches.append(TournamentMatch(
            id: UUID(), tournamentId: tournamentId,
            round: 1, matchNumber: matchNumber,
            teamAId: nil, teamBId: nil,
            scoreA: nil, scoreB: nil, winnerId: nil,
            status: "scheduled",
            scheduledAt: nil, completedAt: nil,
            bracketType: "grand_final", courtNumber: nil
        ))

        return matches
    }

    /// Advance bracket after a match completes. Returns the match that should be updated with the advancing team.
    static func advanceWinner(
        completedMatch: TournamentMatch,
        winnerId: UUID,
        allMatches: [TournamentMatch]
    ) -> (advanceTo: TournamentMatch, slotIsTeamA: Bool)? {
        let bracketType = completedMatch.bracketType ?? "winners"

        switch bracketType {
        case "winners":
            // Find next winners bracket match
            let winnersMatches = allMatches.filter { $0.bracketType == "winners" }
            let currentRoundMatches = winnersMatches
                .filter { $0.round == completedMatch.round }
                .sorted { $0.matchNumber < $1.matchNumber }
            let nextRoundMatches = winnersMatches
                .filter { $0.round == completedMatch.round + 1 }
                .sorted { $0.matchNumber < $1.matchNumber }

            guard let indexInRound = currentRoundMatches.firstIndex(where: { $0.id == completedMatch.id }) else {
                return nil
            }

            if nextRoundMatches.isEmpty {
                // This was the winners final - advance to grand final
                if let grandFinal = allMatches.first(where: { $0.bracketType == "grand_final" }) {
                    return (grandFinal, true) // Winners champ goes to teamA slot
                }
                return nil
            }

            let nextMatchIndex = indexInRound / 2
            guard nextMatchIndex < nextRoundMatches.count else { return nil }
            let isTeamA = indexInRound % 2 == 0
            return (nextRoundMatches[nextMatchIndex], isTeamA)

        case "losers":
            let losersMatches = allMatches.filter { $0.bracketType == "losers" }
            let currentRoundMatches = losersMatches
                .filter { $0.round == completedMatch.round }
                .sorted { $0.matchNumber < $1.matchNumber }
            let nextRoundMatches = losersMatches
                .filter { $0.round == completedMatch.round + 1 }
                .sorted { $0.matchNumber < $1.matchNumber }

            guard let indexInRound = currentRoundMatches.firstIndex(where: { $0.id == completedMatch.id }) else {
                return nil
            }

            if nextRoundMatches.isEmpty {
                // Losers bracket final - advance to grand final
                if let grandFinal = allMatches.first(where: { $0.bracketType == "grand_final" }) {
                    return (grandFinal, false) // Losers champ goes to teamB slot
                }
                return nil
            }

            // In losers bracket, advancement depends on round type:
            // Even round (internal elimination) -> winners halve into next round
            // Odd round (drop-down) -> winners advance 1:1 into next round
            let nextMatchIndex = completedMatch.round % 2 == 0 ? indexInRound / 2 : indexInRound
            guard nextMatchIndex < nextRoundMatches.count else { return nil }
            let isTeamA = completedMatch.round % 2 == 1 // drop-down survivors go to teamA
            return (nextRoundMatches[nextMatchIndex], isTeamA)

        case "grand_final":
            return nil // Tournament complete

        default:
            return nil
        }
    }

    /// When a player loses in the winners bracket, find where they drop to in the losers bracket.
    /// Winners round R losers go to losers round 2*(R-1) + 1.
    static func findLosersEntry(
        completedMatch: TournamentMatch,
        loserId: UUID,
        allMatches: [TournamentMatch]
    ) -> (advanceTo: TournamentMatch, slotIsTeamA: Bool)? {
        guard completedMatch.bracketType == "winners" else { return nil }

        let winnersMatches = allMatches.filter { $0.bracketType == "winners" }
        let currentRoundMatches = winnersMatches
            .filter { $0.round == completedMatch.round }
            .sorted { $0.matchNumber < $1.matchNumber }

        guard let indexInRound = currentRoundMatches.firstIndex(where: { $0.id == completedMatch.id }) else {
            return nil
        }

        // Winners round R losers go to losers round 2*(R-1) + 1
        let losersEntryRound = 2 * (completedMatch.round - 1) + 1
        let losersMatches = allMatches
            .filter { $0.bracketType == "losers" && $0.round == losersEntryRound }
            .sorted { $0.matchNumber < $1.matchNumber }

        // Map position: round 1 losers pair up (halve), later rounds map 1:1
        let losersIndex: Int
        if completedMatch.round == 1 {
            losersIndex = indexInRound / 2
        } else {
            losersIndex = indexInRound
        }

        guard losersIndex < losersMatches.count else { return nil }
        return (losersMatches[losersIndex], false) // Dropdowns go to teamB slot
    }
}
