import Foundation

// MARK: - LevelProgress

struct LevelProgress: Codable {
    var stars: Int = 0
    var bestScore: Int = 0
    var completed: Bool = false
}

// MARK: - PowerUpInventory

struct PowerUpInventory: Codable {
    var hintCount: Int = 3
    var bombCount: Int = 2
    var laserCount: Int = 2
    var crossLaserCount: Int = 1
    var mineCount: Int = 1
    var linkCount: Int = 0

    subscript(_ key: String) -> Int? {
        get {
            switch key {
            case "hint": return hintCount
            case "bomb": return bombCount
            case "laser": return laserCount
            case "crossLaser": return crossLaserCount
            case "mine": return mineCount
            case "link": return linkCount
            default: return nil
            }
        }
        set {
            guard let value = newValue else { return }
            switch key {
            case "hint": hintCount = value
            case "bomb": bombCount = value
            case "laser": laserCount = value
            case "crossLaser": crossLaserCount = value
            case "mine": mineCount = value
            case "link": linkCount = value
            default: break
            }
        }
    }
}


// MARK: - GameStats

struct GameStats: Codable {
    var totalWordsFound: Int = 0
    var totalScore: Int = 0
    var levelsCompleted: Int = 0
    var bestStreak: Double = 1.0
    var bestCascade: Int = 0
    var longestWord: String = ""
    var totalCoinsEarned: Int = 0
    var levelBestTimes: [Int: Int] = [:]   // level → seconds remaining
    var levelBestScores: [Int: Int] = [:]  // level → best score
    var levelStars: [Int: Int] = [:]       // level → stars (1–3)
    var sessionsPlayed: Int = 0
    var lastPlayedDate: String = ""
}

// MARK: - PlayerProgress

struct PlayerProgress: Codable {
    var highestUnlockedLevel: Int = 1
    var levelProgress: [Int: LevelProgress] = [:]
    var powerUpInventory: PowerUpInventory = PowerUpInventory()
    var soundEnabled: Bool = true
    var hapticsEnabled: Bool = true
    var stats: GameStats = GameStats()
}
