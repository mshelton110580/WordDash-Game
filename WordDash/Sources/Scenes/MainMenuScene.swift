import SpriteKit

// MARK: - MainMenuScene

class MainMenuScene: SKScene {

    private var coinLabel: SKLabelNode!

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.1, green: 0.1, blue: 0.2, alpha: 1.0)
        setupUI()
        checkDailyLogin()
        checkFirstLaunchTutorial()
        NotificationCenter.default.addObserver(self, selector: #selector(updateCoinDisplay), name: .coinBalanceChanged, object: nil)
    }

    func setupUI() {
        // Coin display (top right)
        coinLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        coinLabel.text = "🪙 \(CoinManager.shared.balance)"
        coinLabel.fontSize = 18
        coinLabel.fontColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)
        coinLabel.horizontalAlignmentMode = .right
        coinLabel.position = CGPoint(x: size.width - 20, y: size.height - 40)
        coinLabel.zPosition = 10
        addChild(coinLabel)

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

        // Store Button (now functional)
        let storeBtn = createMenuButton(text: "🛒 Store", color: SKColor(red: 0.3, green: 0.5, blue: 0.8, alpha: 1.0))
        storeBtn.position = CGPoint(x: size.width / 2, y: size.height * 0.35)
        storeBtn.name = "storeButton"
        addChild(storeBtn)

        // Settings Button
        let settingsBtn = createMenuButton(text: "Settings", color: SKColor(red: 0.5, green: 0.4, blue: 0.6, alpha: 1.0))
        settingsBtn.position = CGPoint(x: size.width / 2, y: size.height * 0.25)
        settingsBtn.name = "settingsButton"
        addChild(settingsBtn)

        // Stats Button
        let statsBtn = createMenuButton(text: "📊 Stats", color: SKColor(red: 0.25, green: 0.5, blue: 0.45, alpha: 1.0))
        statsBtn.position = CGPoint(x: size.width / 2, y: size.height * 0.15)
        statsBtn.name = "statsButton"
        addChild(statsBtn)

        // Version label
        let versionLabel = SKLabelNode(fontNamed: "AvenirNext-Regular")
        versionLabel.text = "MVP v1.1"
        versionLabel.fontSize = 12
        versionLabel.fontColor = SKColor(white: 0.4, alpha: 1.0)
        versionLabel.position = CGPoint(x: size.width / 2, y: 30)
        addChild(versionLabel)

        // Decorative tiles animation
        addDecorativeTiles()
    }

    func checkFirstLaunchTutorial() {
        let seen = UserDefaults.standard.bool(forKey: "worddash_tutorial_seen")
        guard !seen else { return }

        // Show tutorial 0.8s after menu appears
        run(SKAction.wait(forDuration: 0.8)) { [weak self] in
            guard let self = self else { return }
            let tutorial = TutorialScene(size: self.size)
            tutorial.scaleMode = .aspectFill
            tutorial.zPosition = 300
            tutorial.onDismiss = { /* nothing needed — tutorial marks itself seen */ }
            // Present as overlay by adding as child scene isn't typical in SpriteKit,
            // so present as a new scene transition with a dim fade.
            let overlay = SKNode()
            overlay.zPosition = 250
            self.addChild(overlay)

            let tutScene = TutorialScene(size: self.size)
            tutScene.scaleMode = self.scaleMode
            tutScene.onDismiss = { [weak overlay] in
                overlay?.removeFromParent()
            }
            self.view?.presentScene(tutScene, transition: SKTransition.fade(withDuration: 0.3))
        }
    }

    func checkDailyLogin() {
        let result = DailyLoginManager.shared.checkDailyReward()
        if result.canClaim {
            let overlay = DailyLoginOverlay(size: size, day: result.day, amount: result.amount) { [weak self] in
                self?.updateCoinDisplay()
            }
            overlay.zPosition = 200
            addChild(overlay)
        }
    }

    @objc func updateCoinDisplay() {
        coinLabel?.text = "🪙 \(CoinManager.shared.balance)"
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
            let scene = StoreScene(size: size)
            scene.scaleMode = scaleMode
            view?.presentScene(scene, transition: SKTransition.fade(withDuration: 0.3))
        } else if isButtonTapped(name: "settingsButton", at: location) {
            showSettings()
        } else if isButtonTapped(name: "statsButton", at: location) {
            let scene = StatsScene(size: size)
            scene.scaleMode = scaleMode
            view?.presentScene(scene, transition: SKTransition.fade(withDuration: 0.3))
        }
    }

    func isButtonTapped(name: String, at location: CGPoint) -> Bool {
        guard let btn = childNode(withName: name) else { return false }
        let rect = CGRect(x: btn.position.x - 110, y: btn.position.y - 25, width: 220, height: 50)
        return rect.contains(location)
    }

    func showSettings() {
        let scene = SettingsScene(size: size)
        scene.scaleMode = scaleMode
        view?.presentScene(scene, transition: SKTransition.fade(withDuration: 0.3))
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
