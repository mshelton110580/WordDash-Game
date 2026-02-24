import SpriteKit

/// Overlay scene/node for displaying the daily login reward.
/// Presented as a modal overlay on the main menu.
class DailyLoginOverlay: SKNode {

    private let overlaySize: CGSize
    private var onDismiss: (() -> Void)?

    init(size: CGSize, day: Int, amount: Int, onDismiss: @escaping () -> Void) {
        self.overlaySize = size
        self.onDismiss = onDismiss
        super.init()
        self.isUserInteractionEnabled = true
        setupUI(day: day, amount: amount)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI(day: Int, amount: Int) {
        // Dimmed background
        let dimBg = SKShapeNode(rectOf: overlaySize)
        dimBg.fillColor = SKColor(white: 0.0, alpha: 0.7)
        dimBg.strokeColor = .clear
        dimBg.position = CGPoint(x: overlaySize.width / 2, y: overlaySize.height / 2)
        dimBg.name = "dimBg"
        addChild(dimBg)

        // Card
        let cardWidth: CGFloat = 300
        let cardHeight: CGFloat = 280
        let card = SKShapeNode(rectOf: CGSize(width: cardWidth, height: cardHeight), cornerRadius: 16)
        card.fillColor = SKColor(red: 0.12, green: 0.10, blue: 0.25, alpha: 0.95)
        card.strokeColor = SKColor(red: 0.92, green: 0.69, blue: 0.0, alpha: 0.5)
        card.lineWidth = 2
        card.position = CGPoint(x: overlaySize.width / 2, y: overlaySize.height / 2)
        addChild(card)

        // Gift icon
        let giftIcon = SKLabelNode(text: "🎁")
        giftIcon.fontSize = 40
        giftIcon.position = CGPoint(x: 0, y: 80)
        card.addChild(giftIcon)

        // Title
        let title = SKLabelNode(fontNamed: "AvenirNext-Bold")
        title.text = "Daily Login Reward"
        title.fontSize = 22
        title.fontColor = .white
        title.position = CGPoint(x: 0, y: 45)
        card.addChild(title)

        // Day indicator
        let dayLabel = SKLabelNode(fontNamed: "AvenirNext-Regular")
        dayLabel.text = "Day \(day) of 7"
        dayLabel.fontSize = 14
        dayLabel.fontColor = SKColor(white: 0.7, alpha: 1.0)
        dayLabel.position = CGPoint(x: 0, y: 20)
        card.addChild(dayLabel)

        // Day circles
        let rewards = GameEconomyConfig.dailyRewards
        let circleSpacing: CGFloat = 38
        let startX = -CGFloat(rewards.count - 1) / 2.0 * circleSpacing
        for i in 0..<rewards.count {
            let x = startX + CGFloat(i) * circleSpacing
            let circle = SKShapeNode(circleOfRadius: 14)
            if i + 1 < day {
                circle.fillColor = SKColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1.0)
            } else if i + 1 == day {
                circle.fillColor = SKColor(red: 0.92, green: 0.69, blue: 0.0, alpha: 1.0)
            } else {
                circle.fillColor = SKColor(white: 0.2, alpha: 1.0)
            }
            circle.strokeColor = .clear
            circle.position = CGPoint(x: x, y: -15)
            card.addChild(circle)

            let dLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
            dLabel.text = "D\(i + 1)"
            dLabel.fontSize = 8
            dLabel.fontColor = .white
            dLabel.verticalAlignmentMode = .center
            dLabel.position = CGPoint(x: x, y: -10)
            card.addChild(dLabel)

            let rLabel = SKLabelNode(fontNamed: "AvenirNext-Regular")
            rLabel.text = "\(rewards[i])"
            rLabel.fontSize = 7
            rLabel.fontColor = .white
            rLabel.verticalAlignmentMode = .center
            rLabel.position = CGPoint(x: x, y: -22)
            card.addChild(rLabel)
        }

        // Amount
        let amountLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        amountLabel.text = "+\(amount) 🪙"
        amountLabel.fontSize = 28
        amountLabel.fontColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)
        amountLabel.position = CGPoint(x: 0, y: -55)
        card.addChild(amountLabel)

        // Claim button
        let claimBtn = SKShapeNode(rectOf: CGSize(width: 220, height: 44), cornerRadius: 22)
        claimBtn.fillColor = SKColor(red: 0.92, green: 0.69, blue: 0.0, alpha: 1.0)
        claimBtn.strokeColor = .clear
        claimBtn.position = CGPoint(x: 0, y: -100)
        claimBtn.name = "claimButton"
        card.addChild(claimBtn)

        let claimLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        claimLabel.text = "Claim Reward"
        claimLabel.fontSize = 18
        claimLabel.fontColor = SKColor(red: 0.15, green: 0.1, blue: 0.0, alpha: 1.0)
        claimLabel.verticalAlignmentMode = .center
        claimBtn.addChild(claimLabel)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let tappedNodes = nodes(at: location)

        for node in tappedNodes {
            if node.name == "claimButton" || node.parent?.name == "claimButton" {
                DailyLoginManager.shared.claimDailyReward()
                dismiss()
                return
            }
            if node.name == "dimBg" {
                // Tapping outside the card also claims and dismisses
                DailyLoginManager.shared.claimDailyReward()
                dismiss()
                return
            }
        }
    }

    private func dismiss() {
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        let remove = SKAction.removeFromParent()
        run(SKAction.sequence([fadeOut, remove]))
        onDismiss?()
    }
}
