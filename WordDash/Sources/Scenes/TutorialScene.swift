import SpriteKit

// MARK: - TutorialScene
// 6-step paginated tutorial overlay shown on first launch.
// Mirrors web TutorialOverlay component.

class TutorialScene: SKScene {

    // MARK: - Tutorial Step Data

    struct TutorialStep {
        let emoji: String
        let title: String
        let body: String
    }

    private let steps: [TutorialStep] = [
        TutorialStep(emoji: "👆", title: "Drag to Spell",
                     body: "Touch and drag across adjacent tiles to spell words. Connect tiles in any of 8 directions including diagonals."),
        TutorialStep(emoji: "💥", title: "Words Clear the Board",
                     body: "Valid words explode the tiles and fill from the top. Tiles fall with gravity — chain reactions earn cascade bonuses!"),
        TutorialStep(emoji: "⚡", title: "Earn Special Tiles",
                     body: "Spell long words to earn powerful tiles. 5-letter words spawn Bombs, 6-letter Lasers, 7-letter Cross Lasers, 8+ Wildcards."),
        TutorialStep(emoji: "🔥", title: "Build Streaks",
                     body: "Submit words quickly to build a streak multiplier up to 3×. More points per word the hotter your streak!"),
        TutorialStep(emoji: "🎯", title: "Use Power-Ups",
                     body: "Tap a power-up icon then tap a tile to activate it. Hints highlight a word. Bombs, Lasers, and Mines clear large areas."),
        TutorialStep(emoji: "🪙", title: "Earn Coins",
                     body: "Complete levels to earn coins. Buy more power-ups in the Store. Daily login bonuses increase each consecutive day.")
    ]

    private var currentStep = 0
    private var contentNode: SKNode!
    private var stepDots: [SKShapeNode] = []

    // Callback when tutorial is dismissed
    var onDismiss: (() -> Void)?

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        // Semi-transparent backdrop
        backgroundColor = SKColor(red: 0.05, green: 0.03, blue: 0.12, alpha: 0.95)
        setupUI()
        showStep(currentStep, animated: false)
    }

    // MARK: - UI Setup

    private func setupUI() {
        // Card background
        let cardWidth = min(size.width - 40, 360)
        let cardHeight: CGFloat = 380
        let card = SKShapeNode(rectOf: CGSize(width: cardWidth, height: cardHeight), cornerRadius: 20)
        card.fillColor = SKColor(red: 0.13, green: 0.09, blue: 0.22, alpha: 1.0)
        card.strokeColor = SKColor(red: 0.5, green: 0.35, blue: 0.8, alpha: 0.4)
        card.lineWidth = 1.5
        card.position = CGPoint(x: size.width / 2, y: size.height / 2)
        card.name = "card"
        card.zPosition = 10
        addChild(card)

        // Title: "How to Play"
        let titleLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        titleLabel.text = "How to Play"
        titleLabel.fontSize = 22
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: 0, y: cardHeight / 2 - 36)
        titleLabel.zPosition = 1
        card.addChild(titleLabel)

        // Step dots
        let dotSpacing: CGFloat = 18
        let dotsStartX = -CGFloat(steps.count - 1) * dotSpacing / 2
        for i in 0..<steps.count {
            let dot = SKShapeNode(circleOfRadius: 5)
            dot.position = CGPoint(x: dotsStartX + CGFloat(i) * dotSpacing, y: -cardHeight / 2 + 52)
            dot.zPosition = 1
            dot.name = "dot_\(i)"
            card.addChild(dot)
            stepDots.append(dot)
        }

        // Content container (swappable)
        contentNode = SKNode()
        contentNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        contentNode.zPosition = 20
        addChild(contentNode)

        // Skip button
        let skipLabel = SKLabelNode(fontNamed: "AvenirNext-Regular")
        skipLabel.text = "Skip"
        skipLabel.fontSize = 14
        skipLabel.fontColor = SKColor(white: 0.5, alpha: 1.0)
        skipLabel.position = CGPoint(x: 0, y: -cardHeight / 2 + 20)
        skipLabel.name = "skipButton"
        skipLabel.zPosition = 1
        card.addChild(skipLabel)

        // Next / Done button
        let nextBtn = createButton(text: "Next →", width: 130, height: 44,
                                   color: SKColor(red: 0.4, green: 0.25, blue: 0.75, alpha: 1.0))
        nextBtn.position = CGPoint(x: 0, y: -cardHeight / 2 + 80)
        nextBtn.name = "nextButton"
        nextBtn.zPosition = 1
        card.addChild(nextBtn)

        updateDots()
    }

    // MARK: - Step Rendering

    private func showStep(_ index: Int, animated: Bool) {
        contentNode.removeAllChildren()

        let step = steps[index]
        let cardHeight: CGFloat = 380

        // Emoji
        let emojiLabel = SKLabelNode(text: step.emoji)
        emojiLabel.fontSize = 64
        emojiLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 + 80)
        emojiLabel.zPosition = 1
        contentNode.addChild(emojiLabel)

        // Step title
        let titleLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        titleLabel.text = step.title
        titleLabel.fontSize = 20
        titleLabel.fontColor = SKColor(red: 0.85, green: 0.7, blue: 1.0, alpha: 1.0)
        titleLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 + 20)
        titleLabel.zPosition = 1
        contentNode.addChild(titleLabel)

        // Body text — word-wrapped via multiple lines
        let bodyLines = wrapText(step.body, maxWidth: min(size.width - 80, 300), fontSize: 15)
        let lineHeight: CGFloat = 22
        let bodyStartY = size.height / 2 - 16
        for (i, line) in bodyLines.enumerated() {
            let lineLabel = SKLabelNode(fontNamed: "AvenirNext-Regular")
            lineLabel.text = line
            lineLabel.fontSize = 15
            lineLabel.fontColor = SKColor(white: 0.75, alpha: 1.0)
            lineLabel.position = CGPoint(x: size.width / 2, y: bodyStartY - CGFloat(i) * lineHeight)
            lineLabel.zPosition = 1
            contentNode.addChild(lineLabel)
        }

        // Update next button text
        let card = childNode(withName: "card")
        if let nextBtn = card?.childNode(withName: "nextButton"),
           let btnLabel = nextBtn.children.first(where: { ($0 as? SKLabelNode) != nil }) as? SKLabelNode {
            btnLabel.text = index == steps.count - 1 ? "Let's Play!" : "Next →"
        }

        if animated {
            contentNode.alpha = 0
            contentNode.run(SKAction.fadeIn(withDuration: 0.2))
        }

        updateDots()
    }

    private func updateDots() {
        for (i, dot) in stepDots.enumerated() {
            if i == currentStep {
                dot.fillColor = SKColor(red: 0.7, green: 0.5, blue: 1.0, alpha: 1.0)
                dot.strokeColor = .clear
            } else {
                dot.fillColor = SKColor(white: 0.3, alpha: 1.0)
                dot.strokeColor = .clear
            }
        }
    }

    // MARK: - Helpers

    private func createButton(text: String, width: CGFloat, height: CGFloat, color: SKColor) -> SKNode {
        let container = SKNode()
        let bg = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 10)
        bg.fillColor = color
        bg.strokeColor = .clear
        container.addChild(bg)

        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = text
        label.fontSize = 16
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        container.addChild(label)

        return container
    }

    /// Simple word-wrap: splits text into lines that fit within maxWidth.
    private func wrapText(_ text: String, maxWidth: CGFloat, fontSize: CGFloat) -> [String] {
        let words = text.split(separator: " ").map(String.init)
        var lines: [String] = []
        var current = ""
        // Approximate char width at given fontSize
        let charWidth = fontSize * 0.52

        for word in words {
            let testLine = current.isEmpty ? word : current + " " + word
            if CGFloat(testLine.count) * charWidth > maxWidth && !current.isEmpty {
                lines.append(current)
                current = word
            } else {
                current = testLine
            }
        }
        if !current.isEmpty { lines.append(current) }
        return lines
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let tapped = nodes(at: location)

        for node in tapped {
            let name = node.name ?? node.parent?.name ?? ""

            if name.contains("nextButton") {
                advanceStep()
                return
            }
            if name.contains("skipButton") || name.contains("dot_") {
                dismiss()
                return
            }
        }

        // Tap on dots to jump to step
        for (i, dot) in stepDots.enumerated() {
            let dotWorldPos = dot.parent?.convert(dot.position, to: self) ?? dot.position
            if hypot(location.x - dotWorldPos.x, location.y - dotWorldPos.y) < 15 {
                currentStep = i
                showStep(currentStep, animated: true)
                return
            }
        }
    }

    private func advanceStep() {
        if currentStep < steps.count - 1 {
            currentStep += 1
            showStep(currentStep, animated: true)
        } else {
            dismiss()
        }
    }

    private func dismiss() {
        // Mark tutorial as seen
        UserDefaults.standard.set(true, forKey: "worddash_tutorial_seen")
        UserDefaults.standard.synchronize()

        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        let remove = SKAction.run { [weak self] in
            self?.onDismiss?()
        }
        run(SKAction.sequence([fadeOut, remove]))
    }
}
