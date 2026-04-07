import XCTest
@testable import Dink

final class Glicko2Tests: XCTestCase {

    // MARK: - Scale Conversion

    func testScaleToGlickoRating1MapsToAbout1100() {
        let result = scaleToGlicko(1.0)
        XCTAssertEqual(result, 1100, accuracy: 1.0)
    }

    func testScaleToGlickoRating7MapsToAbout1900() {
        let result = scaleToGlicko(7.0)
        XCTAssertEqual(result, 1900, accuracy: 1.0)
    }

    func testScaleToGlickoRating4MapsTo1500() {
        let result = scaleToGlicko(4.0)
        XCTAssertEqual(result, 1500, accuracy: 0.01)
    }

    func testScaleConversionRoundTrips() {
        let values: [Double] = [1.0, 2.5, 4.0, 5.5, 7.0]
        for value in values {
            let glicko = scaleToGlicko(value)
            let roundTripped = scaleFromGlicko(glicko)
            XCTAssertEqual(roundTripped, value, accuracy: 0.01, "Round trip failed for \(value)")
        }
    }

    func testScaleFromGlickoClampsToRange() {
        // Very low Glicko rating should clamp to 1.0
        let low = scaleFromGlicko(0)
        XCTAssertEqual(low, 1.0, accuracy: 0.01)

        // Very high Glicko rating should clamp to 7.0
        let high = scaleFromGlicko(5000)
        XCTAssertEqual(high, 7.0, accuracy: 0.01)
    }

    // MARK: - Confidence / RD Conversion

    func testConfidenceZeroMapsToRD350() {
        let rd = confidenceToRD(0.0)
        XCTAssertEqual(rd, 350, accuracy: 0.01)
    }

    func testConfidenceOneMapsToRD50() {
        let rd = confidenceToRD(1.0)
        XCTAssertEqual(rd, 50, accuracy: 0.01)
    }

    func testConfidenceConversionRoundTrips() {
        let values: [Double] = [0.0, 0.25, 0.5, 0.75, 1.0]
        for value in values {
            let rd = confidenceToRD(value)
            let roundTripped = rdToConfidence(rd)
            XCTAssertEqual(roundTripped, value, accuracy: 0.01, "Round trip failed for \(value)")
        }
    }

    func testRdToConfidenceClampsToRange() {
        let low = rdToConfidence(500) // very high RD
        XCTAssertEqual(low, 0.0, accuracy: 0.01)

        let high = rdToConfidence(-100) // negative RD edge case
        XCTAssertEqual(high, 1.0, accuracy: 0.01)
    }

    // MARK: - Rating Update After Win

    func testRatingIncreasesAfterWin() {
        let player = Glicko2PlayerRating(rating: 3.5, confidence: 0.5, volatility: 0.5, totalGames: 10)
        let results = [Glicko2GameResult(opponentRating: 4.5, opponentConfidence: 0.5, score: 1.0)]

        let updated = updatePlayerRating(player: player, gameResults: results)
        XCTAssertGreaterThan(updated.rating, player.rating, "Rating should increase after beating a higher-rated opponent")
    }

    // MARK: - Rating Update After Loss

    func testRatingDecreasesAfterLoss() {
        let player = Glicko2PlayerRating(rating: 4.5, confidence: 0.5, volatility: 0.5, totalGames: 10)
        let results = [Glicko2GameResult(opponentRating: 3.5, opponentConfidence: 0.5, score: 0.0)]

        let updated = updatePlayerRating(player: player, gameResults: results)
        XCTAssertLessThan(updated.rating, player.rating, "Rating should decrease after losing to a lower-rated opponent")
    }

    // MARK: - Rating Update With No Games

    func testRatingUnchangedWithNoGames() {
        let player = Glicko2PlayerRating(rating: 4.0, confidence: 0.5, volatility: 0.5, totalGames: 5)
        let updated = updatePlayerRating(player: player, gameResults: [])

        XCTAssertEqual(updated.rating, player.rating, accuracy: 0.01, "Rating should not change with no games")
        XCTAssertEqual(updated.confidence, player.confidence, accuracy: 0.01, "Confidence should not change with no games")
        XCTAssertEqual(updated.totalGames, player.totalGames, "Total games should not change")
    }

    // MARK: - Confidence Increases With Games

    func testConfidenceIncreasesWithGamesPlayed() {
        var player = Glicko2PlayerRating(rating: 4.0, confidence: 0.0, volatility: 0.5, totalGames: 0)

        // Play several games
        for _ in 0..<10 {
            let result = Glicko2GameResult(opponentRating: 4.0, opponentConfidence: 0.5, score: 1.0)
            player = updatePlayerRating(player: player, gameResults: [result])
        }

        XCTAssertGreaterThan(player.confidence, 0.0, "Confidence should increase after playing multiple games")
    }

    // MARK: - Team Rating

    func testTeamRatingIsAverage() {
        let teamRating = calculateTeamRating(player1Rating: 3.0, player2Rating: 5.0)
        XCTAssertEqual(teamRating, 4.0, accuracy: 0.01)
    }

    func testTeamRatingEqualPlayers() {
        let teamRating = calculateTeamRating(player1Rating: 4.0, player2Rating: 4.0)
        XCTAssertEqual(teamRating, 4.0, accuracy: 0.01)
    }

    // MARK: - Team Confidence

    func testTeamConfidenceIsAverage() {
        let teamConfidence = calculateTeamConfidence(player1Confidence: 0.2, player2Confidence: 0.8)
        XCTAssertEqual(teamConfidence, 0.5, accuracy: 0.01)
    }

    // MARK: - Game Result Score Calculation

    func testGameResultScoreWin() {
        let score = calculateGameResultScore(team1Scores: [11, 11], team2Scores: [5, 7], isTeam1Player: true)
        XCTAssertEqual(score, 1.0, accuracy: 0.01, "Team 1 wins both games, score should be 1.0")
    }

    func testGameResultScoreLoss() {
        let score = calculateGameResultScore(team1Scores: [11, 11], team2Scores: [5, 7], isTeam1Player: false)
        XCTAssertEqual(score, 0.0, accuracy: 0.01, "Team 2 loses both games, score should be 0.0")
    }

    func testGameResultScoreDraw() {
        let score = calculateGameResultScore(team1Scores: [11, 5], team2Scores: [5, 11], isTeam1Player: true)
        XCTAssertEqual(score, 0.5, accuracy: 0.01, "Split games should produce 0.5")
    }

    func testGameResultScoreMismatchedArrays() {
        let score = calculateGameResultScore(team1Scores: [11, 11], team2Scores: [5], isTeam1Player: true)
        XCTAssertEqual(score, 0.5, accuracy: 0.01, "Mismatched arrays default to 0.5")
    }

    // MARK: - Edge Cases

    func testExtremeRatingDifference() {
        let player = Glicko2PlayerRating(rating: 1.0, confidence: 0.5, volatility: 0.5, totalGames: 10)
        let results = [Glicko2GameResult(opponentRating: 7.0, opponentConfidence: 0.5, score: 1.0)]

        let updated = updatePlayerRating(player: player, gameResults: results)
        XCTAssertGreaterThan(updated.rating, player.rating, "Rating should increase significantly after beating much higher opponent")
    }

    func testMinimumConfidenceNewPlayer() {
        let player = Glicko2PlayerRating(rating: 4.0, confidence: 0.0, volatility: 1.0, totalGames: 0)
        let results = [Glicko2GameResult(opponentRating: 4.0, opponentConfidence: 0.5, score: 1.0)]

        let updated = updatePlayerRating(player: player, gameResults: results)
        XCTAssertGreaterThan(updated.confidence, 0.0, "Confidence should increase from 0 after a game")
        XCTAssertEqual(updated.totalGames, 1)
    }

    func testTotalGamesIncrement() {
        let player = Glicko2PlayerRating(rating: 4.0, confidence: 0.5, volatility: 0.5, totalGames: 5)
        let results = [
            Glicko2GameResult(opponentRating: 4.0, opponentConfidence: 0.5, score: 1.0),
            Glicko2GameResult(opponentRating: 3.5, opponentConfidence: 0.5, score: 0.0)
        ]

        let updated = updatePlayerRating(player: player, gameResults: results)
        XCTAssertEqual(updated.totalGames, 7, "Total games should increment by number of results")
    }
}
