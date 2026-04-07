import Foundation

// MARK: - Glicko-2 Rating System
// Adapted for pickleball with skill level 1.0-7.0 scale

// MARK: - Constants

private let TAU: Double = 0.5        // System volatility constant
private let EPSILON: Double = 0.000001 // Convergence tolerance

// MARK: - Types

struct Glicko2PlayerRating {
    let rating: Double        // Skill level (1.0-7.0)
    let confidence: Double    // Rating deviation (0.0-1.0)
    let volatility: Double    // Rating volatility (starts at 1.0, decreases)
    let totalGames: Int       // Total games played
}

struct Glicko2GameResult {
    let opponentRating: Double
    let opponentConfidence: Double
    let score: Double // 1 for win, 0.5 for tie, 0 for loss
}

// MARK: - Scale Conversion

/// Convert skill level to Glicko-2 scale (1500 +/- 400)
func scaleToGlicko(_ rating: Double) -> Double {
    return 1500 + ((rating - 4.0) * 400 / 3.0)
}

/// Convert Glicko-2 scale back to skill level (1.0-7.0)
func scaleFromGlicko(_ glickoRating: Double) -> Double {
    return max(1.0, min(7.0, 4.0 + ((glickoRating - 1500) * 3.0 / 400)))
}

/// Convert confidence to Glicko-2 RD scale
/// Confidence 0.0 = RD 350 (high uncertainty)
/// Confidence 1.0 = RD 50 (low uncertainty)
func confidenceToRD(_ confidence: Double) -> Double {
    return 350 - (confidence * 300)
}

/// Convert RD back to confidence
func rdToConfidence(_ rd: Double) -> Double {
    return max(0.0, min(1.0, (350 - rd) / 300))
}

// MARK: - Glicko-2 Core Functions

/// G function from Glicko-2
private func g(_ rd: Double) -> Double {
    return 1 / sqrt(1 + (3 * rd * rd) / (Double.pi * Double.pi))
}

/// E function from Glicko-2 (expected score)
private func expectedScore(rating: Double, opponentRating: Double, opponentRd: Double) -> Double {
    return 1 / (1 + exp(-g(opponentRd) * (rating - opponentRating)))
}

// MARK: - Internal Result Type

private struct GlickoResult {
    let rating: Double
    let rd: Double
    let score: Double
}

// MARK: - Variance Calculation

/// Calculate variance
private func calculateVariance(rating: Double, results: [GlickoResult]) -> Double {
    var variance: Double = 0
    for result in results {
        let e = expectedScore(rating: rating, opponentRating: result.rating, opponentRd: result.rd)
        variance += g(result.rd) * g(result.rd) * e * (1 - e)
    }
    return 1 / variance
}

// MARK: - Volatility Update (Illinois Method)

/// Update volatility using Illinois method
private func updateVolatility(
    rating: Double,
    rd: Double,
    volatility: Double,
    variance: Double,
    delta: Double
) -> Double {
    let a = log(volatility * volatility)

    func f(_ x: Double) -> Double {
        let ex = exp(x)
        let num = ex * (delta * delta - rd * rd - variance - ex)
        let denom = 2 * pow(rd * rd + variance + ex, 2)
        return num / denom - (x - a) / (TAU * TAU)
    }

    var capA = a
    var capB: Double

    if delta * delta > rd * rd + variance {
        capB = log(delta * delta - rd * rd - variance)
    } else {
        var k: Double = 1
        while f(a - k * TAU) < 0 {
            k += 1
        }
        capB = a - k * TAU
    }

    var fA = f(capA)
    var fB = f(capB)

    while abs(capB - capA) > EPSILON {
        let capC = capA + (capA - capB) * fA / (fB - fA)
        let fC = f(capC)

        if fC * fB < 0 {
            capA = capB
            fA = fB
        } else {
            fA = fA / 2
        }

        capB = capC
        fB = fC
    }

    return exp(capA / 2)
}

// MARK: - Main Rating Update

/// Main rating update function
func updatePlayerRating(player: Glicko2PlayerRating, gameResults: [Glicko2GameResult]) -> Glicko2PlayerRating {
    if gameResults.isEmpty {
        return player
    }

    // Convert to Glicko-2 scale
    let glickoRating = scaleToGlicko(player.rating)
    let rd = confidenceToRD(player.confidence)

    // Prepare results in Glicko-2 format
    let glickoResults = gameResults.map { result in
        GlickoResult(
            rating: scaleToGlicko(result.opponentRating),
            rd: confidenceToRD(result.opponentConfidence),
            score: result.score
        )
    }

    // Step 1: Calculate variance
    let variance = calculateVariance(rating: glickoRating, results: glickoResults)

    // Step 2: Calculate delta
    var delta: Double = 0
    for result in glickoResults {
        let e = expectedScore(rating: glickoRating, opponentRating: result.rating, opponentRd: result.rd)
        delta += g(result.rd) * (result.score - e)
    }
    delta *= variance

    // Step 3: Update volatility
    let newVolatility = updateVolatility(
        rating: glickoRating,
        rd: rd,
        volatility: player.volatility,
        variance: variance,
        delta: delta
    )

    // Step 4: Update rating deviation
    let rdStar = sqrt(rd * rd + newVolatility * newVolatility)
    let newRd = 1 / sqrt(1 / (rdStar * rdStar) + 1 / variance)

    // Step 5: Update rating
    var ratingChange: Double = 0
    for result in glickoResults {
        let e = expectedScore(rating: glickoRating, opponentRating: result.rating, opponentRd: result.rd)
        ratingChange += g(result.rd) * (result.score - e)
    }
    let newGlickoRating = glickoRating + newRd * newRd * ratingChange

    // Convert back to our scale and update confidence
    let newRating = scaleFromGlicko(newGlickoRating)
    let newConfidence = rdToConfidence(newRd)
    let newTotalGames = player.totalGames + gameResults.count

    // Boost confidence based on total games played
    let gameBasedConfidence = min(1.0, Double(newTotalGames) * 0.02) // 2% confidence per game, capped at 100%
    let finalConfidence = max(newConfidence, gameBasedConfidence)

    return Glicko2PlayerRating(
        rating: (newRating * 100).rounded() / 100,           // Round to 2 decimal places
        confidence: (finalConfidence * 100).rounded() / 100,
        volatility: max(0.05, (newVolatility * 100).rounded() / 100), // Minimum volatility of 0.05
        totalGames: newTotalGames
    )
}

// MARK: - Game Result Score Calculation

/// Calculate game result score based on individual game scores
func calculateGameResultScore(
    team1Scores: [Int],
    team2Scores: [Int],
    isTeam1Player: Bool
) -> Double {
    if team1Scores.count != team2Scores.count {
        return 0.5 // Default to tie if mismatched
    }

    var team1Wins = 0
    var team2Wins = 0
    let totalGames = team1Scores.count

    for i in 0..<totalGames {
        if team1Scores[i] > team2Scores[i] {
            team1Wins += 1
        } else if team2Scores[i] > team1Scores[i] {
            team2Wins += 1
        }
    }

    // Calculate score based on games won ratio
    let team1Score = Double(team1Wins) / Double(totalGames)
    let team2Score = Double(team2Wins) / Double(totalGames)

    return isTeam1Player ? team1Score : team2Score
}

// MARK: - Team Rating Helpers

/// Calculate average rating for doubles partners
func calculateTeamRating(player1Rating: Double, player2Rating: Double) -> Double {
    return (player1Rating + player2Rating) / 2
}

/// Calculate average confidence for doubles partners
func calculateTeamConfidence(player1Confidence: Double, player2Confidence: Double) -> Double {
    return (player1Confidence + player2Confidence) / 2
}
