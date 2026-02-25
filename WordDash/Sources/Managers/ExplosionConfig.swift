import Foundation
import SpriteKit

// MARK: - Explosion Tier

enum ExplosionTier {
    case small
    case medium
    case big
}

// MARK: - Explosion Cause

enum ExplosionCause {
    case normalClear
    case chainResolve
    case bomb
    case laser
    case crossLaser
    case mine
}

// MARK: - HUD Targets

struct HUDTargets {
    let scoreLabelPosition: CGPoint
    let coinLabelPosition: CGPoint
}

// MARK: - ExplosionConfig

/// Central configuration for all explosion/reward feedback parameters.
/// Adjust values here to tune feel without touching manager logic.
struct ExplosionConfig {

    // MARK: - Tier Selection Thresholds

    /// Points threshold at or above which a BIG tier is forced
    static let bigPointsThreshold: Int = 1500
    /// Coins threshold at or above which a BIG tier is forced
    static let bigCoinsThreshold: Int = 5
    /// Streak multiplier threshold at or above which a BIG tier is forced
    static let bigStreakThreshold: Double = 6.0

    /// Points threshold at or above which a MEDIUM tier is selected (when not BIG)
    static let mediumPointsThreshold: Int = 400

    // MARK: - Particle Caps

    static let maxActiveFragments: Int = 40   // points + coins combined
    static let maxSparks: Int = 50
    static let maxDebris: Int = 12

    // MARK: - Small Tier

    struct Small {
        // VFX
        static let anticipationDuration: TimeInterval = 0.07
        static let flashStartScale: CGFloat = 0.3
        static let flashEndScale: CGFloat = 0.9
        static let flashDuration: TimeInterval = 0.12
        static let flashFadeDuration: TimeInterval = 0.25
        static let sparkCountMin: Int = 8
        static let sparkCountMax: Int = 12
        static let sparkLifetimeMin: TimeInterval = 0.20
        static let sparkLifetimeMax: TimeInterval = 0.35

        // Tile animation
        static let squashDuration: TimeInterval = 0.06
        static let popDuration: TimeInterval = 0.08
        static let fadeDuration: TimeInterval = 0.12

        // Rewards
        static let popupFontSize: CGFloat = 20
        static let popupDriftDuration: TimeInterval = 0.35
        static let scoreCountDuration: TimeInterval = 0.20
    }

    // MARK: - Medium Tier

    struct Medium {
        // VFX
        static let anticipationDuration: TimeInterval = 0.08
        static let anticipationScale: CGFloat = 1.08
        static let flashStartScale: CGFloat = 0.2
        static let flashEndScale: CGFloat = 1.2
        static let flashDuration: TimeInterval = 0.15
        static let flashFadeDuration: TimeInterval = 0.35
        static let shockwaveStartScale: CGFloat = 0.6
        static let shockwaveEndScale: CGFloat = 1.5
        static let shockwaveDuration: TimeInterval = 0.22
        static let sparkCountMin: Int = 16
        static let sparkCountMax: Int = 22
        static let woodSpeckCountMin: Int = 4
        static let woodSpeckCountMax: Int = 8
        static let cameraShakePx: CGFloat = 1.5
        static let cameraShakeDuration: TimeInterval = 0.12

        // Tile animation
        static let squashDuration: TimeInterval = 0.06
        static let popDuration: TimeInterval = 0.09
        static let fadeDuration: TimeInterval = 0.13

        // Rewards
        static let popupFontSize: CGFloat = 26
        static let scoreCountDuration: TimeInterval = 0.42
    }

    // MARK: - Big Tier

    struct Big {
        // VFX
        static let anticipationDuration: TimeInterval = 0.10
        static let anticipationScale: CGFloat = 1.10
        static let flashStartScale: CGFloat = 0.2
        static let flashEndScale: CGFloat = 1.6
        static let flashDuration: TimeInterval = 0.16
        static let flashFadeDuration: TimeInterval = 0.45
        static let shockwaveStartScale: CGFloat = 0.5
        static let shockwaveEndScale: CGFloat = 1.9
        static let shockwaveDuration: TimeInterval = 0.26
        static let secondRingDelay: TimeInterval = 0.05
        static let microSparkCountMin: Int = 24
        static let microSparkCountMax: Int = 40
        static let mainSparkCountMin: Int = 12
        static let mainSparkCountMax: Int = 18
        static let debrisCountMin: Int = 8
        static let debrisCountMax: Int = 12
        static let cameraShakePx: CGFloat = 3.0
        static let cameraShakeDuration: TimeInterval = 0.16
        static let screenTintDuration: TimeInterval = 0.12

        // Tile animation
        static let squashDuration: TimeInterval = 0.05
        static let popDuration: TimeInterval = 0.08
        static let fadeDuration: TimeInterval = 0.11

        // Rewards
        static let popupFontSize: CGFloat = 34
        static let popupAppearDelay: TimeInterval = 0.15   // timed to explosion peak
        static let fragmentBurstDuration: TimeInterval = 0.12
        static let fragmentFlyMinDuration: TimeInterval = 0.45
        static let fragmentFlyMaxDuration: TimeInterval = 0.65
        static let pointFragmentCountMin: Int = 10
        static let pointFragmentCountMax: Int = 20
        static let coinFragmentCountMin: Int = 10
        static let coinFragmentCountMax: Int = 20
        static let scoreCountDuration: TimeInterval = 0.75
    }

    // MARK: - Tier Selection Logic

    /// Determine explosion tier from points, coins, cause, and streak multiplier.
    static func selectTier(
        points: Int,
        coins: Int,
        cause: ExplosionCause,
        streakMultiplier: Double = 1.0
    ) -> ExplosionTier {
        // BIG conditions
        if points >= bigPointsThreshold { return .big }
        if coins >= bigCoinsThreshold { return .big }
        if streakMultiplier >= bigStreakThreshold { return .big }
        switch cause {
        case .chainResolve: return .big
        default: break
        }

        // MEDIUM conditions
        if points >= mediumPointsThreshold { return .medium }
        switch cause {
        case .bomb, .laser, .crossLaser, .mine: return .medium
        default: break
        }

        return .small
    }
}
