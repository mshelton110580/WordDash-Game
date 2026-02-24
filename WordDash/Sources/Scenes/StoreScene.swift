import SpriteKit

/// Power-Up Store scene where players can purchase power-ups with coins.
class StoreScene: SKScene {

    private var coinLabel: SKLabelNode!

    struct StoreItem {
        let key: String
        let name: String
        let icon: String
        let description: String
        let price: Int
    }

    private let items: [StoreItem] = [
        StoreItem(key: "hint", name: "Hint", icon: "💡", description: "Highlights a valid word", price: GameEconomyConfig.storePrices["hint"] ?? 50),
        StoreItem(key: "bomb", name: "Bomb", icon: "💣", description: "Places a bomb tile (3×3)", price: GameEconomyConfig.storePrices["bomb"] ?? 75),
        StoreItem(key: "laser", name: "Laser", icon: "⚡", description: "Places a laser tile (row/col)", price: GameEconomyConfig.storePrices["laser"] ?? 100),
        StoreItem(key: "crossLaser", name: "Cross Laser", icon: "✦", description: "Places cross laser (row+col)", price: GameEconomyConfig.storePrices["crossLaser"] ?? 150),
        StoreItem(key: "mine", name: "Mine", icon: "💥", description: "Places a mine tile", price: GameEconomyConfig.storePrices["mine"] ?? 125),
    ]

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.08, green: 0.06, blue: 0.15, alpha: 1.0)
        setupUI()
        NotificationCenter.default.addObserver(self, selector: #selector(updateCoinDisplay), name: .coinBalanceChanged, object: nil)
    }

    private func setupUI() {
        let titleLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        titleLabel.text = "Power-Up Store"
        titleLabel.fontSize = 28
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: size.width / 2, y: size.height - 80)
        addChild(titleLabel)

        // Coin display
        coinLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        coinLabel.text = "🪙 \(CoinManager.shared.balance)"
        coinLabel.fontSize = 20
        coinLabel.fontColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)
        coinLabel.position = CGPoint(x: size.width - 80, y: size.height - 80)
        addChild(coinLabel)

        // Back button
        let backLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        backLabel.text = "← Back"
        backLabel.fontSize = 18
        backLabel.fontColor = .white
        backLabel.position = CGPoint(x: 60, y: size.height - 80)
        backLabel.name = "backButton"
        addChild(backLabel)

        // Store items
        let startY = size.height - 140
        let itemHeight: CGFloat = 90

        for (index, item) in items.enumerated() {
            let y = startY - CGFloat(index) * itemHeight
            createStoreRow(item: item, at: CGPoint(x: size.width / 2, y: y), index: index)
        }
    }

    private func createStoreRow(item: StoreItem, at position: CGPoint, index: Int) {
        let rowWidth = size.width - 60
        let bg = SKShapeNode(rectOf: CGSize(width: rowWidth, height: 70), cornerRadius: 12)
        bg.position = position
        bg.fillColor = SKColor(white: 1.0, alpha: 0.08)
        bg.strokeColor = SKColor(white: 1.0, alpha: 0.15)
        bg.lineWidth = 1
        bg.name = "storeItem_\(index)"
        addChild(bg)

        // Icon
        let icon = SKLabelNode(text: item.icon)
        icon.fontSize = 28
        icon.position = CGPoint(x: -rowWidth / 2 + 35, y: -10)
        bg.addChild(icon)

        // Name + count
        let progress = PersistenceManager.shared.loadProgress()
        let count = progress.powerUpInventory[item.key] ?? 0
        let nameLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        nameLabel.text = "\(item.name)  ×\(count)"
        nameLabel.fontSize = 16
        nameLabel.fontColor = .white
        nameLabel.horizontalAlignmentMode = .left
        nameLabel.position = CGPoint(x: -rowWidth / 2 + 65, y: 5)
        bg.addChild(nameLabel)

        // Description
        let descLabel = SKLabelNode(fontNamed: "AvenirNext-Regular")
        descLabel.text = item.description
        descLabel.fontSize = 12
        descLabel.fontColor = SKColor(white: 0.7, alpha: 1.0)
        descLabel.horizontalAlignmentMode = .left
        descLabel.position = CGPoint(x: -rowWidth / 2 + 65, y: -15)
        bg.addChild(descLabel)

        // Price button
        let priceBtn = SKShapeNode(rectOf: CGSize(width: 80, height: 32), cornerRadius: 16)
        priceBtn.fillColor = SKColor(red: 0.92, green: 0.69, blue: 0.0, alpha: 1.0)
        priceBtn.strokeColor = .clear
        priceBtn.position = CGPoint(x: rowWidth / 2 - 55, y: 0)
        priceBtn.name = "buyButton_\(index)"
        bg.addChild(priceBtn)

        let priceLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        priceLabel.text = "🪙 \(item.price)"
        priceLabel.fontSize = 14
        priceLabel.fontColor = SKColor(red: 0.15, green: 0.1, blue: 0.0, alpha: 1.0)
        priceLabel.verticalAlignmentMode = .center
        priceBtn.addChild(priceLabel)
    }

    @objc private func updateCoinDisplay() {
        coinLabel?.text = "🪙 \(CoinManager.shared.balance)"
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let tappedNodes = nodes(at: location)

        for node in tappedNodes {
            if node.name == "backButton" {
                let menu = MainMenuScene(size: size)
                menu.scaleMode = .aspectFill
                view?.presentScene(menu, transition: .fade(withDuration: 0.3))
                return
            }

            if let name = node.name, name.hasPrefix("buyButton_") || name.hasPrefix("storeItem_") {
                let indexStr = name.split(separator: "_").last.flatMap { String($0) } ?? ""
                if let index = Int(indexStr), index < items.count {
                    purchaseItem(at: index)
                    return
                }
            }

            // Check parent nodes too
            if let parentName = node.parent?.name {
                if parentName.hasPrefix("buyButton_") || parentName.hasPrefix("storeItem_") {
                    let indexStr = parentName.split(separator: "_").last.flatMap { String($0) } ?? ""
                    if let index = Int(indexStr), index < items.count {
                        purchaseItem(at: index)
                        return
                    }
                }
            }
        }
    }

    private func purchaseItem(at index: Int) {
        let item = items[index]
        guard CoinManager.shared.canAfford(item.price) else {
            showMessage("Not enough coins!")
            return
        }

        CoinManager.shared.spendCoins(item.price, reason: .storePurchase)

        var progress = PersistenceManager.shared.loadProgress()
        progress.powerUpInventory[item.key, default: 0] += 1
        PersistenceManager.shared.saveProgress(progress)

        // Refresh the scene
        removeAllChildren()
        setupUI()
        showMessage("\(item.name) purchased!")
    }

    private func showMessage(_ text: String) {
        let msg = SKLabelNode(fontNamed: "AvenirNext-Bold")
        msg.text = text
        msg.fontSize = 20
        msg.fontColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)
        msg.position = CGPoint(x: size.width / 2, y: 60)
        msg.alpha = 0
        addChild(msg)

        let fadeIn = SKAction.fadeIn(withDuration: 0.2)
        let wait = SKAction.wait(forDuration: 1.5)
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        let remove = SKAction.removeFromParent()
        msg.run(SKAction.sequence([fadeIn, wait, fadeOut, remove]))
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
