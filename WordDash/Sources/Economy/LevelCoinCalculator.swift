import Foundation

/// A single line item in the coin breakdown.
struct CoinTransaction {
    let label: String
    let amount: Int
}

/// Full breakdown of coins earned from completing a level.
struct CoinBreakdown {
    let transactions: [CoinTransaction]
    let total: Int
}

/// Calculates coins earned from a completed level based on performance.
struct LevelCoinCalculator {

    static func calculate(
        levelNumber: Int,
        stars: Int,
        wordsFound: [String],
        maxStreakReached: Double,
        maxCascadeReached: Int,
        timeRemaining: Int,
        totalTime: Int,
        movesRemaining: Int,
        goalType: GoalType,
        isReplay: Bool
    ) -> CoinBreakdown {
        var transactions: [CoinTransaction] = []

        // 1. Base coins
        var baseCoinAmount = levelNumber * GameEconomyConfig.baseCoinsPerLevel
        if isReplay {
            baseCoinAmount = Int(Double(baseCoinAmount) * GameEconomyConfig.replayBaseMultiplier)
        }
        transactions.append(CoinTransaction(label: isReplay ? "Base (replay 50%)" : "Base", amount: baseCoinAmount))

        // 2. Star bonus (not for replays)
        if !isReplay, let bonus = GameEconomyConfig.starBonus[stars] {
            transactions.append(CoinTransaction(label: "\(stars)★ Bonus", amount: bonus))
        }

        // 3. Long word bonuses
        var longWordCoins = 0
        for word in wordsFound {
            for tier in GameEconomyConfig.longWordBonus {
                if word.count >= tier.minLength {
                    longWordCoins += tier.coins
                    break // Only highest tier per word
                }
            }
        }
        if isReplay {
            longWordCoins = min(longWordCoins, GameEconomyConfig.replayPerformanceCap)
        }
        if longWordCoins > 0 {
            transactions.append(CoinTransaction(label: "Long Words", amount: longWordCoins))
        }

        // 4. Streak bonus
        var streakCoins = 0
        for tier in GameEconomyConfig.streakBonus {
            if maxStreakReached >= tier.minStreak {
                streakCoins = tier.coins
                break // Highest matching tier
            }
        }
        if isReplay {
            streakCoins = min(streakCoins, GameEconomyConfig.replayPerformanceCap)
        }
        if streakCoins > 0 {
            transactions.append(CoinTransaction(label: "Streak Bonus", amount: streakCoins))
        }

        // 5. Cascade bonus
        var cascadeCoins = 0
        for tier in GameEconomyConfig.cascadeBonus {
            if maxCascadeReached >= tier.minCascade {
                cascadeCoins = tier.coins
                break
            }
        }
        if isReplay {
            cascadeCoins = min(cascadeCoins, GameEconomyConfig.replayPerformanceCap)
        }
        if cascadeCoins > 0 {
            transactions.append(CoinTransaction(label: "Cascade Bonus", amount: cascadeCoins))
        }

        // 6. Efficiency bonus
        var efficiencyCoins = 0
        if goalType == .scoreTimed {
            if totalTime > 0 {
                let ratio = Double(timeRemaining) / Double(totalTime)
                if ratio >= GameEconomyConfig.efficiencyTimeThreshold {
                    efficiencyCoins = GameEconomyConfig.efficiencyBonus
                }
            }
        } else {
            if movesRemaining >= GameEconomyConfig.efficiencyMoveThreshold {
                efficiencyCoins = GameEconomyConfig.efficiencyBonus
            }
        }
        if isReplay {
            efficiencyCoins = min(efficiencyCoins, GameEconomyConfig.replayPerformanceCap)
        }
        if efficiencyCoins > 0 {
            transactions.append(CoinTransaction(label: "Efficiency", amount: efficiencyCoins))
        }

        // Total with cap
        let rawTotal = transactions.reduce(0) { $0 + $1.amount }
        let total = min(rawTotal, GameEconomyConfig.maxCoinsPerLevel)

        return CoinBreakdown(transactions: transactions, total: total)
    }
}
