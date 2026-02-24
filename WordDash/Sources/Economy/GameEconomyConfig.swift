import Foundation

/// Central configuration for the entire coin economy.
/// No hardcoded economy values elsewhere — everything references this struct.
struct GameEconomyConfig {
    // MARK: - Starting Balance
    static let startingCoins: Int = 500

    // MARK: - Level Completion Rewards
    static let baseCoinsPerLevel: Int = 5 // multiplied by levelNumber
    static let starBonus: [Int: Int] = [1: 10, 2: 20, 3: 40]

    // Word length bonuses (coins per occurrence)
    static let longWordBonus: [(minLength: Int, coins: Int)] = [
        (8, 6), // 8+ letters
        (7, 4), // 7 letters
        (6, 2), // 6 letters
    ]

    // Streak bonuses
    static let streakBonus: [(minStreak: Double, coins: Int)] = [
        (3.0, 20),
        (2.5, 10),
        (2.0, 5),
    ]

    // Cascade bonuses
    static let cascadeBonus: [(minCascade: Int, coins: Int)] = [
        (3, 10),
        (2, 5),
    ]

    // Efficiency bonuses
    static let efficiencyTimeThreshold: Double = 0.20 // 20% time remaining
    static let efficiencyMoveThreshold: Int = 3 // 3+ moves remaining
    static let efficiencyBonus: Int = 10

    // Anti-farming
    static let replayBaseMultiplier: Double = 0.5
    static let replayPerformanceCap: Int = 50
    static let maxCoinsPerLevel: Int = 500

    // MARK: - Store Prices
    static let storePrices: [String: Int] = [
        "hint": 50,
        "bomb": 75,
        "laser": 100,
        "crossLaser": 150,
        "mine": 125,
    ]

    // MARK: - Continue System
    static let continueCosts: [Int] = [200, 300, 400] // escalating per session
    static let maxContinuesPerSession: Int = 3
    static let continueTimedBonus: Int = 15 // seconds added
    static let continueMoveBonus: Int = 5 // moves added

    // MARK: - Daily Login Rewards
    static let dailyRewards: [Int] = [25, 35, 50, 75, 100, 125, 150] // Day 1-7
}
