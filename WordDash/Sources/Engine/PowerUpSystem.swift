import Foundation

// MARK: - PowerUpType

enum PowerUpType: String, CaseIterable {
    case hint
    case bomb
    case laser
    case crossLaser
    case mine
    case shuffle
}

// MARK: - PowerUpAction

enum PowerUpAction {
    case hint(path: [TileModel])
    case placedSpecialTile(tile: TileModel, type: SpecialTileType)
    case placedMine(tile: TileModel)
    case shuffled
}

// MARK: - PowerUpSystem

class PowerUpSystem {

    weak var gameState: GameState?
    weak var boardModel: BoardModel?

    init(gameState: GameState, boardModel: BoardModel) {
        self.gameState = gameState
        self.boardModel = boardModel
    }

    // MARK: - Inventory

    func count(for type: PowerUpType) -> Int {
        guard let state = gameState else { return 0 }
        switch type {
        case .hint: return state.hintCount
        case .bomb: return state.bombCount
        case .laser: return state.laserCount
        case .crossLaser: return state.crossLaserCount
        case .mine: return state.mineCount
        case .shuffle: return state.shuffleCount
        }
    }

    func canUse(_ type: PowerUpType) -> Bool {
        return count(for: type) > 0
    }

    func consume(_ type: PowerUpType) -> Bool {
        guard let state = gameState, canUse(type) else { return false }
        switch type {
        case .hint: state.hintCount -= 1
        case .bomb: state.bombCount -= 1
        case .laser: state.laserCount -= 1
        case .crossLaser: state.crossLaserCount -= 1
        case .mine: state.mineCount -= 1
        case .shuffle: state.shuffleCount -= 1
        }
        return true
    }

    // MARK: - Execute Power-Ups

    func executeHint() -> [TileModel]? {
        guard let board = boardModel else { return nil }
        guard consume(.hint) else { return nil }

        let grid = board.grid
        return WordValidator.shared.findValidWord(on: grid)
    }

    /// Place a bomb special tile at a random normal tile on the board (keeps its letter)
    func placeBomb() -> TileModel? {
        guard let board = boardModel else { return nil }
        guard consume(.bomb) else { return nil }
        return placeSpecialTileRandomly(on: board, type: .bomb)
    }

    /// Place a laser special tile at a random normal tile on the board (keeps its letter)
    func placeLaser() -> TileModel? {
        guard let board = boardModel else { return nil }
        guard consume(.laser) else { return nil }
        return placeSpecialTileRandomly(on: board, type: .laser)
    }

    /// Place a cross laser special tile at a random normal tile on the board (keeps its letter)
    func placeCrossLaser() -> TileModel? {
        guard let board = boardModel else { return nil }
        guard consume(.crossLaser) else { return nil }
        return placeSpecialTileRandomly(on: board, type: .crossLaser)
    }

    /// Place a mine overlay on a random normal tile on the board
    func placeMine() -> TileModel? {
        guard let board = boardModel else { return nil }
        guard consume(.mine) else { return nil }

        var normalTiles: [TileModel] = []
        for r in 0..<board.rows {
            for c in 0..<board.cols {
                if let tile = board.grid[r][c], tile.specialType == nil && !tile.hasMineOverlay {
                    normalTiles.append(tile)
                }
            }
        }
        guard let target = normalTiles.randomElement() else { return nil }
        target.hasMineOverlay = true
        return target
    }

    /// Shuffle all normal tiles on the board
    func executeShuffle() -> Bool {
        guard let board = boardModel else { return false }
        guard consume(.shuffle) else { return false }

        var normalTiles: [TileModel] = []
        for r in 0..<board.rows {
            for c in 0..<board.cols {
                if let tile = board.grid[r][c], tile.specialType == nil {
                    normalTiles.append(tile)
                }
            }
        }

        // Shuffle letters among normal tiles
        var letters = normalTiles.map { $0.letter }
        letters.shuffle()
        for (i, tile) in normalTiles.enumerated() {
            tile.letter = letters[i]
        }

        return true
    }

    // MARK: - Private Helpers

    private func placeSpecialTileRandomly(on board: BoardModel, type: SpecialTileType) -> TileModel? {
        var normalTiles: [TileModel] = []
        for r in 0..<board.rows {
            for c in 0..<board.cols {
                if let tile = board.grid[r][c], tile.specialType == nil {
                    normalTiles.append(tile)
                }
            }
        }
        guard let target = normalTiles.randomElement() else { return nil }
        target.specialType = type
        return target
    }

    // MARK: - Sync with Persistence

    func syncFromProgress(_ inventory: PowerUpInventory) {
        guard let state = gameState else { return }
        state.hintCount = inventory.hintCount
        state.bombCount = inventory.bombCount
        state.laserCount = inventory.laserCount
        state.crossLaserCount = inventory.crossLaserCount
        state.mineCount = inventory.mineCount
    }

    func currentInventory() -> PowerUpInventory {
        guard let state = gameState else { return PowerUpInventory() }
        return PowerUpInventory(
            hintCount: state.hintCount,
            bombCount: state.bombCount,
            laserCount: state.laserCount,
            crossLaserCount: state.crossLaserCount,
            mineCount: state.mineCount
        )
    }
}
