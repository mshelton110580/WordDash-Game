import SpriteKit

// MARK: - LevelMapScene

class LevelMapScene: SKScene {

    var progress: PlayerProgress!

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.1, green: 0.12, blue: 0.22, alpha: 1.0)
        progress = PersistenceManager.shared.loadProgress()

        // Load levels
        LevelManager.shared.loadAllLevels()

        setupUI()
    }

    func setupUI() {
        // Title
        let titleLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        titleLabel.text = "Select Level"
        titleLabel.fontSize = 32
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: size.width / 2, y: size.height - 80)
        addChild(titleLabel)

        // Back button
        let backBtn = SKNode()
        backBtn.name = "backButton"
        backBtn.position = CGPoint(x: 40, y: size.height - 75)
        let backBG = SKShapeNode(rectOf: CGSize(width: 60, height: 35), cornerRadius: 8)
        backBG.fillColor = SKColor(white: 0.3, alpha: 0.8)
        backBG.strokeColor = .clear
        backBtn.addChild(backBG)
        let backLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        backLabel.text = "← Back"
        backLabel.fontSize = 14
        backLabel.fontColor = .white
        backLabel.verticalAlignmentMode = .center
        backBtn.addChild(backLabel)
        addChild(backBtn)

        // Level grid (2 columns, 5 rows)
        let columns = 2
        let buttonSize: CGFloat = 120
        let spacing: CGFloat = 20
        let totalWidth = CGFloat(columns) * buttonSize + CGFloat(columns - 1) * spacing
        let startX = (size.width - totalWidth) / 2 + buttonSize / 2
        let startY = size.height - 160

        for level in 1...10 {
            let row = (level - 1) / columns
            let col = (level - 1) % columns

            let x = startX + CGFloat(col) * (buttonSize + spacing)
            let y = startY - CGFloat(row) * (buttonSize + spacing)

            let isUnlocked = level <= progress.highestUnlockedLevel
            let levelProg = progress.levelProgress[level]

            let btn = createLevelButton(
                level: level,
                unlocked: isUnlocked,
                stars: levelProg?.stars ?? 0,
                bestScore: levelProg?.bestScore ?? 0,
                buttonSize: buttonSize
            )
            btn.position = CGPoint(x: x, y: y)
            btn.name = "level_\(level)"
            addChild(btn)
        }
    }

    func createLevelButton(level: Int, unlocked: Bool, stars: Int, bestScore: Int, buttonSize: CGFloat) -> SKNode {
        let container = SKNode()

        let bg = SKShapeNode(rectOf: CGSize(width: buttonSize, height: buttonSize), cornerRadius: 12)
        if unlocked {
            bg.fillColor = SKColor(red: 0.2, green: 0.3, blue: 0.5, alpha: 1.0)
            bg.strokeColor = SKColor(red: 0.4, green: 0.6, blue: 0.9, alpha: 0.8)
        } else {
            bg.fillColor = SKColor(white: 0.2, alpha: 0.8)
            bg.strokeColor = SKColor(white: 0.3, alpha: 0.5)
        }
        bg.lineWidth = 2
        container.addChild(bg)

        // Level number
        let numLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        numLabel.text = "\(level)"
        numLabel.fontSize = 32
        numLabel.fontColor = unlocked ? .white : SKColor(white: 0.4, alpha: 1.0)
        numLabel.verticalAlignmentMode = .center
        numLabel.position = CGPoint(x: 0, y: 10)
        container.addChild(numLabel)

        if unlocked {
            // Stars
            let starsLabel = SKLabelNode(fontNamed: "AvenirNext-Regular")
            starsLabel.text = String(repeating: "⭐", count: stars) + String(repeating: "☆", count: 3 - stars)
            starsLabel.fontSize = 14
            starsLabel.position = CGPoint(x: 0, y: -20)
            container.addChild(starsLabel)

            // Goal type indicator
            if let config = LevelManager.shared.config(for: level) {
                let typeLabel = SKLabelNode(fontNamed: "AvenirNext-Regular")
                typeLabel.text = config.goalType == .scoreTimed ? "⏱ Score" : "❄️ Ice"
                typeLabel.fontSize = 11
                typeLabel.fontColor = SKColor(white: 0.6, alpha: 1.0)
                typeLabel.position = CGPoint(x: 0, y: -38)
                container.addChild(typeLabel)
            }
        } else {
            // Lock icon
            let lockLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
            lockLabel.text = "🔒"
            lockLabel.fontSize = 20
            lockLabel.position = CGPoint(x: 0, y: -20)
            container.addChild(lockLabel)
        }

        return container
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        // Back button
        if let backBtn = childNode(withName: "backButton") {
            let rect = CGRect(x: backBtn.position.x - 30, y: backBtn.position.y - 17, width: 60, height: 35)
            if rect.contains(location) {
                let scene = MainMenuScene(size: size)
                scene.scaleMode = scaleMode
                view?.presentScene(scene, transition: SKTransition.fade(withDuration: 0.3))
                return
            }
        }

        // Level buttons
        for level in 1...10 {
            guard level <= progress.highestUnlockedLevel else { continue }
            if let btn = childNode(withName: "level_\(level)") {
                let rect = CGRect(x: btn.position.x - 60, y: btn.position.y - 60, width: 120, height: 120)
                if rect.contains(location) {
                    startLevel(level)
                    return
                }
            }
        }
    }

    func startLevel(_ level: Int) {
        guard let config = LevelManager.shared.config(for: level) else { return }

        let scene = GameScene(size: size)
        scene.scaleMode = scaleMode
        scene.configure(with: config, progress: progress)
        view?.presentScene(scene, transition: SKTransition.fade(withDuration: 0.5))
    }
}
