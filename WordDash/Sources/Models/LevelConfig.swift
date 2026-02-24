import Foundation

// MARK: - Goal Type

enum GoalType: String, Codable {
    case scoreTimed
    case clearIceMoves
}

// MARK: - IcePosition

struct IcePosition: Codable {
    let row: Int
    let col: Int
}

// MARK: - Star Thresholds

struct StarThresholds: Codable {
    let oneStar: Int
    let twoStar: Int
    let threeStar: Int
}

// MARK: - LevelConfig

struct LevelConfig: Codable {
    let levelNumber: Int
    let goalType: GoalType
    let boardSize: Int  // default 7

    // scoreTimed fields
    let targetScore: Int?
    let timeLimitSeconds: Int?
    let addTimeOnClearSeconds: Int?

    // clearIceMoves fields
    let iceTilesToClearTarget: Int?
    let moveLimit: Int?
    let icePositions: [IcePosition]?

    // star thresholds
    let starThresholds: StarThresholds

    // letter distribution weights (optional override)
    let letterWeights: [String: Int]?

    init(levelNumber: Int,
         goalType: GoalType,
         boardSize: Int = 7,
         targetScore: Int? = nil,
         timeLimitSeconds: Int? = nil,
         addTimeOnClearSeconds: Int? = nil,
         iceTilesToClearTarget: Int? = nil,
         moveLimit: Int? = nil,
         icePositions: [IcePosition]? = nil,
         starThresholds: StarThresholds,
         letterWeights: [String: Int]? = nil) {
        self.levelNumber = levelNumber
        self.goalType = goalType
        self.boardSize = boardSize
        self.targetScore = targetScore
        self.timeLimitSeconds = timeLimitSeconds
        self.addTimeOnClearSeconds = addTimeOnClearSeconds
        self.iceTilesToClearTarget = iceTilesToClearTarget
        self.moveLimit = moveLimit
        self.icePositions = icePositions
        self.starThresholds = starThresholds
        self.letterWeights = letterWeights
    }
}
