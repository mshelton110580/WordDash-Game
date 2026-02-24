import Foundation

// MARK: - WordValidator

class WordValidator {
    private var validWords: Set<String> = []
    private var profanityList: Set<String> = []

    static let shared = WordValidator()

    private init() {}

    // MARK: - Loading

    func loadDictionary(from filename: String = "wordlist", extension ext: String = "txt") {
        guard let url = Bundle.main.url(forResource: filename, withExtension: ext) else {
            print("WordValidator: Could not find \(filename).\(ext) in bundle")
            return
        }
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            let words = content.components(separatedBy: .newlines)
            validWords = Set(words.map { $0.trimmingCharacters(in: .whitespaces).uppercased() }
                                  .filter { !$0.isEmpty })
            print("WordValidator: Loaded \(validWords.count) words")
        } catch {
            print("WordValidator: Error loading dictionary: \(error)")
        }
    }

    func loadProfanityList(from filename: String = "profanity", extension ext: String = "txt") {
        guard let url = Bundle.main.url(forResource: filename, withExtension: ext) else {
            print("WordValidator: No profanity list found (optional)")
            return
        }
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            let words = content.components(separatedBy: .newlines)
            profanityList = Set(words.map { $0.trimmingCharacters(in: .whitespaces).uppercased() }
                                     .filter { !$0.isEmpty })
            print("WordValidator: Loaded \(profanityList.count) profanity words")
        } catch {
            print("WordValidator: Error loading profanity list: \(error)")
        }
    }

    // MARK: - Validation

    func isValidWord(_ word: String) -> Bool {
        let upper = word.uppercased()
        guard upper.count >= GameConstants.minWordLength else { return false }
        guard !profanityList.contains(upper) else { return false }
        return validWords.contains(upper)
    }

    /// Build a word string from tiles, handling wildcards
    func buildWord(from tiles: [TileModel]) -> String {
        return String(tiles.map { $0.letter })
    }

    /// For wildcard tiles, check all possible letter substitutions
    func isValidWordWithWildcards(tiles: [TileModel]) -> (valid: Bool, resolvedWord: String) {
        let wildcardIndices = tiles.enumerated().compactMap { $0.element.specialType == .wildcard ? $0.offset : nil }

        if wildcardIndices.isEmpty {
            let word = buildWord(from: tiles)
            return (isValidWord(word), word)
        }

        // Try all letter combinations for wildcards
        let letters: [Character] = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
        return tryWildcardCombinations(tiles: tiles, wildcardIndices: wildcardIndices, currentIndex: 0, letters: letters)
    }

    private func tryWildcardCombinations(tiles: [TileModel], wildcardIndices: [Int], currentIndex: Int, letters: [Character]) -> (valid: Bool, resolvedWord: String) {
        if currentIndex >= wildcardIndices.count {
            let word = buildWord(from: tiles)
            if isValidWord(word) {
                return (true, word)
            }
            return (false, word)
        }

        let tileIndex = wildcardIndices[currentIndex]
        let originalLetter = tiles[tileIndex].letter

        for letter in letters {
            tiles[tileIndex].letter = letter
            let result = tryWildcardCombinations(tiles: tiles, wildcardIndices: wildcardIndices, currentIndex: currentIndex + 1, letters: letters)
            if result.valid {
                return result
            }
        }

        tiles[tileIndex].letter = originalLetter
        return (false, buildWord(from: tiles))
    }

    // MARK: - Hint: Find a valid word on the board

    func findValidWord(on board: [[TileModel?]]) -> [TileModel]? {
        let rows = board.count
        guard rows > 0 else { return nil }
        let cols = board[0].count

        // DFS to find any valid word of length 3+
        for r in 0..<rows {
            for c in 0..<cols {
                guard let tile = board[r][c] else { continue }
                var path: [TileModel] = [tile]
                var visited: Set<UUID> = [tile.id]
                if let result = dfsForWord(board: board, path: &path, visited: &visited, rows: rows, cols: cols) {
                    return result
                }
            }
        }
        return nil
    }

    private func dfsForWord(board: [[TileModel?]], path: inout [TileModel], visited: inout Set<UUID>, rows: Int, cols: Int) -> [TileModel]? {
        if path.count >= GameConstants.minWordLength {
            let word = buildWord(from: path)
            if isValidWord(word) {
                return Array(path)
            }
        }

        if path.count >= 8 { return nil } // limit search depth

        let lastTile = path.last!
        let directions = [(-1, -1), (-1, 0), (-1, 1), (0, -1), (0, 1), (1, -1), (1, 0), (1, 1)]

        for (dr, dc) in directions {
            let nr = lastTile.row + dr
            let nc = lastTile.col + dc
            guard nr >= 0 && nr < rows && nc >= 0 && nc < cols else { continue }
            guard let nextTile = board[nr][nc] else { continue }
            guard !visited.contains(nextTile.id) else { continue }

            path.append(nextTile)
            visited.insert(nextTile.id)

            if let result = dfsForWord(board: board, path: &path, visited: &visited, rows: rows, cols: cols) {
                return result
            }

            path.removeLast()
            visited.remove(nextTile.id)
        }

        return nil
    }
}
