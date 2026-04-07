import Foundation

// MARK: - Player Swap Service
// Handles bidirectional player swaps between courts and between court/rest positions.

// MARK: - Types

enum SwapTeamType: String {
    case team1
    case team2
}

struct PlayerPosition {
    let isResting: Bool
    let courtIndex: Int?
    let teamType: SwapTeamType?
}

// MARK: - Errors

enum SwapError: Error, LocalizedError {
    case noTargetPlayer
    case sourcePlayerNotFound
    case targetPlayerNotFound
    case cannotSwapWithSelf
    case sourcePlayerNotInRestPosition
    case sourcePlayerNotInCourtPosition
    case targetPlayerNotInRestPosition
    case targetPlayerNotInCourtPosition
    case cannotSwapSameTeam

    var errorDescription: String? {
        switch self {
        case .noTargetPlayer:
            return "No target player specified for swap"
        case .sourcePlayerNotFound:
            return "Could not find selected player's position"
        case .targetPlayerNotFound:
            return "Could not find target player's position"
        case .cannotSwapWithSelf:
            return "Cannot swap a player with themselves"
        case .sourcePlayerNotInRestPosition:
            return "Selected player not found in resting position"
        case .sourcePlayerNotInCourtPosition:
            return "Selected player not found in specified court position"
        case .targetPlayerNotInRestPosition:
            return "Target player not found in resting position"
        case .targetPlayerNotInCourtPosition:
            return "Target player not found in specified court position"
        case .cannotSwapSameTeam:
            return "Cannot swap players on the same team"
        }
    }
}

// MARK: - Player Swap Service

enum PlayerSwapService {

    // MARK: - Main Swap Handler

    /// Handle a player swap within a rotation. Returns the updated rotation or throws on failure.
    static func handlePlayerSwap(
        selectedPlayer: String,
        targetPlayer: String,
        rotation: ScheduleRotation
    ) throws -> ScheduleRotation {
        // Find source position
        guard let sourcePosition = findPlayerPosition(player: selectedPlayer, rotation: rotation) else {
            throw SwapError.sourcePlayerNotFound
        }

        // Find target position
        guard let targetPosition = findPlayerPosition(player: targetPlayer, rotation: rotation) else {
            throw SwapError.targetPlayerNotFound
        }

        // Validate the swap
        try validateSwap(
            selectedPlayer: selectedPlayer,
            targetPlayer: targetPlayer,
            sourcePosition: sourcePosition,
            targetPosition: targetPosition,
            rotation: rotation
        )

        // Perform the swap
        return performSwap(
            selectedPlayer: selectedPlayer,
            targetPlayer: targetPlayer,
            sourcePosition: sourcePosition,
            targetPosition: targetPosition,
            rotation: rotation
        )
    }

    // MARK: - Find Player Position

    /// Find a player's position within a rotation (court + team, or resting).
    static func findPlayerPosition(player: String, rotation: ScheduleRotation) -> PlayerPosition? {
        // Check if player is resting
        if rotation.resters.contains(player) {
            return PlayerPosition(isResting: true, courtIndex: nil, teamType: nil)
        }

        // Find player in courts
        for i in 0..<rotation.courts.count {
            let court = rotation.courts[i]
            if court.team1.contains(player) {
                return PlayerPosition(isResting: false, courtIndex: i, teamType: .team1)
            }
            if court.team2.contains(player) {
                return PlayerPosition(isResting: false, courtIndex: i, teamType: .team2)
            }
        }

        return nil
    }

    // MARK: - Validation

    /// Validate that a swap is legal.
    static func validateSwap(
        selectedPlayer: String,
        targetPlayer: String,
        sourcePosition: PlayerPosition,
        targetPosition: PlayerPosition,
        rotation: ScheduleRotation
    ) throws {
        // Cannot swap player with themselves
        if targetPlayer == selectedPlayer {
            throw SwapError.cannotSwapWithSelf
        }

        // Verify both players exist in their respective positions
        if sourcePosition.isResting {
            guard rotation.resters.contains(selectedPlayer) else {
                throw SwapError.sourcePlayerNotInRestPosition
            }
        } else {
            guard let courtIndex = sourcePosition.courtIndex,
                  let teamType = sourcePosition.teamType,
                  courtIndex < rotation.courts.count else {
                throw SwapError.sourcePlayerNotInCourtPosition
            }
            let sourceCourt = rotation.courts[courtIndex]
            let team = teamType == .team1 ? sourceCourt.team1 : sourceCourt.team2
            guard team.contains(selectedPlayer) else {
                throw SwapError.sourcePlayerNotInCourtPosition
            }
        }

        if targetPosition.isResting {
            guard rotation.resters.contains(targetPlayer) else {
                throw SwapError.targetPlayerNotInRestPosition
            }
        } else {
            guard let courtIndex = targetPosition.courtIndex,
                  let teamType = targetPosition.teamType,
                  courtIndex < rotation.courts.count else {
                throw SwapError.targetPlayerNotInCourtPosition
            }
            let targetCourt = rotation.courts[courtIndex]
            let team = teamType == .team1 ? targetCourt.team1 : targetCourt.team2
            guard team.contains(targetPlayer) else {
                throw SwapError.targetPlayerNotInCourtPosition
            }
        }

        // Prevent same player appearing twice on a team
        if !sourcePosition.isResting && !targetPosition.isResting &&
            sourcePosition.courtIndex == targetPosition.courtIndex &&
            sourcePosition.teamType == targetPosition.teamType {
            throw SwapError.cannotSwapSameTeam
        }
    }

    // MARK: - Perform Swap

    /// Perform the actual swap and return the updated rotation.
    static func performSwap(
        selectedPlayer: String,
        targetPlayer: String,
        sourcePosition: PlayerPosition,
        targetPosition: PlayerPosition,
        rotation: ScheduleRotation
    ) -> ScheduleRotation {
        var updatedRotation = rotation

        // Handle swaps involving resting players
        if sourcePosition.isResting {
            // Remove selected player from resters
            updatedRotation.resters.removeAll { $0 == selectedPlayer }

            if targetPosition.isResting {
                // Both players are resting - remove target, add selected back (effectively a no-op on positions,
                // but maintains the same logic as the TS version)
                updatedRotation.resters.removeAll { $0 == targetPlayer }
                updatedRotation.resters.append(selectedPlayer)
            } else {
                // Move target player to resters, put selected player in their spot
                let courtIndex = targetPosition.courtIndex!
                let teamType = targetPosition.teamType!
                var team = teamType == .team1
                    ? updatedRotation.courts[courtIndex].team1
                    : updatedRotation.courts[courtIndex].team2
                if let targetIndex = team.firstIndex(of: targetPlayer) {
                    team[targetIndex] = selectedPlayer
                }
                updatedRotation.resters.append(targetPlayer)
                if teamType == .team1 {
                    updatedRotation.courts[courtIndex].team1 = team
                } else {
                    updatedRotation.courts[courtIndex].team2 = team
                }
            }
        } else {
            let sourceCourtIndex = sourcePosition.courtIndex!
            let sourceTeamType = sourcePosition.teamType!
            var sourceTeam = sourceTeamType == .team1
                ? updatedRotation.courts[sourceCourtIndex].team1
                : updatedRotation.courts[sourceCourtIndex].team2
            let sourceIndex = sourceTeam.firstIndex(of: selectedPlayer)!

            if targetPosition.isResting {
                // Move selected player to resters, put target player in their spot
                updatedRotation.resters.removeAll { $0 == targetPlayer }
                sourceTeam[sourceIndex] = targetPlayer
                updatedRotation.resters.append(selectedPlayer)
                if sourceTeamType == .team1 {
                    updatedRotation.courts[sourceCourtIndex].team1 = sourceTeam
                } else {
                    updatedRotation.courts[sourceCourtIndex].team2 = sourceTeam
                }
            } else {
                // Standard court-to-court swap
                let targetCourtIndex = targetPosition.courtIndex!
                let targetTeamType = targetPosition.teamType!
                var targetTeam = targetTeamType == .team1
                    ? updatedRotation.courts[targetCourtIndex].team1
                    : updatedRotation.courts[targetCourtIndex].team2
                let targetIndex = targetTeam.firstIndex(of: targetPlayer)!

                sourceTeam[sourceIndex] = targetPlayer
                targetTeam[targetIndex] = selectedPlayer

                if sourceTeamType == .team1 {
                    updatedRotation.courts[sourceCourtIndex].team1 = sourceTeam
                } else {
                    updatedRotation.courts[sourceCourtIndex].team2 = sourceTeam
                }
                if targetTeamType == .team1 {
                    updatedRotation.courts[targetCourtIndex].team1 = targetTeam
                } else {
                    updatedRotation.courts[targetCourtIndex].team2 = targetTeam
                }
            }
        }

        return updatedRotation
    }
}
