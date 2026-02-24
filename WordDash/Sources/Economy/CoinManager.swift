import Foundation

/// Reason for a coin transaction, used for analytics and UI display.
enum CoinReason: String, Codable {
    case levelBase
    case starBonus
    case streakBonus
    case cascadeBonus
    case efficiencyBonus
    case longWordBonus
    case dailyLogin
    case dailyChallenge
    case adReward
    case storePurchase
    case continueSpend
    case levelReward
}

/// Notification posted when coin balance changes.
extension Notification.Name {
    static let coinBalanceChanged = Notification.Name("coinBalanceChanged")
}

/// Manages the player's coin balance with persistence via UserDefaults.
final class CoinManager {
    static let shared = CoinManager()

    private let balanceKey = "worddash_coin_balance"
    private let historyKey = "worddash_coin_history"

    private(set) var balance: Int {
        didSet {
            UserDefaults.standard.set(balance, forKey: balanceKey)
            NotificationCenter.default.post(name: .coinBalanceChanged, object: nil, userInfo: ["balance": balance])
        }
    }

    private init() {
        let saved = UserDefaults.standard.integer(forKey: balanceKey)
        if saved == 0 && !UserDefaults.standard.bool(forKey: "worddash_coin_initialized") {
            self.balance = GameEconomyConfig.startingCoins
            UserDefaults.standard.set(true, forKey: "worddash_coin_initialized")
            UserDefaults.standard.set(balance, forKey: balanceKey)
        } else {
            self.balance = saved
        }
    }

    func canAfford(_ amount: Int) -> Bool {
        return balance >= amount
    }

    @discardableResult
    func addCoins(_ amount: Int, reason: CoinReason) -> Int {
        guard amount > 0 else { return balance }
        balance += amount
        return balance
    }

    @discardableResult
    func spendCoins(_ amount: Int, reason: CoinReason) -> Bool {
        guard canAfford(amount) else { return false }
        balance -= amount
        return true
    }
}
