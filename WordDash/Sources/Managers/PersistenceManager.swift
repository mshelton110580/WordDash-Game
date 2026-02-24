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
}
