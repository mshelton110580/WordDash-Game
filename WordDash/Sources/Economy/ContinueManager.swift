import Foundation

/// Manages the continue system for failed levels.
/// Escalating costs: 200 → 300 → 400 coins, max 3 per session.
final class ContinueManager {
    private var continueCount: Int = 0
    private var adUsed: Bool = false

    /// Reset for a new level session.
    func resetForNewLevel() {
        continueCount = 0
        adUsed = false
    }

    /// Whether the player can continue (hasn't hit max).
    var canContinue: Bool {
        return continueCount < GameEconomyConfig.maxContinuesPerSession
    }

    /// The current cost for the next continue.
    var currentCost: Int {
        guard canContinue else { return 0 }
        return GameEconomyConfig.continueCosts[continueCount]
    }

    /// Whether the player can afford to continue.
    var canAffordContinue: Bool {
        return CoinManager.shared.canAfford(currentCost)
    }

    /// Whether the ad continue is available.
    var canUseAdContinue: Bool {
        return !adUsed && canContinue
    }

    /// Attempt to continue with coins. Returns true if successful.
    @discardableResult
    func continueWithCoins() -> Bool {
        guard canContinue else { return false }
        let cost = currentCost
        guard CoinManager.shared.spendCoins(cost, reason: .continueSpend) else { return false }
        continueCount += 1
        return true
    }

    /// Continue with an ad (stub). Returns true if successful.
    @discardableResult
    func continueWithAd() -> Bool {
        guard canUseAdContinue else { return false }
        adUsed = true
        continueCount += 1
        return true
    }

    /// The bonus granted by a continue.
    /// For timed levels: +15 seconds. For move-based: +5 moves.
    func continueBonus(for goalType: GoalType) -> (time: Int, moves: Int) {
        switch goalType {
        case .scoreTimed:
            return (GameEconomyConfig.continueTimedBonus, 0)
        case .clearIceMoves:
            return (0, GameEconomyConfig.continueMoveBonus)
        }
    }
}
