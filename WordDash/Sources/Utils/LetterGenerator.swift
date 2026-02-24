import Foundation

// MARK: - LetterGenerator

struct LetterGenerator {
    private let weightedPool: [Character]

    init(weights: [Character: Int]? = nil) {
        let w = weights?.compactMapValues { $0 } ?? GameConstants.defaultLetterWeights.mapValues { $0 }
        var pool: [Character] = []
        for (letter, count) in w {
            for _ in 0..<count {
                pool.append(letter)
            }
        }
        self.weightedPool = pool
    }

    func randomLetter() -> Character {
        return weightedPool.randomElement() ?? "E"
    }
}
