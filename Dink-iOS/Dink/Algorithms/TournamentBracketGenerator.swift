import Foundation

enum TournamentBracketGenerator {

    /// Generate round-robin pairings for all registrations
    static func generateRoundRobin(registrations: [TournamentRegistration]) -> [TournamentMatch] {
        var matches: [TournamentMatch] = []
        let teams = registrations
        var round = 1
        var matchNumber = 1

        for i in 0..<teams.count {
            for j in (i + 1)..<teams.count {
                matches.append(TournamentMatch(
                    id: UUID(),
                    tournamentId: teams[i].tournamentId,
                    round: round,
                    matchNumber: matchNumber,
                    teamAId: teams[i].id,
                    teamBId: teams[j].id,
                    scoreA: nil, scoreB: nil, winnerId: nil,
                    status: "scheduled",
                    scheduledAt: nil, completedAt: nil,
                    bracketType: nil, courtNumber: nil
                ))
                matchNumber += 1
                if matchNumber > teams.count / 2 {
                    matchNumber = 1
                    round += 1
                }
            }
        }
        return matches
    }

    /// Generate single elimination bracket
    static func generateElimination(registrations: [TournamentRegistration]) -> [TournamentMatch] {
        var matches: [TournamentMatch] = []
        let teams = registrations.shuffled()

        // Pad to nearest power of 2
        var bracketSize = 1
        while bracketSize < teams.count { bracketSize *= 2 }

        let totalRounds = Int(log2(Double(bracketSize)))
        var matchNumber = 1

        // First round - pair teams, byes for extras
        for i in stride(from: 0, to: bracketSize, by: 2) {
            let teamA = i < teams.count ? teams[i].id : nil
            let teamB = (i + 1) < teams.count ? teams[i + 1].id : nil

            matches.append(TournamentMatch(
                id: UUID(),
                tournamentId: registrations.first!.tournamentId,
                round: 1,
                matchNumber: matchNumber,
                teamAId: teamA,
                teamBId: teamB,
                scoreA: nil, scoreB: nil,
                winnerId: teamB == nil ? teamA : nil,
                status: teamB == nil ? "completed" : "scheduled",
                scheduledAt: nil,
                completedAt: nil,
                bracketType: "winners", courtNumber: nil
            ))
            matchNumber += 1
        }

        // Subsequent rounds (empty matches to be filled)
        for round in 2...totalRounds {
            let matchesInRound = bracketSize / Int(pow(2.0, Double(round)))
            for _ in 0..<matchesInRound {
                matches.append(TournamentMatch(
                    id: UUID(),
                    tournamentId: registrations.first!.tournamentId,
                    round: round,
                    matchNumber: matchNumber,
                    teamAId: nil, teamBId: nil,
                    scoreA: nil, scoreB: nil, winnerId: nil,
                    status: "scheduled",
                    scheduledAt: nil, completedAt: nil,
                    bracketType: "winners", courtNumber: nil
                ))
                matchNumber += 1
            }
        }

        return matches
    }

    /// Generate double elimination bracket
    static func generateDoubleElimination(registrations: [TournamentRegistration]) -> [TournamentMatch] {
        DoubleEliminationEngine.generate(registrations: registrations)
    }

    /// Set up King of the Court initial state
    static func generateKingOfTheCourt(
        registrations: [TournamentRegistration],
        courtCount: Int,
        tournamentId: UUID
    ) -> (courts: [KingOfCourtState], queue: [KingOfCourtQueue]) {
        KingOfCourtEngine.initialState(registrations: registrations, courtCount: courtCount, tournamentId: tournamentId)
    }
}
