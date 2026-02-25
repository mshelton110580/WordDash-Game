import XCTest
@testable import WordDash

// MARK: - Tier Selection Tests

class TierSelectionTests: XCTestCase {

    // MARK: - Small Tier

    func testSmallTierDefault() {
        let tier = ExplosionConfig.selectTier(
            points: 50,
            coins: 0,
            cause: .normalClear,
            streakMultiplier: 1.0
        )
        XCTAssertEqual(tier, .small, "Low points + normalClear should be SMALL")
    }

    func testSmallTierBelowMediumThreshold() {
        let tier = ExplosionConfig.selectTier(
            points: 399,
            coins: 0,
            cause: .normalClear,
            streakMultiplier: 1.0
        )
        XCTAssertEqual(tier, .small, "399 pts is just below medium threshold, should be SMALL")
    }

    func testSmallTierZeroPoints() {
        let tier = ExplosionConfig.selectTier(points: 0, coins: 0, cause: .normalClear)
        XCTAssertEqual(tier, .small)
    }

    // MARK: - Medium Tier — Points

    func testMediumTierAtPointsThreshold() {
        let tier = ExplosionConfig.selectTier(
            points: ExplosionConfig.mediumPointsThreshold,
            coins: 0,
            cause: .normalClear,
            streakMultiplier: 1.0
        )
        XCTAssertEqual(tier, .medium, "Points == mediumThreshold should be MEDIUM")
    }

    func testMediumTierAbovePointsThreshold() {
        let tier = ExplosionConfig.selectTier(
            points: 800,
            coins: 0,
            cause: .normalClear,
            streakMultiplier: 1.0
        )
        XCTAssertEqual(tier, .medium, "800 pts > mediumThreshold should be MEDIUM")
    }

    func testMediumTierJustBelowBigPointsThreshold() {
        let tier = ExplosionConfig.selectTier(
            points: ExplosionConfig.bigPointsThreshold - 1,
            coins: 0,
            cause: .normalClear,
            streakMultiplier: 1.0
        )
        XCTAssertEqual(tier, .medium, "One below bigThreshold should be MEDIUM not BIG")
    }

    // MARK: - Medium Tier — Cause

    func testMediumTierBombCause() {
        let tier = ExplosionConfig.selectTier(points: 10, coins: 0, cause: .bomb)
        XCTAssertEqual(tier, .medium, "Bomb cause should always be at least MEDIUM")
    }

    func testMediumTierLaserCause() {
        let tier = ExplosionConfig.selectTier(points: 10, coins: 0, cause: .laser)
        XCTAssertEqual(tier, .medium, "Laser cause should always be at least MEDIUM")
    }

    func testMediumTierCrossLaserCause() {
        let tier = ExplosionConfig.selectTier(points: 10, coins: 0, cause: .crossLaser)
        XCTAssertEqual(tier, .medium, "CrossLaser cause should always be at least MEDIUM")
    }

    func testMediumTierMineCause() {
        let tier = ExplosionConfig.selectTier(points: 10, coins: 0, cause: .mine)
        XCTAssertEqual(tier, .medium, "Mine cause should always be at least MEDIUM")
    }

    // MARK: - Big Tier — Points

    func testBigTierAtPointsThreshold() {
        let tier = ExplosionConfig.selectTier(
            points: ExplosionConfig.bigPointsThreshold,
            coins: 0,
            cause: .normalClear,
            streakMultiplier: 1.0
        )
        XCTAssertEqual(tier, .big, "Points == bigThreshold should be BIG")
    }

    func testBigTierWellAbovePointsThreshold() {
        let tier = ExplosionConfig.selectTier(
            points: 3000,
            coins: 0,
            cause: .normalClear,
            streakMultiplier: 1.0
        )
        XCTAssertEqual(tier, .big, "3000 pts should be BIG")
    }

    // MARK: - Big Tier — Coins

    func testBigTierAtCoinsThreshold() {
        let tier = ExplosionConfig.selectTier(
            points: 10,
            coins: ExplosionConfig.bigCoinsThreshold,
            cause: .normalClear,
            streakMultiplier: 1.0
        )
        XCTAssertEqual(tier, .big, "coins == bigCoinsThreshold should be BIG")
    }

    func testBigTierAboveCoinsThreshold() {
        let tier = ExplosionConfig.selectTier(points: 10, coins: 10, cause: .normalClear)
        XCTAssertEqual(tier, .big, "10 coins should force BIG")
    }

    func testBelowCoinThresholdNotForcesBig() {
        let tier = ExplosionConfig.selectTier(
            points: 10,
            coins: ExplosionConfig.bigCoinsThreshold - 1,
            cause: .normalClear,
            streakMultiplier: 1.0
        )
        // coins = 4 with low points + normalClear = small
        XCTAssertEqual(tier, .small, "Just below coin threshold with low points should be SMALL")
    }

    // MARK: - Big Tier — Chain Resolve

    func testBigTierChainResolve() {
        let tier = ExplosionConfig.selectTier(
            points: 10,
            coins: 0,
            cause: .chainResolve,
            streakMultiplier: 1.0
        )
        XCTAssertEqual(tier, .big, "chainResolve cause should always be BIG")
    }

    func testBigTierChainResolveWithLowPoints() {
        // Even tiny points + chainResolve = BIG
        let tier = ExplosionConfig.selectTier(points: 0, coins: 0, cause: .chainResolve)
        XCTAssertEqual(tier, .big)
    }

    // MARK: - Big Tier — Streak Multiplier

    func testBigTierAtStreakThreshold() {
        let tier = ExplosionConfig.selectTier(
            points: 10,
            coins: 0,
            cause: .normalClear,
            streakMultiplier: ExplosionConfig.bigStreakThreshold
        )
        XCTAssertEqual(tier, .big, "streakMultiplier == bigStreakThreshold should be BIG")
    }

    func testBigTierAboveStreakThreshold() {
        let tier = ExplosionConfig.selectTier(
            points: 10,
            coins: 0,
            cause: .normalClear,
            streakMultiplier: 10.0
        )
        XCTAssertEqual(tier, .big, "Very high streak should be BIG")
    }

    func testBelowStreakThresholdNotForcesBig() {
        let tier = ExplosionConfig.selectTier(
            points: 10,
            coins: 0,
            cause: .normalClear,
            streakMultiplier: ExplosionConfig.bigStreakThreshold - 0.1
        )
        // Below both big points and streak thresholds with normalClear = small
        XCTAssertEqual(tier, .small)
    }

    // MARK: - Priority: Big overrides Medium

    func testBigOverridesMediumCauseWhenPointsHigh() {
        // bomb cause would normally be medium, but big points force big
        let tier = ExplosionConfig.selectTier(
            points: ExplosionConfig.bigPointsThreshold,
            coins: 0,
            cause: .bomb,
            streakMultiplier: 1.0
        )
        XCTAssertEqual(tier, .big, "High points + bomb cause should be BIG, not MEDIUM")
    }

    func testBigOverridesMediumViaCoinThreshold() {
        let tier = ExplosionConfig.selectTier(
            points: ExplosionConfig.mediumPointsThreshold,
            coins: ExplosionConfig.bigCoinsThreshold,
            cause: .bomb
        )
        XCTAssertEqual(tier, .big, "Coin threshold should push bomb+medium-points to BIG")
    }

    // MARK: - Exact Boundary Values

    func testPointsBoundarySmallToMedium() {
        let small = ExplosionConfig.selectTier(points: 399, coins: 0, cause: .normalClear)
        let medium = ExplosionConfig.selectTier(points: 400, coins: 0, cause: .normalClear)
        XCTAssertEqual(small, .small)
        XCTAssertEqual(medium, .medium)
    }

    func testPointsBoundaryMediumToBig() {
        let medium = ExplosionConfig.selectTier(points: 1499, coins: 0, cause: .normalClear)
        let big = ExplosionConfig.selectTier(points: 1500, coins: 0, cause: .normalClear)
        XCTAssertEqual(medium, .medium)
        XCTAssertEqual(big, .big)
    }

    func testCoinsBoundarySmallToBig() {
        // coins = 4 → small (below bigCoinsThreshold=5), coins = 5 → big
        let small = ExplosionConfig.selectTier(points: 10, coins: 4, cause: .normalClear)
        let big   = ExplosionConfig.selectTier(points: 10, coins: 5, cause: .normalClear)
        XCTAssertEqual(small, .small)
        XCTAssertEqual(big, .big)
    }

    // MARK: - Cause Color Mapping

    func testEffectColorNormalClear() {
        let color = ExplosionManager.shared.effectColor(for: .normalClear)
        // Warm wood: R~0.83
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        XCTAssertGreaterThan(r, 0.7, "Normal clear should have warm wood color (high R)")
    }

    func testEffectColorBomb() {
        let color = ExplosionManager.shared.effectColor(for: .bomb)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        XCTAssertEqual(r, 1.0, accuracy: 0.01, "Bomb should have full-red orange color")
    }

    func testEffectColorChainResolve() {
        let color = ExplosionManager.shared.effectColor(for: .chainResolve)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        XCTAssertEqual(r, 1.0, accuracy: 0.01, "Chain resolve should be gold (high R)")
        XCTAssertGreaterThan(g, 0.7, "Chain resolve gold should have high G")
    }

    // MARK: - Cause Conversion from SpecialTileType

    func testCauseFromNilSpecialType() {
        let cause = ExplosionManager.shared.cause(for: nil)
        XCTAssertEqual(cause, .normalClear)
    }

    func testCauseFromBombTile() {
        let cause = ExplosionManager.shared.cause(for: .bomb)
        XCTAssertEqual(cause, .bomb)
    }

    func testCauseFromLaserTile() {
        let cause = ExplosionManager.shared.cause(for: .laser)
        XCTAssertEqual(cause, .laser)
    }

    func testCauseFromCrossLaserTile() {
        let cause = ExplosionManager.shared.cause(for: .crossLaser)
        XCTAssertEqual(cause, .crossLaser)
    }

    func testCauseFromMineTile() {
        let cause = ExplosionManager.shared.cause(for: .mine)
        XCTAssertEqual(cause, .mine)
    }

    func testCauseFromWildcardTile() {
        // Wildcards map to chainResolve for gold effect
        let cause = ExplosionManager.shared.cause(for: .wildcard)
        XCTAssertEqual(cause, .chainResolve)
    }

    // MARK: - Config Threshold Sanity

    func testThresholdsAreOrdered() {
        // medium threshold must be < big threshold
        XCTAssertLessThan(
            ExplosionConfig.mediumPointsThreshold,
            ExplosionConfig.bigPointsThreshold,
            "Medium points threshold should be below big threshold"
        )
    }

    func testBigPointsThresholdPositive() {
        XCTAssertGreaterThan(ExplosionConfig.bigPointsThreshold, 0)
    }

    func testBigCoinsThresholdPositive() {
        XCTAssertGreaterThan(ExplosionConfig.bigCoinsThreshold, 0)
    }

    func testParticleCapsPositive() {
        XCTAssertGreaterThan(ExplosionConfig.maxActiveFragments, 0)
        XCTAssertGreaterThan(ExplosionConfig.maxSparks, 0)
        XCTAssertGreaterThan(ExplosionConfig.maxDebris, 0)
    }

    func testParticleCapsWithinReasonableRange() {
        XCTAssertLessThanOrEqual(ExplosionConfig.maxActiveFragments, 100,
            "Fragment cap should be performance-safe (<= 100)")
        XCTAssertLessThanOrEqual(ExplosionConfig.maxSparks, 100,
            "Spark cap should be performance-safe (<= 100)")
        XCTAssertLessThanOrEqual(ExplosionConfig.maxDebris, 30,
            "Debris cap should be performance-safe (<= 30)")
    }

    // MARK: - Animation Duration Sanity

    func testSmallTierTotalDurationUnder1s() {
        let total = ExplosionConfig.Small.flashFadeDuration +
                    ExplosionConfig.Small.sparkLifetimeMax
        XCTAssertLessThanOrEqual(total, 1.0,
            "Small tier total effect duration should be <= 1.0s (got \(total)s)")
    }

    func testMediumTierTotalDurationUnder1s() {
        let total = ExplosionConfig.Medium.flashFadeDuration +
                    ExplosionConfig.Medium.shockwaveDuration
        XCTAssertLessThanOrEqual(total, 1.0,
            "Medium tier combined flash+ring duration should be <= 1.0s")
    }

    func testBigTierFragmentFlyDurationUnder1_2s() {
        let total = ExplosionConfig.Big.fragmentBurstDuration +
                    ExplosionConfig.Big.fragmentFlyMaxDuration
        XCTAssertLessThanOrEqual(total, 1.2,
            "Big tier burst + fly should be <= 1.2s (got \(total)s)")
    }

    func testBigScoreCountDurationUnder1s() {
        XCTAssertLessThanOrEqual(ExplosionConfig.Big.scoreCountDuration, 1.0,
            "Big tier score count-up should be <= 1.0s")
    }
}

// MARK: - ExplosionCause Equatable conformance for tests

extension ExplosionCause: Equatable {
    public static func == (lhs: ExplosionCause, rhs: ExplosionCause) -> Bool {
        switch (lhs, rhs) {
        case (.normalClear, .normalClear),
             (.chainResolve, .chainResolve),
             (.bomb, .bomb),
             (.laser, .laser),
             (.crossLaser, .crossLaser),
             (.mine, .mine):
            return true
        default:
            return false
        }
    }
}

// MARK: - ExplosionTier Equatable conformance for tests

extension ExplosionTier: Equatable {
    public static func == (lhs: ExplosionTier, rhs: ExplosionTier) -> Bool {
        switch (lhs, rhs) {
        case (.small, .small), (.medium, .medium), (.big, .big): return true
        default: return false
        }
    }
}
