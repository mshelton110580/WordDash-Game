import Foundation

// MARK: - GameState

class GameState {
    var currentLevel: Int = 1
    var score: Int = 0
    var movesUsed: Int = 0
    var timeRemaining: TimeInterval = 0
    var timerStarted: Bool = false
    var iceTilesCleared: Int = 0
    var streakMultiplier: Double = 1.0
    var lastWordTime: Date?
    var wordUsageCounts: [String: Int] = [:]
    var cascadeStep: Int = 0
    var isGameOver: Bool = false
    var isLevelComplete: Bool = false
    var wordSubmitCount: Int = 0
    var wordsFound: [String] = []
    var maxStreakReached: Double = 1.0
    var maxCascadeReached: Int = 0
    var continueCount: Int = 0
    var adContinueUsed: Bool = false
    var coinsEarnedThisLevel: Int = 0

    // Power-up inventory
    var hintCount: Int = 3
    var bombCount: Int = 2
    var laserCount: Int = 2
    var crossLaserCount: Int = 1
    var mineCount: Int = 1
    var shuffleCount: Int = 2

    func reset(for config: LevelConfig) {
        score = 0
        movesUsed = 0
        iceTilesCleared = 0
        streakMultiplier = 1.0
        lastWordTime = nil
        wordUsageCounts = [:]
        cascadeStep = 0
        isGameOver = false
        isLevelComplete = false
        timerStarted = false
        wordSubmitCount = 0
        wordsFound = []
        maxStreakReached = 1.0
        maxCascadeReached = 0
        continueCount = 0
        adContinueUsed = false
        coinsEarnedThisLevel = 0

        if config.goalType == .scoreTimed {
            timeRemaining = TimeInterval(config.timeLimitSeconds ?? 60)
        }
    }

    /// Update streak based on time since last word
    func updateStreak() {
        let now = Date()
        if let lastTime = lastWordTime {
            let elapsed = now.timeIntervalSince(lastTime)
            if elapsed <= 4.0 {
                streakMultiplier = min(streakMultiplier + 0.2, 3.0)
                maxStreakReached = max(maxStreakReached, streakMultiplier)
            } else {
                streakMultiplier = 1.0
            }
        }
        lastWordTime = now
    }

    /// Track word usage and return the usage count (1 = first use)
    func trackWordUsage(_ word: String) -> Int {
        let upper = word.uppercased()
        let count = (wordUsageCounts[upper] ?? 0) + 1
        wordUsageCounts[upper] = count
        return count
    }

    /// Get the diminishing multiplier for repeated words
    func diminishingMultiplier(usageCount: Int) -> Double {
        switch usageCount {
        case 1: return 1.0
        case 2: return 0.5
        default: return 0.1
        }
    }
}
