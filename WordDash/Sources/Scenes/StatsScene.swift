import SpriteKit

// MARK: - StatsScene
// Global stats + per-level performance table.
// Mirrors web StatsScreen component.

class StatsScene: SKScene {

    private var scrollNode: SKNode!
    private var contentHeight: CGFloat = 0

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.08, green: 0.06, blue: 0.15, alpha: 1.0)
        setupUI()
    }

    // MARK: - UI

    private func setupUI() {
        // Title
        let titleLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        titleLabel.text = "📊 Your Stats"
        titleLabel.fontSize = 26
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: size.width / 2, y: size.height - 70)
        addChild(titleLabel)

        // Coin display
        let coinLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        coinLabel.text = "🪙 \(CoinManager.shared.balance)"
        coinLabel.fontSize = 18
        coinLabel.fontColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)
        coinLabel.position = CGPoint(x: size.width - 70, y: size.height - 70)
        addChild(coinLabel)

        // Back button
        let backLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        backLabel.text = "← Back"
        backLabel.fontSize = 18
        backLabel.fontColor = .white
        backLabel.position = CGPoint(x: 55, y: size.height - 70)
        backLabel.name = "backButton"
        addChild(backLabel)

        // Scrollable content
        scrollNode = SKNode()
        scrollNode.position = CGPoint(x: 0, y: 0)
        addChild(scrollNode)

        let stats = PersistenceManager.shared.loadStats()
        buildContent(stats: stats)
    }

    private func buildContent(stats: GameStats) {
        var y = size.height - 120

        // Section: Global Stats
        y = addSectionHeader("Global Stats", at: y)

        let globalRows: [(String, String)] = [
            ("Words Found", "\(stats.totalWordsFound)"),
            ("Total Score", formatNumber(stats.totalScore)),
            ("Levels Completed", "\(stats.levelsCompleted)"),
            ("Best Streak", String(format: "%.1fx", stats.bestStreak)),
            ("Best Cascade", stats.bestCascade > 0 ? "×\(stats.bestCascade)" : "—"),
            ("Longest Word", stats.longestWord.isEmpty ? "—" : stats.longestWord),
            ("Coins Earned", formatNumber(stats.totalCoinsEarned)),
            ("Sessions Played", "\(stats.sessionsPlayed)"),
            ("Last Played", stats.lastPlayedDate.isEmpty ? "—" : stats.lastPlayedDate),
        ]

        for (label, value) in globalRows {
            y = addStatRow(label: label, value: value, at: y)
        }

        y -= 16

        // Section: Level Performance
        y = addSectionHeader("Level Performance", at: y)

        // Table header
        y = addLevelTableHeader(at: y)

        for level in 1...10 {
            let stars = stats.levelStars[level] ?? 0
            let score = stats.levelBestScores[level] ?? 0
            y = addLevelRow(level: level, stars: stars, score: score, at: y)
        }

        contentHeight = size.height - 120 - y
    }

    // MARK: - Row Builders

    @discardableResult
    private func addSectionHeader(_ text: String, at y: CGFloat) -> CGFloat {
        let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        label.text = text
        label.fontSize = 15
        label.fontColor = SKColor(red: 0.65, green: 0.5, blue: 0.9, alpha: 1.0)
        label.horizontalAlignmentMode = .left
        label.position = CGPoint(x: 24, y: y - 24)
        scrollNode.addChild(label)
        return y - 40
    }

    @discardableResult
    private func addStatRow(label: String, value: String, at y: CGFloat) -> CGFloat {
        let rowHeight: CGFloat = 38
        let rowWidth = size.width - 32

        let bg = SKShapeNode(rectOf: CGSize(width: rowWidth, height: rowHeight - 4), cornerRadius: 8)
        bg.position = CGPoint(x: size.width / 2, y: y - rowHeight / 2)
        bg.fillColor = SKColor(white: 1.0, alpha: 0.05)
        bg.strokeColor = .clear
        scrollNode.addChild(bg)

        let labelNode = SKLabelNode(fontNamed: "AvenirNext-Regular")
        labelNode.text = label
        labelNode.fontSize = 14
        labelNode.fontColor = SKColor(white: 0.65, alpha: 1.0)
        labelNode.horizontalAlignmentMode = .left
        labelNode.verticalAlignmentMode = .center
        labelNode.position = CGPoint(x: 20 - rowWidth / 2, y: 0)
        bg.addChild(labelNode)

        let valueNode = SKLabelNode(fontNamed: "AvenirNext-Bold")
        valueNode.text = value
        valueNode.fontSize = 14
        valueNode.fontColor = .white
        valueNode.horizontalAlignmentMode = .right
        valueNode.verticalAlignmentMode = .center
        valueNode.position = CGPoint(x: rowWidth / 2 - 12, y: 0)
        bg.addChild(valueNode)

        return y - rowHeight
    }

    @discardableResult
    private func addLevelTableHeader(at y: CGFloat) -> CGFloat {
        let columns: [(String, CGFloat)] = [
            ("Level", 50), ("Stars", size.width / 2 - 20), ("Best Score", size.width - 60)
        ]
        for (text, x) in columns {
            let label = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
            label.text = text
            label.fontSize = 12
            label.fontColor = SKColor(white: 0.45, alpha: 1.0)
            label.horizontalAlignmentMode = .left
            label.position = CGPoint(x: x, y: y - 16)
            scrollNode.addChild(label)
        }
        return y - 30
    }

    @discardableResult
    private func addLevelRow(level: Int, stars: Int, score: Int, at y: CGFloat) -> CGFloat {
        let rowHeight: CGFloat = 34
        let rowWidth = size.width - 32

        let bg = SKShapeNode(rectOf: CGSize(width: rowWidth, height: rowHeight - 2), cornerRadius: 6)
        bg.position = CGPoint(x: size.width / 2, y: y - rowHeight / 2)
        bg.fillColor = stars > 0
            ? SKColor(red: 0.15, green: 0.12, blue: 0.25, alpha: 1.0)
            : SKColor(white: 1.0, alpha: 0.03)
        bg.strokeColor = .clear
        scrollNode.addChild(bg)

        // Level number
        let levelLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        levelLabel.text = "Lvl \(level)"
        levelLabel.fontSize = 13
        levelLabel.fontColor = stars > 0 ? .white : SKColor(white: 0.35, alpha: 1.0)
        levelLabel.horizontalAlignmentMode = .left
        levelLabel.verticalAlignmentMode = .center
        levelLabel.position = CGPoint(x: 20 - rowWidth / 2, y: 0)
        bg.addChild(levelLabel)

        // Stars
        let starString = stars > 0 ? String(repeating: "★", count: stars) + String(repeating: "☆", count: 3 - stars) : "—"
        let starsLabel = SKLabelNode(fontNamed: "AvenirNext-Regular")
        starsLabel.text = starString
        starsLabel.fontSize = 14
        starsLabel.fontColor = stars > 0 ? SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0) : SKColor(white: 0.25, alpha: 1.0)
        starsLabel.horizontalAlignmentMode = .center
        starsLabel.verticalAlignmentMode = .center
        starsLabel.position = CGPoint(x: 0, y: 0)
        bg.addChild(starsLabel)

        // Best score
        let scoreLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        scoreLabel.text = score > 0 ? formatNumber(score) : "—"
        scoreLabel.fontSize = 13
        scoreLabel.fontColor = score > 0 ? SKColor(red: 0.5, green: 0.9, blue: 0.6, alpha: 1.0) : SKColor(white: 0.25, alpha: 1.0)
        scoreLabel.horizontalAlignmentMode = .right
        scoreLabel.verticalAlignmentMode = .center
        scoreLabel.position = CGPoint(x: rowWidth / 2 - 12, y: 0)
        bg.addChild(scoreLabel)

        return y - rowHeight
    }

    // MARK: - Helpers

    private func formatNumber(_ n: Int) -> String {
        if n >= 1_000_000 { return String(format: "%.1fM", Double(n) / 1_000_000) }
        if n >= 1_000 { return String(format: "%.1fK", Double(n) / 1_000) }
        return "\(n)"
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let tapped = nodes(at: location)

        for node in tapped {
            if node.name == "backButton" || node.parent?.name == "backButton" {
                let menu = MainMenuScene(size: size)
                menu.scaleMode = .aspectFill
                view?.presentScene(menu, transition: .fade(withDuration: 0.3))
                return
            }
        }
    }
}
