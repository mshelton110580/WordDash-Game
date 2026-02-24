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
}

// MARK: - PlayerProgress

struct PlayerProgress: Codable {
    var highestUnlockedLevel: Int = 1
    var levelProgress: [Int: LevelProgress] = [:]
    var powerUpInventory: PowerUpInventory = PowerUpInventory()
    var soundEnabled: Bool = true
    var hapticsEnabled: Bool = true
}
