import Foundation
import CoreGraphics

// MARK: - Game Constants

struct GameConstants {
    static let boardSize = 7
    static let minWordLength = 3
    static let streakTimeWindow: TimeInterval = 4.0
    static let maxStreakMultiplier: Double = 3.0
    static let streakStep: Double = 0.2
    static let wildcardBasePoints = 2

    // MARK: - Letter Values (Scrabble-like)

    static let letterValues: [Character: Int] = [
        "A": 1, "E": 1, "I": 1, "O": 1, "N": 1,
        "R": 1, "T": 1, "L": 1, "S": 1, "U": 1,
        "D": 2, "G": 2,
        "B": 3, "C": 3, "M": 3, "P": 3,
        "F": 4, "H": 4, "V": 4, "W": 4, "Y": 4,
        "K": 5,
        "J": 8, "X": 8,
        "Q": 10, "Z": 10
    ]

    // MARK: - Length Multipliers

    static let lengthMultipliers: [Int: Double] = [
        3: 1.0,
        4: 1.2,
        5: 1.5,
        6: 1.9,
        7: 2.4
    ]

    static func lengthMultiplier(for length: Int) -> Double {
        if length >= 8 { return 3.0 }
        return lengthMultipliers[length] ?? 1.0
    }

    // MARK: - Cascade Bonuses

    static func cascadeBonus(step: Int) -> Int {
        switch step {
        case 1: return 10
        case 2: return 25
        case 3: return 50
        default: return step >= 4 ? 100 : 0
        }
    }

    // MARK: - Special Tile Spawn Rules

    static func specialTileForWordLength(_ length: Int) -> SpecialTileType? {
        switch length {
        case 5: return .bomb
        case 6: return .laser
        case 7: return .crossLaser
        case 8...: return .wildcard
        default: return nil
        }
    }

    // MARK: - Letter Distribution Weights (for random tile generation)

    static let defaultLetterWeights: [Character: Int] = [
        "A": 9, "B": 2, "C": 2, "D": 4, "E": 12,
        "F": 2, "G": 3, "H": 2, "I": 9, "J": 1,
        "K": 1, "L": 4, "M": 2, "N": 6, "O": 8,
        "P": 2, "Q": 1, "R": 6, "S": 4, "T": 6,
        "U": 4, "V": 2, "W": 2, "X": 1, "Y": 2,
        "Z": 1
    ]

    // MARK: - UI Layout

    static let tileSize: CGFloat = 48.0
    static let tileSpacing: CGFloat = 4.0
    static let hudHeight: CGFloat = 120.0
    static let powerUpBarHeight: CGFloat = 60.0
}
