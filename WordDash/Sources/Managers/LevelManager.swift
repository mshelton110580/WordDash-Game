import Foundation

// MARK: - LevelManager

class LevelManager {

    static let shared = LevelManager()

    private var levels: [Int: LevelConfig] = [:]

    private init() {}

    // MARK: - Loading

    func loadAllLevels() {
        for i in 1...10 {
            if let config = loadLevel(number: i) {
                levels[i] = config
            }
        }
        print("LevelManager: Loaded \(levels.count) levels")
    }

    func loadLevel(number: Int) -> LevelConfig? {
        let filename = "level_\(number)"
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            print("LevelManager: Could not find \(filename).json")
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let config = try decoder.decode(LevelConfig.self, from: data)
            return config
        } catch {
            print("LevelManager: Error loading level \(number): \(error)")
            return nil
        }
    }

    // MARK: - Access

    func config(for level: Int) -> LevelConfig? {
        return levels[level]
    }

    var totalLevels: Int {
        return levels.count
    }

    // MARK: - Star Calculation

    func starsEarned(for level: Int, score: Int) -> Int {
        guard let config = levels[level] else { return 0 }
        if score >= config.starThresholds.threeStar { return 3 }
        if score >= config.starThresholds.twoStar { return 2 }
        if score >= config.starThresholds.oneStar { return 1 }
        return 0
    }

    func starsEarnedForIceLevel(for level: Int, iceCleared: Int, movesUsed: Int) -> Int {
        guard let config = levels[level] else { return 0 }
        guard let target = config.iceTilesToClearTarget else { return 0 }
        guard let moveLimit = config.moveLimit else { return 0 }

        if iceCleared < target { return 0 }

        let efficiency = Double(movesUsed) / Double(moveLimit)
        if efficiency <= 0.5 { return 3 }
        if efficiency <= 0.75 { return 2 }
        return 1
    }
}
