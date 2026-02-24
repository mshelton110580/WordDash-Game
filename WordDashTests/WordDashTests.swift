import XCTest
@testable import WordDash

// MARK: - Adjacency Tests

class AdjacencyTests: XCTestCase {

    func testAdjacentHorizontal() {
        let a = TileModel(letter: "A", row: 3, col: 3)
        let b = TileModel(letter: "B", row: 3, col: 4)
        XCTAssertTrue(BoardModel.areAdjacent(a, b), "Horizontal neighbors should be adjacent")
    }

    func testAdjacentVertical() {
        let a = TileModel(letter: "A", row: 3, col: 3)
        let b = TileModel(letter: "B", row: 4, col: 3)
        XCTAssertTrue(BoardModel.areAdjacent(a, b), "Vertical neighbors should be adjacent")
    }

    func testAdjacentDiagonal() {
        let a = TileModel(letter: "A", row: 3, col: 3)
        let b = TileModel(letter: "B", row: 4, col: 4)
        XCTAssertTrue(BoardModel.areAdjacent(a, b), "Diagonal neighbors should be adjacent")
    }

    func testAdjacentDiagonalUpLeft() {
        let a = TileModel(letter: "A", row: 3, col: 3)
        let b = TileModel(letter: "B", row: 2, col: 2)
        XCTAssertTrue(BoardModel.areAdjacent(a, b), "Upper-left diagonal should be adjacent")
    }

    func testNotAdjacentFarAway() {
        let a = TileModel(letter: "A", row: 0, col: 0)
        let b = TileModel(letter: "B", row: 2, col: 2)
        XCTAssertFalse(BoardModel.areAdjacent(a, b), "Tiles 2 steps away should not be adjacent")
    }

    func testNotAdjacentSamePosition() {
        let a = TileModel(letter: "A", row: 3, col: 3)
        let b = TileModel(letter: "B", row: 3, col: 3)
        XCTAssertFalse(BoardModel.areAdjacent(a, b), "Same position should not be adjacent")
    }

    func testNotAdjacentKnightMove() {
        let a = TileModel(letter: "A", row: 3, col: 3)
        let b = TileModel(letter: "B", row: 5, col: 4)
        XCTAssertFalse(BoardModel.areAdjacent(a, b), "Knight-move should not be adjacent")
    }

    func testAllEightDirections() {
        let center = TileModel(letter: "C", row: 3, col: 3)
        let directions = [(-1,-1),(-1,0),(-1,1),(0,-1),(0,1),(1,-1),(1,0),(1,1)]
        for (dr, dc) in directions {
            let neighbor = TileModel(letter: "N", row: 3 + dr, col: 3 + dc)
            XCTAssertTrue(BoardModel.areAdjacent(center, neighbor),
                          "Direction (\(dr),\(dc)) should be adjacent")
        }
    }

    // MARK: - No Reuse Tests

    func testPathNoReuse() {
        let board = BoardModel(rows: 7, cols: 7)
        let t1 = TileModel(letter: "A", row: 0, col: 0)
        let t2 = TileModel(letter: "B", row: 0, col: 1)
        let t3 = TileModel(letter: "C", row: 1, col: 1)

        XCTAssertTrue(board.isValidPath([t1, t2, t3]), "Valid path without reuse")
    }

    func testPathWithReuse() {
        let board = BoardModel(rows: 7, cols: 7)
        let t1 = TileModel(letter: "A", row: 0, col: 0)
        let t2 = TileModel(letter: "B", row: 0, col: 1)

        // Create path that reuses t1
        let path = [t1, t2, t1]
        XCTAssertFalse(board.isValidPath(path), "Path reusing a tile should be invalid")
    }

    func testPathNotAdjacent() {
        let board = BoardModel(rows: 7, cols: 7)
        let t1 = TileModel(letter: "A", row: 0, col: 0)
        let t2 = TileModel(letter: "B", row: 3, col: 3)

        XCTAssertFalse(board.isValidPath([t1, t2]), "Non-adjacent path should be invalid")
    }
}

// MARK: - Backtracking Tests

class BacktrackingTests: XCTestCase {

    func testBacktrackRemovesLastTile() {
        // Simulate the drag backtracking logic
        var path: [TileModel] = []
        let t1 = TileModel(letter: "A", row: 0, col: 0)
        let t2 = TileModel(letter: "B", row: 0, col: 1)
        let t3 = TileModel(letter: "C", row: 1, col: 1)

        path.append(t1)
        path.append(t2)
        path.append(t3)

        // Simulate backtrack: user drags back to t2
        if path.count >= 2 && t2.id == path[path.count - 2].id {
            path.removeLast()
        }

        XCTAssertEqual(path.count, 2)
        XCTAssertEqual(path.last?.id, t2.id)
    }

    func testBacktrackToStart() {
        var path: [TileModel] = []
        let t1 = TileModel(letter: "A", row: 0, col: 0)
        let t2 = TileModel(letter: "B", row: 0, col: 1)

        path.append(t1)
        path.append(t2)

        // Backtrack to t1
        if path.count >= 2 && t1.id == path[path.count - 2].id {
            path.removeLast()
        }

        XCTAssertEqual(path.count, 1)
        XCTAssertEqual(path.last?.id, t1.id)
    }

    func testNoBacktrackOnForwardMove() {
        var path: [TileModel] = []
        let t1 = TileModel(letter: "A", row: 0, col: 0)
        let t2 = TileModel(letter: "B", row: 0, col: 1)
        let t3 = TileModel(letter: "C", row: 1, col: 1)

        path.append(t1)
        path.append(t2)

        // t3 is not the previous tile, so no backtrack
        if path.count >= 2 && t3.id == path[path.count - 2].id {
            path.removeLast()
        } else {
            // Normal forward append
            path.append(t3)
        }

        XCTAssertEqual(path.count, 3)
    }
}

// MARK: - Scoring Tests

class ScoringTests: XCTestCase {

    func testLetterValues() {
        let engine = ScoringEngine.shared

        XCTAssertEqual(engine.letterValue(for: "A"), 1)
        XCTAssertEqual(engine.letterValue(for: "E"), 1)
        XCTAssertEqual(engine.letterValue(for: "D"), 2)
        XCTAssertEqual(engine.letterValue(for: "G"), 2)
        XCTAssertEqual(engine.letterValue(for: "B"), 3)
        XCTAssertEqual(engine.letterValue(for: "F"), 4)
        XCTAssertEqual(engine.letterValue(for: "K"), 5)
        XCTAssertEqual(engine.letterValue(for: "J"), 8)
        XCTAssertEqual(engine.letterValue(for: "Q"), 10)
        XCTAssertEqual(engine.letterValue(for: "Z"), 10)
    }

    func testBaseLetterScore() {
        let engine = ScoringEngine.shared

        // "CAT" = C(3) + A(1) + T(1) = 5
        let tiles = [
            TileModel(letter: "C", row: 0, col: 0),
            TileModel(letter: "A", row: 0, col: 1),
            TileModel(letter: "T", row: 0, col: 2)
        ]

        XCTAssertEqual(engine.baseLetterScore(for: tiles), 5)
    }

    func testLengthMultipliers() {
        XCTAssertEqual(GameConstants.lengthMultiplier(for: 3), 1.0)
        XCTAssertEqual(GameConstants.lengthMultiplier(for: 4), 1.2)
        XCTAssertEqual(GameConstants.lengthMultiplier(for: 5), 1.5)
        XCTAssertEqual(GameConstants.lengthMultiplier(for: 6), 1.9)
        XCTAssertEqual(GameConstants.lengthMultiplier(for: 7), 2.4)
        XCTAssertEqual(GameConstants.lengthMultiplier(for: 8), 3.0)
        XCTAssertEqual(GameConstants.lengthMultiplier(for: 10), 3.0)
    }

    func testScoreCalculation3LetterWord() {
        let engine = ScoringEngine.shared
        let state = GameState()

        // "CAT" = base 5, length 3 -> mult 1.0, streak 1.0, first use 1.0
        let tiles = [
            TileModel(letter: "C", row: 0, col: 0),
            TileModel(letter: "A", row: 0, col: 1),
            TileModel(letter: "T", row: 0, col: 2)
        ]

        let result = engine.calculateScore(tiles: tiles, gameState: state)
        // 5 * 1.0 * 1.0 * 1.0 = 5
        XCTAssertEqual(result.baseLetterScore, 5)
        XCTAssertEqual(result.lengthMultiplier, 1.0)
        XCTAssertEqual(result.totalScore, 5)
    }

    func testWildcardScoring() {
        let engine = ScoringEngine.shared

        let wildcard = TileModel(letter: "★", row: 0, col: 0, specialType: .wildcard)
        let tiles = [wildcard]

        XCTAssertEqual(engine.baseLetterScore(for: tiles), 2, "Wildcard should score 2 base points")
    }

    func testCascadeBonuses() {
        XCTAssertEqual(GameConstants.cascadeBonus(step: 0), 0)
        XCTAssertEqual(GameConstants.cascadeBonus(step: 1), 10)
        XCTAssertEqual(GameConstants.cascadeBonus(step: 2), 25)
        XCTAssertEqual(GameConstants.cascadeBonus(step: 3), 50)
        XCTAssertEqual(GameConstants.cascadeBonus(step: 4), 100)
        XCTAssertEqual(GameConstants.cascadeBonus(step: 5), 100)
    }
}

// MARK: - Diminishing Repeat Tests

class DiminishingRepeatTests: XCTestCase {

    func testFirstUseFullPoints() {
        let state = GameState()
        let count = state.trackWordUsage("CAT")
        XCTAssertEqual(count, 1)
        XCTAssertEqual(state.diminishingMultiplier(usageCount: 1), 1.0)
    }

    func testSecondUseHalfPoints() {
        let state = GameState()
        _ = state.trackWordUsage("CAT")
        let count = state.trackWordUsage("CAT")
        XCTAssertEqual(count, 2)
        XCTAssertEqual(state.diminishingMultiplier(usageCount: 2), 0.5)
    }

    func testThirdUseTenPercent() {
        let state = GameState()
        _ = state.trackWordUsage("CAT")
        _ = state.trackWordUsage("CAT")
        let count = state.trackWordUsage("CAT")
        XCTAssertEqual(count, 3)
        XCTAssertEqual(state.diminishingMultiplier(usageCount: 3), 0.1)
    }

    func testFourthUseTenPercent() {
        let state = GameState()
        for _ in 1...3 { _ = state.trackWordUsage("CAT") }
        let count = state.trackWordUsage("CAT")
        XCTAssertEqual(count, 4)
        XCTAssertEqual(state.diminishingMultiplier(usageCount: 4), 0.1)
    }

    func testDifferentWordsIndependent() {
        let state = GameState()
        let catCount = state.trackWordUsage("CAT")
        let dogCount = state.trackWordUsage("DOG")
        XCTAssertEqual(catCount, 1)
        XCTAssertEqual(dogCount, 1)
    }

    func testCaseInsensitive() {
        let state = GameState()
        _ = state.trackWordUsage("cat")
        let count = state.trackWordUsage("CAT")
        XCTAssertEqual(count, 2, "Word tracking should be case-insensitive")
    }
}

// MARK: - Streak Tests

class StreakTests: XCTestCase {

    func testStreakIncreasesWithinWindow() {
        let state = GameState()
        state.lastWordTime = Date().addingTimeInterval(-2.0) // 2 seconds ago
        state.streakMultiplier = 1.0
        state.updateStreak()
        XCTAssertEqual(state.streakMultiplier, 1.2, accuracy: 0.01)
    }

    func testStreakResetsOutsideWindow() {
        let state = GameState()
        state.lastWordTime = Date().addingTimeInterval(-5.0) // 5 seconds ago
        state.streakMultiplier = 2.0
        state.updateStreak()
        XCTAssertEqual(state.streakMultiplier, 1.0, accuracy: 0.01)
    }

    func testStreakCapsAtMax() {
        let state = GameState()
        state.streakMultiplier = 2.9
        state.lastWordTime = Date().addingTimeInterval(-1.0)
        state.updateStreak()
        XCTAssertEqual(state.streakMultiplier, 3.0, accuracy: 0.01, "Streak should cap at 3.0")
    }

    func testFirstWordNoStreak() {
        let state = GameState()
        state.lastWordTime = nil
        state.updateStreak()
        XCTAssertEqual(state.streakMultiplier, 1.0, accuracy: 0.01)
    }
}

// MARK: - Special Tile Spawn Tests

class SpecialTileSpawnTests: XCTestCase {

    func testLength5SpawnsBomb() {
        XCTAssertEqual(GameConstants.specialTileForWordLength(5), .bomb)
    }

    func testLength6SpawnsLaser() {
        XCTAssertEqual(GameConstants.specialTileForWordLength(6), .laser)
    }

    func testLength7SpawnsCrossLaser() {
        XCTAssertEqual(GameConstants.specialTileForWordLength(7), .crossLaser)
    }

    func testLength8SpawnsWildcard() {
        XCTAssertEqual(GameConstants.specialTileForWordLength(8), .wildcard)
    }

    func testLength3NoSpawn() {
        XCTAssertNil(GameConstants.specialTileForWordLength(3))
    }

    func testLength4NoSpawn() {
        XCTAssertNil(GameConstants.specialTileForWordLength(4))
    }
}

// MARK: - Ice Tile Tests

class IceTileTests: XCTestCase {

    func testIntactIceNeedsTwoHits() {
        let tile = TileModel(letter: "A", row: 0, col: 0)
        tile.iceState = .intact

        let firstHit = tile.hitIce()
        XCTAssertFalse(firstHit, "First hit should not clear ice")
        XCTAssertEqual(tile.iceState, .cracked)

        let secondHit = tile.hitIce()
        XCTAssertTrue(secondHit, "Second hit should clear ice")
        XCTAssertEqual(tile.iceState, .none)
    }

    func testCrackedIceNeedsOneHit() {
        let tile = TileModel(letter: "A", row: 0, col: 0)
        tile.iceState = .cracked

        let hit = tile.hitIce()
        XCTAssertTrue(hit)
        XCTAssertEqual(tile.iceState, .none)
    }

    func testNoIceHitReturnsTrue() {
        let tile = TileModel(letter: "A", row: 0, col: 0)
        tile.iceState = .none

        let hit = tile.hitIce()
        XCTAssertTrue(hit)
    }
}

// MARK: - Board Model Tests

class BoardModelTests: XCTestCase {

    func testBoardFill() {
        let board = BoardModel(rows: 7, cols: 7)
        board.fillBoard()

        for r in 0..<7 {
            for c in 0..<7 {
                XCTAssertNotNil(board.tileAt(row: r, col: c), "Tile at (\(r),\(c)) should not be nil")
            }
        }
    }

    func testBoardFillWithIce() {
        let board = BoardModel(rows: 7, cols: 7)
        let icePositions = [IcePosition(row: 2, col: 2), IcePosition(row: 3, col: 3)]
        board.fillBoard(icePositions: icePositions)

        XCTAssertEqual(board.tileAt(row: 2, col: 2)?.iceState, .intact)
        XCTAssertEqual(board.tileAt(row: 3, col: 3)?.iceState, .intact)
        XCTAssertEqual(board.tileAt(row: 0, col: 0)?.iceState, .none)
    }

    func testBombAffectsThreeByThree() {
        let board = BoardModel(rows: 7, cols: 7)
        board.fillBoard()

        let center = board.tileAt(row: 3, col: 3)!
        let affected = board.tilesAffectedByBomb(center: center)

        // 3x3 = 9 tiles
        XCTAssertEqual(affected.count, 9)
    }

    func testBombAtCornerAffectsLess() {
        let board = BoardModel(rows: 7, cols: 7)
        board.fillBoard()

        let corner = board.tileAt(row: 0, col: 0)!
        let affected = board.tilesAffectedByBomb(center: corner)

        // Corner: 2x2 = 4 tiles
        XCTAssertEqual(affected.count, 4)
    }

    func testLaserAffectsFullRow() {
        let board = BoardModel(rows: 7, cols: 7)
        board.fillBoard()

        let tile = board.tileAt(row: 3, col: 3)!
        let affected = board.tilesAffectedByLaser(tile: tile, isRow: true)

        XCTAssertEqual(affected.count, 7)
    }

    func testCrossLaserAffectsRowAndColumn() {
        let board = BoardModel(rows: 7, cols: 7)
        board.fillBoard()

        let tile = board.tileAt(row: 3, col: 3)!
        let affected = board.tilesAffectedByCrossLaser(tile: tile)

        // Row(7) + Column(7) - intersection(1) = 13
        XCTAssertEqual(affected.count, 13)
    }

    func testOutOfBoundsReturnsNil() {
        let board = BoardModel(rows: 7, cols: 7)
        board.fillBoard()

        XCTAssertNil(board.tileAt(row: -1, col: 0))
        XCTAssertNil(board.tileAt(row: 7, col: 0))
        XCTAssertNil(board.tileAt(row: 0, col: -1))
        XCTAssertNil(board.tileAt(row: 0, col: 7))
    }
}
