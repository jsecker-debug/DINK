import Foundation

enum KingOfCourtEngine {

    struct GameResult {
        let courts: [KingOfCourtState]
        let queue: [KingOfCourtQueue]
        let match: TournamentMatch
    }

    /// Create initial court assignments and queue from registrations
    static func initialState(
        registrations: [TournamentRegistration],
        courtCount: Int,
        tournamentId: UUID
    ) -> (courts: [KingOfCourtState], queue: [KingOfCourtQueue]) {
        let shuffled = registrations.shuffled()
        let teamsPerCourt = 2
        let courtsToFill = min(courtCount, shuffled.count / teamsPerCourt)

        var courts: [KingOfCourtState] = []
        var queue: [KingOfCourtQueue] = []
        var teamIndex = 0

        // Assign first teams as kings on each court
        for courtNum in 1...courtsToFill {
            guard teamIndex < shuffled.count else { break }
            courts.append(KingOfCourtState(
                id: UUID(),
                tournamentId: tournamentId,
                courtNumber: courtNum,
                currentTeamId: shuffled[teamIndex].id,
                streak: 0,
                updatedAt: Date()
            ))
            teamIndex += 1
        }

        // Remaining teams go into the queue
        var queuePos = 1
        while teamIndex < shuffled.count {
            queue.append(KingOfCourtQueue(
                id: UUID(),
                tournamentId: tournamentId,
                teamId: shuffled[teamIndex].id,
                queuePosition: queuePos
            ))
            queuePos += 1
            teamIndex += 1
        }

        return (courts, queue)
    }

    /// Process a completed game on a court.
    /// - Winner stays (or goes to back of queue if maxStreak reached).
    /// - Loser goes to back of queue.
    /// - Next team from queue becomes the challenger.
    static func processResult(
        winnerTeamId: UUID,
        loserTeamId: UUID,
        courtNumber: Int,
        courts: [KingOfCourtState],
        queue: [KingOfCourtQueue],
        tournamentId: UUID,
        maxStreak: Int? = nil
    ) -> GameResult {
        var updatedCourts = courts
        var updatedQueue = queue

        guard let courtIndex = updatedCourts.firstIndex(where: { $0.courtNumber == courtNumber }) else {
            // Court not found, return unchanged
            return GameResult(
                courts: courts,
                queue: queue,
                match: createMatch(
                    tournamentId: tournamentId,
                    courtNumber: courtNumber,
                    teamA: winnerTeamId,
                    teamB: loserTeamId,
                    winnerId: winnerTeamId
                )
            )
        }

        let court = updatedCourts[courtIndex]
        let newStreak = (court.currentTeamId == winnerTeamId) ? court.streak + 1 : 1
        let dethroned = maxStreak != nil && newStreak >= maxStreak!

        // Determine which teams need to go to queue
        var teamsToQueue: [UUID] = [loserTeamId]
        if dethroned {
            teamsToQueue.append(winnerTeamId)
        }

        // Add losing team (and possibly dethroned winner) to back of queue
        let maxQueuePos = updatedQueue.map(\.queuePosition).max() ?? 0
        for (offset, teamId) in teamsToQueue.enumerated() {
            updatedQueue.append(KingOfCourtQueue(
                id: UUID(),
                tournamentId: tournamentId,
                teamId: teamId,
                queuePosition: maxQueuePos + 1 + offset
            ))
        }

        // Update court with winner (or next from queue if dethroned)
        if dethroned {
            // Pull next team from queue to be king
            if let next = updatedQueue.sorted(by: { $0.queuePosition < $1.queuePosition }).first {
                updatedCourts[courtIndex] = KingOfCourtState(
                    id: court.id,
                    tournamentId: tournamentId,
                    courtNumber: courtNumber,
                    currentTeamId: next.teamId,
                    streak: 0,
                    updatedAt: Date()
                )
                updatedQueue.removeAll { $0.id == next.id }
            }
        } else {
            updatedCourts[courtIndex] = KingOfCourtState(
                id: court.id,
                tournamentId: tournamentId,
                courtNumber: courtNumber,
                currentTeamId: winnerTeamId,
                streak: newStreak,
                updatedAt: Date()
            )
        }

        // Renumber queue positions
        updatedQueue.sort { $0.queuePosition < $1.queuePosition }
        var renumbered: [KingOfCourtQueue] = []
        for (i, item) in updatedQueue.enumerated() {
            renumbered.append(KingOfCourtQueue(
                id: item.id,
                tournamentId: tournamentId,
                teamId: item.teamId,
                queuePosition: i + 1
            ))
        }

        let match = createMatch(
            tournamentId: tournamentId,
            courtNumber: courtNumber,
            teamA: winnerTeamId,
            teamB: loserTeamId,
            winnerId: winnerTeamId
        )

        return GameResult(courts: updatedCourts, queue: renumbered, match: match)
    }

    /// Get the next challenger for a given court from the queue
    static func nextChallenger(
        courtNumber: Int,
        queue: [KingOfCourtQueue]
    ) -> KingOfCourtQueue? {
        queue.sorted { $0.queuePosition < $1.queuePosition }.first
    }

    private static func createMatch(
        tournamentId: UUID,
        courtNumber: Int,
        teamA: UUID,
        teamB: UUID,
        winnerId: UUID
    ) -> TournamentMatch {
        TournamentMatch(
            id: UUID(),
            tournamentId: tournamentId,
            round: 1, // KotC doesn't use rounds meaningfully
            matchNumber: 0, // Will be set by caller or DB
            teamAId: teamA,
            teamBId: teamB,
            scoreA: nil, scoreB: nil,
            winnerId: winnerId,
            status: "completed",
            scheduledAt: nil, completedAt: Date(),
            bracketType: "king_of_court",
            courtNumber: courtNumber
        )
    }
}
