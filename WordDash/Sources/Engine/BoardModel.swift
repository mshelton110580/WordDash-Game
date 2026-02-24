import Foundation

// MARK: - ClearEvent

struct ClearEvent {
    let tiles: [TileModel]
    let reason: ClearReason
}

enum ClearReason {
    case word
    case bomb(center: TileModel)
    case laser(tile: TileModel, isRow: Bool)
    case crossLaser(tile: TileModel)
    case mine(center: TileModel)
}

// MARK: - GravityResult

struct GravityResult {
    /// (tile, fromRow, toRow)
    let movedTiles: [(tile: TileModel, fromRow: Int, toRow: Int)]
    let newTiles: [TileModel]
}

// MARK: - BoardModel

class BoardModel {
    let rows: Int
    let cols: Int
    var grid: [[TileModel?]]
    let letterGenerator: LetterGenerator

    init(rows: Int = GameConstants.boardSize, cols: Int = GameConstants.boardSize, letterWeights: [Character: Int]? = nil) {
        self.rows = rows
        self.cols = cols
        self.letterGenerator = LetterGenerator(weights: letterWeights)
        self.grid = Array(repeating: Array(repeating: nil as TileModel?, count: cols), count: rows)
    }

    // MARK: - Board Setup

    func fillBoard(icePositions: [IcePosition]? = nil) {
        for r in 0..<rows {
            for c in 0..<cols {
                let letter = letterGenerator.randomLetter()
                let tile = TileModel(letter: letter, row: r, col: c)

                // Check if this position should have ice
                if let icePos = icePositions {
                    if icePos.contains(where: { $0.row == r && $0.col == c }) {
                        tile.iceState = .intact
                    }
                }

                grid[r][c] = tile
            }
        }
    }

    func tileAt(row: Int, col: Int) -> TileModel? {
        guard row >= 0 && row < rows && col >= 0 && col < cols else { return nil }
        return grid[row][col]
    }

    // MARK: - Adjacency

    static func areAdjacent(_ a: TileModel, _ b: TileModel) -> Bool {
        let dr = abs(a.row - b.row)
        let dc = abs(a.col - b.col)
        return dr <= 1 && dc <= 1 && !(dr == 0 && dc == 0)
    }

    func isValidPath(_ path: [TileModel]) -> Bool {
        guard path.count >= 1 else { return false }
        var seen = Set<UUID>()
        for (i, tile) in path.enumerated() {
            if seen.contains(tile.id) { return false }
            seen.insert(tile.id)
            if i > 0 {
                if !BoardModel.areAdjacent(path[i - 1], tile) { return false }
            }
        }
        return true
    }

    // MARK: - Clear Tiles

    /// Remove tiles from the grid and handle ice
    /// Returns tiles that were actually removed (ice might survive)
    func clearTiles(_ tilesToClear: [TileModel]) -> (removed: [TileModel], iceHits: [TileModel]) {
        var removed: [TileModel] = []
        var iceHits: [TileModel] = []

        for tile in tilesToClear {
            guard let existing = grid[tile.row][tile.col], existing.id == tile.id else { continue }

            if existing.isIced {
                let cleared = existing.hitIce()
                iceHits.append(existing)
                if cleared {
                    // Ice fully cleared, but tile stays (it's now a normal tile)
                    // The tile itself is not removed, just the ice
                }
                // Don't remove iced tiles from grid on first hit
                if !cleared {
                    continue
                }
            }

            // Check for mine overlay
            if existing.hasMineOverlay {
                existing.hasMineOverlay = false
                // Mine trigger will be handled by caller
            }

            grid[tile.row][tile.col] = nil
            removed.append(existing)
        }

        return (removed, iceHits)
    }

    // MARK: - Special Tile Effects

    func tilesAffectedByBomb(center: TileModel) -> [TileModel] {
        var affected: [TileModel] = []
        for dr in -1...1 {
            for dc in -1...1 {
                let r = center.row + dr
                let c = center.col + dc
                if let tile = tileAt(row: r, col: c) {
                    affected.append(tile)
                }
            }
        }
        return affected
    }

    func tilesAffectedByLaser(tile: TileModel, isRow: Bool) -> [TileModel] {
        var affected: [TileModel] = []
        if isRow {
            for c in 0..<cols {
                if let t = grid[tile.row][c] {
                    affected.append(t)
                }
            }
        } else {
            for r in 0..<rows {
                if let t = grid[r][tile.col] {
                    affected.append(t)
                }
            }
        }
        return affected
    }

    func tilesAffectedByCrossLaser(tile: TileModel) -> [TileModel] {
        var affected: [TileModel] = []
        var seen = Set<UUID>()

        // Row
        for c in 0..<cols {
            if let t = grid[tile.row][c], !seen.contains(t.id) {
                affected.append(t)
                seen.insert(t.id)
            }
        }
        // Column
        for r in 0..<rows {
            if let t = grid[r][tile.col], !seen.contains(t.id) {
                affected.append(t)
                seen.insert(t.id)
            }
        }
        return affected
    }

    func tilesAffectedByMine(center: TileModel) -> [TileModel] {
        return tilesAffectedByBomb(center: center) // Same 3x3 area
    }

    // MARK: - Process Special Tiles in Word

    func processSpecialEffects(wordTiles: [TileModel], dragDirections: [(dx: Int, dy: Int)]) -> [ClearEvent] {
        var events: [ClearEvent] = []

        for (i, tile) in wordTiles.enumerated() {
            guard let special = tile.specialType else { continue }

            switch special {
            case .bomb:
                let affected = tilesAffectedByBomb(center: tile)
                events.append(ClearEvent(tiles: affected, reason: .bomb(center: tile)))

            case .laser:
                // Determine direction based on drag into this tile
                let isRow: Bool
                if i > 0 && i - 1 < dragDirections.count {
                    let dir = dragDirections[i - 1]
                    isRow = abs(dir.dx) >= abs(dir.dy)
                } else {
                    isRow = true // default to row
                }
                let affected = tilesAffectedByLaser(tile: tile, isRow: isRow)
                events.append(ClearEvent(tiles: affected, reason: .laser(tile: tile, isRow: isRow)))

            case .crossLaser:
                let affected = tilesAffectedByCrossLaser(tile: tile)
                events.append(ClearEvent(tiles: affected, reason: .crossLaser(tile: tile)))

            case .mine:
                // Mine in word path: treat like bomb
                let affected = tilesAffectedByMine(center: tile)
                events.append(ClearEvent(tiles: affected, reason: .mine(center: tile)))

            case .wildcard:
                // No special clear effect
                break
            }
        }

        return events
    }

    // MARK: - Check for Mine Triggers

    func findTriggeredMines(in clearedTiles: [TileModel]) -> [TileModel] {
        return clearedTiles.filter { $0.hasMineOverlay }
    }

    // MARK: - Gravity & Refill

    func applyGravityAndRefill(specialTileSpawn: (row: Int, col: Int, type: SpecialTileType)? = nil) -> GravityResult {
        var movedTiles: [(tile: TileModel, fromRow: Int, toRow: Int)] = []
        var newTiles: [TileModel] = []

        for c in 0..<cols {
            // Collect non-nil tiles from bottom to top
            var columnTiles: [TileModel] = []
            for r in stride(from: rows - 1, through: 0, by: -1) {
                if let tile = grid[r][c] {
                    columnTiles.append(tile)
                }
            }

            // Place them at bottom
            var writeRow = rows - 1
            for tile in columnTiles {
                let fromRow = tile.row
                tile.row = writeRow
                tile.col = c
                grid[writeRow][c] = tile
                if fromRow != writeRow {
                    movedTiles.append((tile: tile, fromRow: fromRow, toRow: writeRow))
                }
                writeRow -= 1
            }

            // Fill empty spaces from top
            for r in stride(from: writeRow, through: 0, by: -1) {
                // Check if we should spawn a special tile here
                if let spawn = specialTileSpawn, spawn.col == c && r == writeRow {
                    let tile = TileModel(letter: "★", row: r, col: c, specialType: spawn.type)
                    if spawn.type == .wildcard {
                        tile.letter = "✦"
                    }
                    grid[r][c] = tile
                    newTiles.append(tile)
                } else {
                    let letter = letterGenerator.randomLetter()
                    let tile = TileModel(letter: letter, row: r, col: c)
                    grid[r][c] = tile
                    newTiles.append(tile)
                }
            }
        }

        return GravityResult(movedTiles: movedTiles, newTiles: newTiles)
    }

    // MARK: - Count Ice Tiles

    func countIceTiles() -> Int {
        var count = 0
        for r in 0..<rows {
            for c in 0..<cols {
                if let tile = grid[r][c], tile.isIced {
                    count += 1
                }
            }
        }
        return count
    }

    // MARK: - Debug Print

    func printBoard() {
        for r in 0..<rows {
            var line = ""
            for c in 0..<cols {
                if let tile = grid[r][c] {
                    let prefix = tile.isIced ? "[" : " "
                    let suffix = tile.isIced ? "]" : " "
                    let special = tile.specialType != nil ? "*" : ""
                    line += "\(prefix)\(tile.letter)\(special)\(suffix)"
                } else {
                    line += " .  "
                }
            }
            print(line)
        }
    }
}
