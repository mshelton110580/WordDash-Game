import Foundation

// MARK: - PersistenceManager

class PersistenceManager {

    static let shared = PersistenceManager()

    private let progressKey = "WordDash_PlayerProgress"

    private init() {}

    // MARK: - Save

    func saveProgress(_ progress: PlayerProgress) {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(progress)
            UserDefaults.standard.set(data, forKey: progressKey)
            UserDefaults.standard.synchronize()
        } catch {
            print("PersistenceManager: Failed to save progress: \(error)")
        }
    }

    // MARK: - Load

    func loadProgress() -> PlayerProgress {
        guard let data = UserDefaults.standard.data(forKey: progressKey) else {
            return PlayerProgress()
        }
        do {
            let decoder = JSONDecoder()
            let progress = try decoder.decode(PlayerProgress.self, from: data)
            return progress
        } catch {
            print("PersistenceManager: Failed to load progress: \(error)")
            return PlayerProgress()
        }
    }

    // MARK: - Reset

    func resetProgress() {
        let fresh = PlayerProgress()
        saveProgress(fresh)
    }

    // MARK: - Convenience

    func updateLevelProgress(level: Int, stars: Int, score: Int, completed: Bool) {
        var progress = loadProgress()
        var levelProg = progress.levelProgress[level] ?? LevelProgress()

        levelProg.stars = max(levelProg.stars, stars)
        levelProg.bestScore = max(levelProg.bestScore, score)

        if completed {
            levelProg.completed = true
            if level + 1 > progress.highestUnlockedLevel {
                progress.highestUnlockedLevel = level + 1
            }
        }

        progress.levelProgress[level] = levelProg
        saveProgress(progress)
    }

    func updatePowerUpInventory(_ inventory: PowerUpInventory) {
        var progress = loadProgress()
        progress.powerUpInventory = inventory
        saveProgress(progress)
    }

    // MARK: - Stats

    func loadStats() -> GameStats {
        return loadProgress().stats
    }

    func saveStats(_ stats: GameStats) {
        var progress = loadProgress()
        progress.stats = stats
        saveProgress(progress)
    }

    /// Update stats after a level is completed.
    func updateStatsOnLevelComplete(
        levelNumber: Int,
        wordsFound: Int,
        score: Int,
        stars: Int,
        maxStreak: Double,
        maxCascade: Int,
        timeRemaining: Int,
        coinsEarned: Int,
        longestWord: String
    ) {
        var progress = loadProgress()
        var stats = progress.stats

        stats.totalWordsFound += wordsFound
        stats.totalScore += score
        stats.levelsCompleted += 1
        stats.sessionsPlayed += 1
        stats.totalCoinsEarned += coinsEarned

        if maxStreak > stats.bestStreak { stats.bestStreak = maxStreak }
        if maxCascade > stats.bestCascade { stats.bestCascade = maxCascade }
        if longestWord.count > stats.longestWord.count { stats.longestWord = longestWord }

        // Per-level bests
        let prevTime = stats.levelBestTimes[levelNumber] ?? -1
        if timeRemaining > prevTime { stats.levelBestTimes[levelNumber] = timeRemaining }
        let prevScore = stats.levelBestScores[levelNumber] ?? 0
        if score > prevScore { stats.levelBestScores[levelNumber] = score }
        let prevStars = stats.levelStars[levelNumber] ?? 0
        if stars > prevStars { stats.levelStars[levelNumber] = stars }

        // Last played date
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        stats.lastPlayedDate = formatter.string(from: Date())

        progress.stats = stats
        saveProgress(progress)
    }

    // MARK: - Reset

    func resetStats() {
        var progress = loadProgress()
        progress.stats = GameStats()
        saveProgress(progress)
    }
}
