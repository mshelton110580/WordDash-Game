import Foundation

// MARK: - PowerUpType

enum PowerUpType: String, CaseIterable {
    case hint
    case bomb
    case laser
    case crossLaser
    case mine
}

// MARK: - PowerUpAction

enum PowerUpAction {
    case hint(path: [TileModel])
    case bomb(center: TileModel)
    case laser(tile: TileModel, isRow: Bool)
    case crossLaser(tile: TileModel)
    case mine(tile: TileModel)
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

    func executeBomb(at tile: TileModel) -> [TileModel]? {
        guard let board = boardModel else { return nil }
        guard consume(.bomb) else { return nil }
        return board.tilesAffectedByBomb(center: tile)
    }

    func executeLaser(at tile: TileModel, isRow: Bool) -> [TileModel]? {
        guard let board = boardModel else { return nil }
        guard consume(.laser) else { return nil }
        return board.tilesAffectedByLaser(tile: tile, isRow: isRow)
    }

    func executeCrossLaser(at tile: TileModel) -> [TileModel]? {
        guard let board = boardModel else { return nil }
        guard consume(.crossLaser) else { return nil }
        return board.tilesAffectedByCrossLaser(tile: tile)
    }

    func placeMine(on tile: TileModel) -> Bool {
        guard consume(.mine) else { return false }
        tile.hasMineOverlay = true
        return true
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
