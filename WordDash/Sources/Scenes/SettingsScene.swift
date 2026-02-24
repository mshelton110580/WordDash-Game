import SpriteKit

// MARK: - SettingsScene

class SettingsScene: SKScene {

    var progress: PlayerProgress!
    var soundToggle: SKNode!
    var hapticsToggle: SKNode!

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.1, green: 0.1, blue: 0.2, alpha: 1.0)
        progress = PersistenceManager.shared.loadProgress()
        setupUI()
    }

    func setupUI() {
        // Title
        let titleLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        titleLabel.text = "Settings"
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

        // Sound toggle
        soundToggle = createToggle(label: "Sound", isOn: progress.soundEnabled, yPos: size.height - 180)
        soundToggle.name = "soundToggle"
        addChild(soundToggle)

        // Haptics toggle
        hapticsToggle = createToggle(label: "Haptics", isOn: progress.hapticsEnabled, yPos: size.height - 250)
        hapticsToggle.name = "hapticsToggle"
        addChild(hapticsToggle)

        // Reset Progress button
        let resetBtn = SKNode()
        resetBtn.name = "resetButton"
        resetBtn.position = CGPoint(x: size.width / 2, y: size.height - 380)

        let resetBG = SKShapeNode(rectOf: CGSize(width: 220, height: 44), cornerRadius: 10)
        resetBG.fillColor = SKColor(red: 0.8, green: 0.2, blue: 0.2, alpha: 1.0)
        resetBG.strokeColor = .clear
        resetBtn.addChild(resetBG)

        let resetLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        resetLabel.text = "Reset Progress"
        resetLabel.fontSize = 18
        resetLabel.fontColor = .white
        resetLabel.verticalAlignmentMode = .center
        resetBtn.addChild(resetLabel)

        addChild(resetBtn)
    }

    func createToggle(label: String, isOn: Bool, yPos: CGFloat) -> SKNode {
        let container = SKNode()
        container.position = CGPoint(x: size.width / 2, y: yPos)

        let textLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        textLabel.text = label
        textLabel.fontSize = 22
        textLabel.fontColor = .white
        textLabel.horizontalAlignmentMode = .left
        textLabel.position = CGPoint(x: -100, y: -8)
        container.addChild(textLabel)

        let toggleBG = SKShapeNode(rectOf: CGSize(width: 60, height: 30), cornerRadius: 15)
        toggleBG.fillColor = isOn ? SKColor(red: 0.2, green: 0.7, blue: 0.3, alpha: 1.0) : SKColor(white: 0.3, alpha: 1.0)
        toggleBG.strokeColor = .clear
        toggleBG.position = CGPoint(x: 80, y: 0)
        toggleBG.name = "toggleBG"
        container.addChild(toggleBG)

        let knob = SKShapeNode(circleOfRadius: 12)
        knob.fillColor = .white
        knob.strokeColor = .clear
        knob.position = CGPoint(x: isOn ? 95 : 65, y: 0)
        knob.name = "toggleKnob"
        container.addChild(knob)

        return container
    }

    func updateToggle(_ toggle: SKNode, isOn: Bool) {
        if let bg = toggle.childNode(withName: "toggleBG") as? SKShapeNode {
            bg.fillColor = isOn ? SKColor(red: 0.2, green: 0.7, blue: 0.3, alpha: 1.0) : SKColor(white: 0.3, alpha: 1.0)
        }
        if let knob = toggle.childNode(withName: "toggleKnob") {
            let targetX: CGFloat = isOn ? 95 : 65
            knob.run(SKAction.moveTo(x: targetX, duration: 0.2))
        }
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

        // Sound toggle
        if let toggle = childNode(withName: "soundToggle") {
            let rect = CGRect(x: toggle.position.x - 110, y: toggle.position.y - 20, width: 220, height: 40)
            if rect.contains(location) {
                progress.soundEnabled.toggle()
                updateToggle(toggle, isOn: progress.soundEnabled)
                PersistenceManager.shared.saveProgress(progress)
                return
            }
        }

        // Haptics toggle
        if let toggle = childNode(withName: "hapticsToggle") {
            let rect = CGRect(x: toggle.position.x - 110, y: toggle.position.y - 20, width: 220, height: 40)
            if rect.contains(location) {
                progress.hapticsEnabled.toggle()
                updateToggle(toggle, isOn: progress.hapticsEnabled)
                PersistenceManager.shared.saveProgress(progress)
                return
            }
        }

        // Reset button
        if let resetBtn = childNode(withName: "resetButton") {
            let rect = CGRect(x: resetBtn.position.x - 110, y: resetBtn.position.y - 22, width: 220, height: 44)
            if rect.contains(location) {
                PersistenceManager.shared.resetProgress()
                progress = PersistenceManager.shared.loadProgress()
                // Show confirmation
                let confirm = SKLabelNode(fontNamed: "AvenirNext-Bold")
                confirm.text = "Progress Reset!"
                confirm.fontSize = 18
                confirm.fontColor = .red
                confirm.position = CGPoint(x: size.width / 2, y: resetBtn.position.y - 40)
                addChild(confirm)
                confirm.run(SKAction.sequence([
                    SKAction.wait(forDuration: 2.0),
                    SKAction.fadeOut(withDuration: 0.5),
                    SKAction.removeFromParent()
                ]))
                return
            }
        }
    }
}
