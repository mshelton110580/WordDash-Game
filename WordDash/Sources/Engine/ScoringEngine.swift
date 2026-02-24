import Foundation

// MARK: - ScoreResult

struct ScoreResult {
    let baseLetterScore: Int
    let lengthMultiplier: Double
    let streakMultiplier: Double
    let diminishingMultiplier: Double
    let cascadeBonus: Int
    let totalScore: Int
}

// MARK: - ScoringEngine

class ScoringEngine {

    static let shared = ScoringEngine()

    private init() {}

    // MARK: - Letter Score

    func letterValue(for character: Character) -> Int {
        return GameConstants.letterValues[Character(character.uppercased())] ?? 0
    }

    /// Base letter score for a word — applies letterMultiplier (2x/3x) per tile
    func baseLetterScore(for tiles: [TileModel]) -> Int {
        var total = 0
        for tile in tiles {
            if tile.specialType == .wildcard {
                total += GameConstants.wildcardBasePoints
            } else {
                let baseVal = letterValue(for: tile.letter)
                total += baseVal * tile.letterMultiplier
            }
        }
        return total
    }

    /// Explosion score for tiles destroyed by power-ups — NO letterMultiplier applied
    func explosionScore(for tiles: [TileModel]) -> Int {
        var total = 0
        for tile in tiles {
            if tile.specialType == .wildcard {
                total += GameConstants.wildcardBasePoints
            } else {
                total += letterValue(for: tile.letter)
            }
        }
        return total
    }

    // MARK: - Full Score Calculation

    func calculateScore(tiles: [TileModel], gameState: GameState) -> ScoreResult {
        let base = baseLetterScore(for: tiles)
        let lengthMult = GameConstants.lengthMultiplier(for: tiles.count)

        // Update streak
        gameState.updateStreak()
        let streakMult = gameState.streakMultiplier

        // Track word usage
        let word = String(tiles.map { $0.letter })
        let usageCount = gameState.trackWordUsage(word)
        let diminishing = gameState.diminishingMultiplier(usageCount: usageCount)

        // Calculate word score
        let wordScore = Double(base) * lengthMult * streakMult * diminishing
        let roundedWordScore = Int(round(wordScore))

        // Cascade bonus (applied separately after initial clear)
        let cascade = GameConstants.cascadeBonus(step: gameState.cascadeStep)

        let total = roundedWordScore + cascade

        return ScoreResult(
            baseLetterScore: base,
            lengthMultiplier: lengthMult,
            streakMultiplier: streakMult,
            diminishingMultiplier: diminishing,
            cascadeBonus: cascade,
            totalScore: max(total, 0)
        )
    }

    // MARK: - Cascade-only Score (for chain reactions)

    func cascadeScore(step: Int) -> Int {
        return GameConstants.cascadeBonus(step: step)
    }

    // MARK: - Dual-Bomb Board Explosion Bonus

    func boardExplosionBonus(step: Int) -> Int {
        return GameConstants.cascadeBonus(step: step) * 3
    }
}
