// Glicko-2 Rating System Implementation
// Adapted for pickleball with skill level 1.0-7.0 scale

const TAU = 0.5; // System volatility constant
const EPSILON = 0.000001; // Convergence tolerance

interface PlayerRating {
  rating: number;        // Skill level (1.0-7.0)
  confidence: number;    // Rating deviation (0.0-1.0)
  volatility: number;    // Rating volatility (starts at 1.0, decreases)
  total_games: number;   // Total games played
}

interface GameResult {
  opponent_rating: number;
  opponent_confidence: number;
  score: number; // 1 for win, 0.5 for tie, 0 for loss
}

// Convert skill level to Glicko-2 scale (1500 +/- 400)
function scaleToGlicko(rating: number): number {
  return 1500 + ((rating - 4.0) * 400 / 3.0);
}

// Convert Glicko-2 scale back to skill level (1.0-7.0)
function scaleFromGlicko(glickoRating: number): number {
  return Math.max(1.0, Math.min(7.0, 4.0 + ((glickoRating - 1500) * 3.0 / 400)));
}

// Convert confidence to Glicko-2 RD scale
function confidenceToRD(confidence: number): number {
  // Confidence 0.0 = RD 350 (high uncertainty)
  // Confidence 1.0 = RD 50 (low uncertainty)
  return 350 - (confidence * 300);
}

// Convert RD back to confidence
function rdToConfidence(rd: number): number {
  return Math.max(0.0, Math.min(1.0, (350 - rd) / 300));
}

// G function from Glicko-2
function g(rd: number): number {
  return 1 / Math.sqrt(1 + (3 * rd * rd) / (Math.PI * Math.PI));
}

// E function from Glicko-2 (expected score)
function expectedScore(rating: number, opponentRating: number, opponentRd: number): number {
  return 1 / (1 + Math.exp(-g(opponentRd) * (rating - opponentRating)));
}

// Calculate variance
function calculateVariance(rating: number, results: Array<{rating: number, rd: number, score: number}>): number {
  let variance = 0;
  for (const result of results) {
    const e = expectedScore(rating, result.rating, result.rd);
    variance += g(result.rd) * g(result.rd) * e * (1 - e);
  }
  return 1 / variance;
}

// Update volatility using Illinois method
function updateVolatility(
  rating: number,
  rd: number,
  volatility: number,
  variance: number,
  delta: number
): number {
  const a = Math.log(volatility * volatility);
  
  function f(x: number): number {
    const ex = Math.exp(x);
    const num = ex * (delta * delta - rd * rd - variance - ex);
    const denom = 2 * Math.pow(rd * rd + variance + ex, 2);
    return num / denom - (x - a) / (TAU * TAU);
  }

  let A = a;
  let B: number;
  
  if (delta * delta > rd * rd + variance) {
    B = Math.log(delta * delta - rd * rd - variance);
  } else {
    let k = 1;
    while (f(a - k * TAU) < 0) {
      k++;
    }
    B = a - k * TAU;
  }

  let fA = f(A);
  let fB = f(B);

  while (Math.abs(B - A) > EPSILON) {
    const C = A + (A - B) * fA / (fB - fA);
    const fC = f(C);
    
    if (fC * fB < 0) {
      A = B;
      fA = fB;
    } else {
      fA = fA / 2;
    }
    
    B = C;
    fB = fC;
  }

  return Math.exp(A / 2);
}

// Main rating update function
export function updatePlayerRating(
  player: PlayerRating,
  gameResults: GameResult[]
): PlayerRating {
  if (gameResults.length === 0) {
    return player;
  }

  // Convert to Glicko-2 scale
  const glickoRating = scaleToGlicko(player.rating);
  const rd = confidenceToRD(player.confidence);
  
  // Prepare results in Glicko-2 format
  const glickoResults = gameResults.map(result => ({
    rating: scaleToGlicko(result.opponent_rating),
    rd: confidenceToRD(result.opponent_confidence),
    score: result.score
  }));

  // Step 1: Calculate variance
  const variance = calculateVariance(glickoRating, glickoResults);

  // Step 2: Calculate delta
  let delta = 0;
  for (const result of glickoResults) {
    const e = expectedScore(glickoRating, result.rating, result.rd);
    delta += g(result.rd) * (result.score - e);
  }
  delta *= variance;

  // Step 3: Update volatility
  const newVolatility = updateVolatility(glickoRating, rd, player.volatility, variance, delta);

  // Step 4: Update rating deviation
  const rdStar = Math.sqrt(rd * rd + newVolatility * newVolatility);
  const newRd = 1 / Math.sqrt(1 / (rdStar * rdStar) + 1 / variance);

  // Step 5: Update rating
  let ratingChange = 0;
  for (const result of glickoResults) {
    const e = expectedScore(glickoRating, result.rating, result.rd);
    ratingChange += g(result.rd) * (result.score - e);
  }
  const newGlickoRating = glickoRating + newRd * newRd * ratingChange;

  // Convert back to our scale and update confidence
  const newRating = scaleFromGlicko(newGlickoRating);
  const newConfidence = rdToConfidence(newRd);
  const newTotalGames = player.total_games + gameResults.length;

  // Boost confidence based on total games played
  const gameBasedConfidence = Math.min(1.0, newTotalGames * 0.02); // 2% confidence per game, capped at 100%
  const finalConfidence = Math.max(newConfidence, gameBasedConfidence);

  return {
    rating: Math.round(newRating * 100) / 100, // Round to 2 decimal places
    confidence: Math.round(finalConfidence * 100) / 100,
    volatility: Math.max(0.05, Math.round(newVolatility * 100) / 100), // Minimum volatility of 0.05
    total_games: newTotalGames
  };
}

// Calculate game result score based on individual game scores
export function calculateGameResultScore(
  team1Scores: number[],
  team2Scores: number[],
  isTeam1Player: boolean
): number {
  if (team1Scores.length !== team2Scores.length) {
    return 0.5; // Default to tie if mismatched
  }

  let team1Wins = 0;
  let team2Wins = 0;
  let totalGames = team1Scores.length;

  for (let i = 0; i < totalGames; i++) {
    if (team1Scores[i] > team2Scores[i]) {
      team1Wins++;
    } else if (team2Scores[i] > team1Scores[i]) {
      team2Wins++;
    }
  }

  // Calculate score based on games won ratio
  const team1Score = team1Wins / totalGames;
  const team2Score = team2Wins / totalGames;

  return isTeam1Player ? team1Score : team2Score;
}

// Calculate average rating for doubles partners
export function calculateTeamRating(player1Rating: number, player2Rating: number): number {
  return (player1Rating + player2Rating) / 2;
}

// Calculate average confidence for doubles partners
export function calculateTeamConfidence(player1Confidence: number, player2Confidence: number): number {
  return (player1Confidence + player2Confidence) / 2;
}