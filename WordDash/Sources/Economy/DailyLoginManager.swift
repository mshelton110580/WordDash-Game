import Foundation

/// Manages daily login reward streaks.
/// Day 1-7 rewards escalate; missing a day resets the streak.
final class DailyLoginManager {
    static let shared = DailyLoginManager()

    private let lastLoginKey = "worddash_last_login_date"
    private let streakDayKey = "worddash_login_streak_day"

    private init() {}

    /// Check if the player can claim a daily reward today.
    /// Returns (canClaim: Bool, day: Int, amount: Int).
    func checkDailyReward() -> (canClaim: Bool, day: Int, amount: Int) {
        let today = Calendar.current.startOfDay(for: Date())
        let lastLogin = UserDefaults.standard.object(forKey: lastLoginKey) as? Date
        let currentDay = UserDefaults.standard.integer(forKey: streakDayKey)

        if let last = lastLogin {
            let lastDay = Calendar.current.startOfDay(for: last)
            if lastDay == today {
                // Already claimed today
                return (false, currentDay, 0)
            }
            let daysBetween = Calendar.current.dateComponents([.day], from: lastDay, to: today).day ?? 0
            if daysBetween == 1 {
                // Consecutive day
                let nextDay = min(currentDay + 1, GameEconomyConfig.dailyRewards.count)
                let amount = GameEconomyConfig.dailyRewards[nextDay - 1]
                return (true, nextDay, amount)
            } else {
                // Missed a day — reset streak
                let amount = GameEconomyConfig.dailyRewards[0]
                return (true, 1, amount)
            }
        } else {
            // First ever login
            let amount = GameEconomyConfig.dailyRewards[0]
            return (true, 1, amount)
        }
    }

    /// Claim the daily reward. Returns the coin amount awarded (0 if already claimed).
    @discardableResult
    func claimDailyReward() -> Int {
        let result = checkDailyReward()
        guard result.canClaim else { return 0 }

        let today = Calendar.current.startOfDay(for: Date())
        UserDefaults.standard.set(today, forKey: lastLoginKey)
        UserDefaults.standard.set(result.day, forKey: streakDayKey)

        CoinManager.shared.addCoins(result.amount, reason: .dailyLogin)
        return result.amount
    }
}
