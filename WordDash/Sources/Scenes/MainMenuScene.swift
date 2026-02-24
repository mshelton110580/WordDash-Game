import SpriteKit

// MARK: - MainMenuScene

class MainMenuScene: SKScene {

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.1, green: 0.1, blue: 0.2, alpha: 1.0)
        setupUI()
    }

    func setupUI() {
        // Title
        let titleLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        titleLabel.text = "WordDash"
        titleLabel.fontSize = 48
        titleLabel.fontColor = SKColor(red: 1.0, green: 0.85, blue: 0.0, alpha: 1.0)
        titleLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.7)
        addChild(titleLabel)

        // Subtitle
        let subtitleLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        subtitleLabel.text = "Swipe. Spell. Score."
        subtitleLabel.fontSize = 18
        subtitleLabel.fontColor = SKColor(white: 0.7, alpha: 1.0)
        subtitleLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.7 - 40)
        addChild(subtitleLabel)

        // Play Button
        let playBtn = createMenuButton(text: "Play", color: SKColor(red: 0.2, green: 0.7, blue: 0.3, alpha: 1.0))
        playBtn.position = CGPoint(x: size.width / 2, y: size.height * 0.45)
        playBtn.name = "playButton"
        addChild(playBtn)

        // Store Button (stub)
        let storeBtn = createMenuButton(text: "Store", color: SKColor(red: 0.3, green: 0.5, blue: 0.8, alpha: 1.0))
        storeBtn.position = CGPoint(x: size.width / 2, y: size.height * 0.35)
        storeBtn.name = "storeButton"
        addChild(storeBtn)

        // Settings Button
        let settingsBtn = createMenuButton(text: "Settings", color: SKColor(red: 0.5, green: 0.4, blue: 0.6, alpha: 1.0))
        settingsBtn.position = CGPoint(x: size.width / 2, y: size.height * 0.25)
        settingsBtn.name = "settingsButton"
        addChild(settingsBtn)

        // Version label
        let versionLabel = SKLabelNode(fontNamed: "AvenirNext-Regular")
        versionLabel.text = "MVP v1.0"
        versionLabel.fontSize = 12
        versionLabel.fontColor = SKColor(white: 0.4, alpha: 1.0)
        versionLabel.position = CGPoint(x: size.width / 2, y: 30)
        addChild(versionLabel)

        // Decorative tiles animation
        addDecorativeTiles()
    }

    func createMenuButton(text: String, color: SKColor) -> SKNode {
        let container = SKNode()

        let bg = SKShapeNode(rectOf: CGSize(width: 220, height: 50), cornerRadius: 12)
        bg.fillColor = color
        bg.strokeColor = SKColor(white: 1.0, alpha: 0.2)
        bg.lineWidth = 1
        container.addChild(bg)

        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = text
        label.fontSize = 22
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        container.addChild(label)

        return container
    }

    func addDecorativeTiles() {
        let letters = "WORDDASH"
        let startX = (size.width - CGFloat(letters.count) * 40) / 2 + 20

        for (i, char) in letters.enumerated() {
            let tile = SKShapeNode(rectOf: CGSize(width: 35, height: 35), cornerRadius: 6)
            tile.fillColor = SKColor(red: 0.25, green: 0.3, blue: 0.5, alpha: 0.8)
            tile.strokeColor = SKColor(white: 0.4, alpha: 0.3)
            tile.position = CGPoint(x: startX + CGFloat(i) * 40, y: size.height * 0.55)
            addChild(tile)

            let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
            label.text = String(char)
            label.fontSize = 18
            label.fontColor = .white
            label.verticalAlignmentMode = .center
            label.position = tile.position
            addChild(label)

            // Gentle bounce animation
            let delay = SKAction.wait(forDuration: Double(i) * 0.1)
            let bounce = SKAction.sequence([
                SKAction.moveBy(x: 0, y: 5, duration: 0.5),
                SKAction.moveBy(x: 0, y: -5, duration: 0.5)
            ])
            tile.run(SKAction.sequence([delay, SKAction.repeatForever(bounce)]))
        }
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        if isButtonTapped(name: "playButton", at: location) {
            let scene = LevelMapScene(size: size)
            scene.scaleMode = scaleMode
            view?.presentScene(scene, transition: SKTransition.fade(withDuration: 0.5))
        } else if isButtonTapped(name: "storeButton", at: location) {
            showStoreStub()
        } else if isButtonTapped(name: "settingsButton", at: location) {
            showSettings()
        }
    }

    func isButtonTapped(name: String, at location: CGPoint) -> Bool {
        guard let btn = childNode(withName: name) else { return false }
        let rect = CGRect(x: btn.position.x - 110, y: btn.position.y - 25, width: 220, height: 50)
        return rect.contains(location)
    }

    func showStoreStub() {
        // Simple popup
        let overlay = SKShapeNode(rectOf: size)
        overlay.fillColor = SKColor(white: 0, alpha: 0.6)
        overlay.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.zPosition = 100
        overlay.name = "storeOverlay"
        addChild(overlay)

        let panel = SKShapeNode(rectOf: CGSize(width: 250, height: 150), cornerRadius: 15)
        panel.fillColor = SKColor(red: 0.15, green: 0.15, blue: 0.3, alpha: 1.0)
        panel.strokeColor = SKColor(white: 0.5, alpha: 0.5)
        panel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        panel.zPosition = 101
        panel.name = "storePanel"
        addChild(panel)

        let label = SKLabelNode(fontNamed: "AvenirNext-Medium")
        label.text = "Store Coming Soon!"
        label.fontSize = 20
        label.fontColor = .white
        label.position = CGPoint(x: 0, y: 20)
        panel.addChild(label)

        let closeBtn = SKLabelNode(fontNamed: "AvenirNext-Bold")
        closeBtn.text = "OK"
        closeBtn.fontSize = 18
        closeBtn.fontColor = .yellow
        closeBtn.position = CGPoint(x: 0, y: -30)
        closeBtn.name = "closeStore"
        panel.addChild(closeBtn)

        // Auto-close on tap
        overlay.run(SKAction.sequence([
            SKAction.wait(forDuration: 2.0),
            SKAction.run { [weak self] in
                self?.childNode(withName: "storeOverlay")?.removeFromParent()
                self?.childNode(withName: "storePanel")?.removeFromParent()
            }
        ]))
    }

    func showSettings() {
        let scene = SettingsScene(size: size)
        scene.scaleMode = scaleMode
        view?.presentScene(scene, transition: SKTransition.fade(withDuration: 0.3))
    }
}
