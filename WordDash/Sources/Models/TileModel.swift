import Foundation

// MARK: - Tile Types

enum SpecialTileType: String, Codable {
    case bomb
    case laser
    case crossLaser
    case mine
    case wildcard
}

enum IceState: Int, Codable {
    case none = 0
    case cracked = 1  // one hit taken
    case intact = 2   // fresh ice, needs two hits
}

// MARK: - TileModel

class TileModel: Equatable, Hashable {
    let id: UUID
    var letter: Character
    var row: Int
    var col: Int
    var specialType: SpecialTileType?
    var iceState: IceState
    var hasMineOverlay: Bool

    init(letter: Character, row: Int, col: Int, specialType: SpecialTileType? = nil, iceState: IceState = .none) {
        self.id = UUID()
        self.letter = letter
        self.row = row
        self.col = col
        self.specialType = specialType
        self.iceState = iceState
        self.hasMineOverlay = false
    }

    var isSpecial: Bool {
        return specialType != nil
    }

    var isIced: Bool {
        return iceState != .none
    }

    /// Hit ice once; returns true if ice is now fully cleared
    @discardableResult
    func hitIce() -> Bool {
        switch iceState {
        case .intact:
            iceState = .cracked
            return false
        case .cracked:
            iceState = .none
            return true
        case .none:
            return true
        }
    }

    // MARK: - Equatable & Hashable

    static func == (lhs: TileModel, rhs: TileModel) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
