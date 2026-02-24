import SpriteKit
import GameplayKit

// MARK: - GameScene

class GameScene: SKScene {

    // MARK: - Properties

    var levelConfig: LevelConfig!
    var boardModel: BoardModel!
    var gameState: GameState!
    var powerUpSystem: PowerUpSystem!

    // Node layers
    var boardNode: SKNode!
    var hudNode: SKNode!
    var powerUpBar: SKNode!
    var effectsLayer: SKNode!

    // Tile sprite mapping
    var tileSprites: [UUID: SKNode] = [:]

    // Drag state
    var selectedPath: [TileModel] = []
    var dragDirections: [(dx: Int, dy: Int)] = []
    var selectionLine: SKShapeNode?
    var wordLabel: SKLabelNode!
    var isDragging = false

    // Power-up activation state
    var activePowerUp: PowerUpType?
    var powerUpButtons: [PowerUpType: SKNode] = [:]
    var powerUpCountLabels: [PowerUpType: SKLabelNode] = [:]

    // HUD elements
    var scoreLabel: SKLabelNode!
    var timerLabel: SKLabelNode!
    var goalLabel: SKLabelNode!
    var streakLabel: SKLabelNode!
    var movesLabel: SKLabelNode!

    // Timer
    var gameTimer: Timer?
    var lastUpdateTime: TimeInterval = 0

    // Layout
    var tileSize: CGFloat = 48
    var boardOriginX: CGFloat = 0
    var boardOriginY: CGFloat = 0

    // Hint highlight
    var hintNodes: [SKNode] = []

    // MARK: - Scene Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.15, green: 0.15, blue: 0.25, alpha: 1.0)

        setupLayout()
        setupBoard()
        setupHUD()
        setupPowerUpBar()
        setupEffectsLayer()
        setupWordLabel()
        renderBoard()

        // Load dictionary
        WordValidator.shared.loadDictionary()
        WordValidator.shared.loadProfanityList()

        // Load levels
        LevelManager.shared.loadAllLevels()
    }

    func configure(with config: LevelConfig, progress: PlayerProgress) {
        self.levelConfig = config
        self.gameState = GameState()
        self.gameState.reset(for: config)

        // Sync power-up inventory
        self.gameState.hintCount = progress.powerUpInventory.hintCount
        self.gameState.bombCount = progress.powerUpInventory.bombCount
        self.gameState.laserCount = progress.powerUpInventory.laserCount
        self.gameState.crossLaserCount = progress.powerUpInventory.crossLaserCount
        self.gameState.mineCount = progress.powerUpInventory.mineCount
    }

    // MARK: - Layout

    func setupLayout() {
        let safeWidth = size.width - 20
        let boardWidth = safeWidth
        tileSize = floor(boardWidth / CGFloat(GameConstants.boardSize)) - 2
        let totalBoardWidth = tileSize * CGFloat(GameConstants.boardSize)
        boardOriginX = (size.width - totalBoardWidth) / 2
        boardOriginY = 100 // bottom margin for power-up bar
    }

    // MARK: - Board Setup

    func setupBoard() {
        boardNode = SKNode()
        boardNode.position = CGPoint(x: boardOriginX, y: boardOriginY)
        boardNode.zPosition = 1
        addChild(boardNode)

        boardModel = BoardModel(rows: GameConstants.boardSize, cols: GameConstants.boardSize)

        if let config = levelConfig {
            boardModel.fillBoard(icePositions: config.icePositions)
        } else {
            boardModel.fillBoard()
        }

        if gameState == nil {
            gameState = GameState()
        }

        powerUpSystem = PowerUpSystem(gameState: gameState, boardModel: boardModel)
    }

    func setupEffectsLayer() {
        effectsLayer = SKNode()
        effectsLayer.zPosition = 100
        addChild(effectsLayer)
    }

    func setupWordLabel() {
        wordLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        wordLabel.fontSize = 28
        wordLabel.fontColor = .white
        wordLabel.position = CGPoint(x: size.width / 2, y: boardOriginY + tileSize * CGFloat(GameConstants.boardSize) + 10)
        wordLabel.zPosition = 50
        wordLabel.text = ""
        addChild(wordLabel)
    }

    // MARK: - Render Board

    func renderBoard() {
        // Remove old sprites
        boardNode.removeAllChildren()
        tileSprites.removeAll()

        for r in 0..<boardModel.rows {
            for c in 0..<boardModel.cols {
                if let tile = boardModel.tileAt(row: r, col: c) {
                    let sprite = createTileSprite(for: tile)
                    boardNode.addChild(sprite)
                    tileSprites[tile.id] = sprite
                }
            }
        }
    }

    func createTileSprite(for tile: TileModel) -> SKNode {
        let container = SKNode()
        container.position = positionForTile(row: tile.row, col: tile.col)
        container.name = "tile_\(tile.id.uuidString)"

        // Background
        let bg = SKShapeNode(rectOf: CGSize(width: tileSize - 2, height: tileSize - 2), cornerRadius: 6)
        bg.name = "tileBG"

        if let special = tile.specialType {
            switch special {
            case .bomb:
                bg.fillColor = SKColor(red: 1.0, green: 0.3, blue: 0.2, alpha: 1.0)
            case .laser:
                bg.fillColor = SKColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 1.0)
            case .crossLaser:
                bg.fillColor = SKColor(red: 0.8, green: 0.2, blue: 1.0, alpha: 1.0)
            case .mine:
                bg.fillColor = SKColor(red: 0.6, green: 0.6, blue: 0.2, alpha: 1.0)
            case .wildcard:
                bg.fillColor = SKColor(red: 1.0, green: 0.85, blue: 0.0, alpha: 1.0)
            }
        } else {
            bg.fillColor = SKColor(red: 0.25, green: 0.3, blue: 0.5, alpha: 1.0)
        }
        bg.strokeColor = SKColor(white: 0.4, alpha: 0.5)
        bg.lineWidth = 1
        bg.zPosition = 0
        container.addChild(bg)

        // Ice overlay
        if tile.isIced {
            let ice = SKShapeNode(rectOf: CGSize(width: tileSize - 2, height: tileSize - 2), cornerRadius: 6)
            ice.name = "iceOverlay"
            if tile.iceState == .intact {
                ice.fillColor = SKColor(red: 0.7, green: 0.9, blue: 1.0, alpha: 0.6)
            } else {
                ice.fillColor = SKColor(red: 0.7, green: 0.9, blue: 1.0, alpha: 0.3)
                // Add crack lines
                let crack = SKShapeNode()
                let path = CGMutablePath()
                path.move(to: CGPoint(x: -8, y: 8))
                path.addLine(to: CGPoint(x: 3, y: -2))
                path.addLine(to: CGPoint(x: -3, y: -8))
                path.move(to: CGPoint(x: 3, y: -2))
                path.addLine(to: CGPoint(x: 10, y: -6))
                crack.path = path
                crack.strokeColor = SKColor(white: 1.0, alpha: 0.8)
                crack.lineWidth = 1.5
                crack.zPosition = 2
                container.addChild(crack)
            }
            ice.strokeColor = SKColor(red: 0.5, green: 0.8, blue: 1.0, alpha: 0.8)
            ice.lineWidth = 2
            ice.zPosition = 1
            container.addChild(ice)
        }

        // Mine overlay
        if tile.hasMineOverlay {
            let mine = SKShapeNode(circleOfRadius: 6)
            mine.fillColor = .red
            mine.strokeColor = .darkGray
            mine.position = CGPoint(x: tileSize / 2 - 10, y: -tileSize / 2 + 10)
            mine.zPosition = 3
            mine.name = "mineOverlay"
            container.addChild(mine)
        }

        // Letter
        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.name = "letterLabel"
        if tile.specialType == .wildcard {
            label.text = "★"
            label.fontSize = tileSize * 0.5
        } else {
            label.text = String(tile.letter)
            label.fontSize = tileSize * 0.45
        }
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.zPosition = 5
        container.addChild(label)

        // Point value (small)
        if tile.specialType == nil {
            let pointLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
            let pts = GameConstants.letterValues[tile.letter] ?? 0
            pointLabel.text = "\(pts)"
            pointLabel.fontSize = tileSize * 0.2
            pointLabel.fontColor = SKColor(white: 0.8, alpha: 0.7)
            pointLabel.position = CGPoint(x: tileSize * 0.3, y: -tileSize * 0.3)
            pointLabel.verticalAlignmentMode = .center
            pointLabel.horizontalAlignmentMode = .center
            pointLabel.zPosition = 5
            container.addChild(pointLabel)
        }

        return container
    }

    func positionForTile(row: Int, col: Int) -> CGPoint {
        let x = CGFloat(col) * tileSize + tileSize / 2
        let y = CGFloat(boardModel.rows - 1 - row) * tileSize + tileSize / 2
        return CGPoint(x: x, y: y)
    }

    func tileAt(point: CGPoint) -> TileModel? {
        let boardPoint = CGPoint(x: point.x - boardOriginX, y: point.y - boardOriginY)
        let col = Int(boardPoint.x / tileSize)
        let row = boardModel.rows - 1 - Int(boardPoint.y / tileSize)
        return boardModel.tileAt(row: row, col: col)
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        // Start timer on first interaction (for scoreTimed)
        if let config = levelConfig, config.goalType == .scoreTimed, !gameState.timerStarted {
            gameState.timerStarted = true
            startTimer()
        }

        // Check if power-up button tapped
        if let powerUp = checkPowerUpTap(at: location) {
            handlePowerUpActivation(powerUp)
            return
        }

        // Check if active power-up needs a target
        if let active = activePowerUp {
            if let tile = tileAt(point: location) {
                executePowerUp(active, on: tile)
            }
            activePowerUp = nil
            return
        }

        // Check for back button
        if let node = atPoint(location) as? SKNode, node.name == "backButton" || node.parent?.name == "backButton" {
            goToLevelMap()
            return
        }

        // Start drag
        guard !gameState.isGameOver && !gameState.isLevelComplete else { return }
        clearHintHighlights()

        if let tile = tileAt(point: location) {
            isDragging = true
            selectedPath = [tile]
            dragDirections = []
            updateSelectionVisuals()
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isDragging, let touch = touches.first else { return }
        let location = touch.location(in: self)

        guard let tile = tileAt(point: location) else { return }

        // Backtracking: if dragged back to previous tile
        if selectedPath.count >= 2 && tile.id == selectedPath[selectedPath.count - 2].id {
            selectedPath.removeLast()
            if !dragDirections.isEmpty { dragDirections.removeLast() }
            updateSelectionVisuals()
            return
        }

        // Already in path
        if selectedPath.contains(where: { $0.id == tile.id }) { return }

        // Check adjacency
        guard let lastTile = selectedPath.last else { return }
        guard BoardModel.areAdjacent(lastTile, tile) else { return }

        // Record drag direction
        let dx = tile.col - lastTile.col
        let dy = tile.row - lastTile.row
        dragDirections.append((dx: dx, dy: dy))

        selectedPath.append(tile)
        updateSelectionVisuals()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isDragging else { return }
        isDragging = false

        if selectedPath.count >= GameConstants.minWordLength {
            attemptWord()
        } else {
            shakeSelection()
            clearSelection()
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        isDragging = false
        clearSelection()
    }

    // MARK: - Selection Visuals

    func updateSelectionVisuals() {
        // Remove old selection line
        selectionLine?.removeFromParent()

        guard selectedPath.count > 0 else {
            wordLabel.text = ""
            return
        }

        // Highlight selected tiles
        for (_, sprite) in tileSprites {
            if let bg = sprite.childNode(withName: "tileBG") as? SKShapeNode {
                // Reset non-selected tiles
                bg.glowWidth = 0
            }
        }

        for tile in selectedPath {
            if let sprite = tileSprites[tile.id],
               let bg = sprite.childNode(withName: "tileBG") as? SKShapeNode {
                bg.glowWidth = 4
            }
        }

        // Draw path line
        if selectedPath.count >= 2 {
            let path = CGMutablePath()
            let firstPos = positionForTile(row: selectedPath[0].row, col: selectedPath[0].col)
            path.move(to: CGPoint(x: firstPos.x, y: firstPos.y))

            for i in 1..<selectedPath.count {
                let pos = positionForTile(row: selectedPath[i].row, col: selectedPath[i].col)
                path.addLine(to: CGPoint(x: pos.x, y: pos.y))
            }

            let line = SKShapeNode(path: path)
            line.strokeColor = SKColor(red: 1.0, green: 0.85, blue: 0.0, alpha: 0.8)
            line.lineWidth = 3
            line.zPosition = 10
            line.lineCap = .round
            line.lineJoin = .round
            boardNode.addChild(line)
            selectionLine = line
        }

        // Update word label
        let word = selectedPath.map { tile -> String in
            if tile.specialType == .wildcard { return "?" }
            return String(tile.letter)
        }.joined()
        wordLabel.text = word
    }

    func clearSelection() {
        selectedPath.removeAll()
        dragDirections.removeAll()
        selectionLine?.removeFromParent()
        selectionLine = nil
        wordLabel.text = ""

        for (_, sprite) in tileSprites {
            if let bg = sprite.childNode(withName: "tileBG") as? SKShapeNode {
                bg.glowWidth = 0
            }
        }
    }

    func shakeSelection() {
        for tile in selectedPath {
            if let sprite = tileSprites[tile.id] {
                let shake = SKAction.sequence([
                    SKAction.moveBy(x: -5, y: 0, duration: 0.05),
                    SKAction.moveBy(x: 10, y: 0, duration: 0.05),
                    SKAction.moveBy(x: -10, y: 0, duration: 0.05),
                    SKAction.moveBy(x: 10, y: 0, duration: 0.05),
                    SKAction.moveBy(x: -5, y: 0, duration: 0.05)
                ])
                sprite.run(shake)
            }
        }
    }

    // MARK: - Word Attempt

    func attemptWord() {
        let hasWildcard = selectedPath.contains { $0.specialType == .wildcard }

        var isValid = false
        var resolvedWord = ""

        if hasWildcard {
            let result = WordValidator.shared.isValidWordWithWildcards(tiles: selectedPath)
            isValid = result.valid
            resolvedWord = result.resolvedWord
        } else {
            resolvedWord = WordValidator.shared.buildWord(from: selectedPath)
            isValid = WordValidator.shared.isValidWord(resolvedWord)
        }

        if !isValid {
            shakeSelection()
            clearSelection()
            return
        }

        // Valid word!
        processValidWord(resolvedWord)
    }

    func processValidWord(_ word: String) {
        // Calculate score
        let scoreResult = ScoringEngine.shared.calculateScore(tiles: selectedPath, gameState: gameState)
        gameState.score += scoreResult.totalScore

        // Track moves
        gameState.movesUsed += 1

        // Show score popup
        showScorePopup(scoreResult.totalScore, at: selectedPath.last!)

        // Determine special tile spawn
        let spawnType = GameConstants.specialTileForWordLength(selectedPath.count)
        let lastTile = selectedPath.last!
        let spawnInfo: (row: Int, col: Int, type: SpecialTileType)? = spawnType.map {
            (row: lastTile.row, col: lastTile.col, type: $0)
        }

        // Collect special tile effects
        let specialEvents = boardModel.processSpecialEffects(wordTiles: selectedPath, dragDirections: dragDirections)

        // Clear word tiles with explosion
        var allTilesToClear = selectedPath
        for event in specialEvents {
            for tile in event.tiles {
                if !allTilesToClear.contains(where: { $0.id == tile.id }) {
                    allTilesToClear.append(tile)
                }
            }
        }

        // Animate explosions
        animateExplosions(tiles: allTilesToClear) { [weak self] in
            guard let self = self else { return }

            // Actually clear from board
            let clearResult = self.boardModel.clearTiles(allTilesToClear)

            // Track ice clears
            for tile in clearResult.iceHits {
                if !tile.isIced { // ice was fully cleared
                    self.gameState.iceTilesCleared += 1
                }
            }

            // Check for mine triggers
            let triggeredMines = clearResult.removed.filter { $0.hasMineOverlay }
            if !triggeredMines.isEmpty {
                self.gameState.cascadeStep += 1
                self.processMineChain(mines: triggeredMines)
                return
            }

            // Apply gravity and refill
            let gravityResult = self.boardModel.applyGravityAndRefill(specialTileSpawn: spawnInfo)
            self.animateGravityAndRefill(result: gravityResult) { [weak self] in
                self?.clearSelection()
                self?.checkLevelCompletion()
                self?.updateHUD()
                self?.gameState.cascadeStep = 0
            }
        }

        // Show special effects
        for event in specialEvents {
            switch event.reason {
            case .laser(let tile, let isRow):
                animateLaserEffect(at: tile, isRow: isRow)
            case .crossLaser(let tile):
                animateLaserEffect(at: tile, isRow: true)
                animateLaserEffect(at: tile, isRow: false)
            case .bomb(let center):
                animateBombEffect(at: center)
            case .mine(let center):
                animateBombEffect(at: center)
            default:
                break
            }
        }

        updateHUD()
    }

    func processMineChain(mines: [TileModel]) {
        for mine in mines {
            let affected = boardModel.tilesAffectedByMine(center: mine)
            animateBombEffect(at: mine)

            animateExplosions(tiles: affected) { [weak self] in
                guard let self = self else { return }
                let result = self.boardModel.clearTiles(affected)

                // Check for more mines
                let moreMines = result.removed.filter { $0.hasMineOverlay }
                if !moreMines.isEmpty {
                    self.gameState.cascadeStep += 1
                    self.processMineChain(mines: moreMines)
                } else {
                    let gravityResult = self.boardModel.applyGravityAndRefill()
                    self.animateGravityAndRefill(result: gravityResult) { [weak self] in
                        self?.clearSelection()
                        self?.checkLevelCompletion()
                        self?.updateHUD()
                        self?.gameState.cascadeStep = 0
                    }
                }
            }
        }
    }

    // MARK: - Animations

    func animateExplosions(tiles: [TileModel], completion: @escaping () -> Void) {
        let group = DispatchGroup()

        for tile in tiles {
            guard let sprite = tileSprites[tile.id] else { continue }
            group.enter()

            // Particle explosion
            let particles = createExplosionParticles(at: sprite.position)
            boardNode.addChild(particles)

            let fadeOut = SKAction.sequence([
                SKAction.group([
                    SKAction.scale(to: 1.3, duration: 0.1),
                    SKAction.fadeAlpha(to: 0.8, duration: 0.1)
                ]),
                SKAction.group([
                    SKAction.scale(to: 0, duration: 0.2),
                    SKAction.fadeOut(withDuration: 0.2)
                ]),
                SKAction.removeFromParent()
            ])

            sprite.run(fadeOut) {
                group.leave()
            }

            tileSprites.removeValue(forKey: tile.id)
        }

        group.notify(queue: .main) {
            completion()
        }
    }

    func createExplosionParticles(at position: CGPoint) -> SKNode {
        let container = SKNode()
        container.position = position
        container.zPosition = 50

        let colors: [SKColor] = [.yellow, .orange, .red, .white]

        for _ in 0..<8 {
            let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...5))
            particle.fillColor = colors.randomElement()!
            particle.strokeColor = .clear

            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 20...50)
            let dx = cos(angle) * distance
            let dy = sin(angle) * distance

            let move = SKAction.moveBy(x: dx, y: dy, duration: 0.3)
            move.timingMode = .easeOut
            let fade = SKAction.fadeOut(withDuration: 0.3)
            let remove = SKAction.removeFromParent()

            particle.run(SKAction.sequence([SKAction.group([move, fade]), remove]))
            container.addChild(particle)
        }

        let removeContainer = SKAction.sequence([
            SKAction.wait(forDuration: 0.5),
            SKAction.removeFromParent()
        ])
        container.run(removeContainer)

        return container
    }

    func animateLaserEffect(at tile: TileModel, isRow: Bool) {
        let pos = positionForTile(row: tile.row, col: tile.col)

        let line = SKShapeNode()
        let path = CGMutablePath()

        if isRow {
            path.move(to: CGPoint(x: 0, y: pos.y))
            path.addLine(to: CGPoint(x: tileSize * CGFloat(boardModel.cols), y: pos.y))
        } else {
            path.move(to: CGPoint(x: pos.x, y: 0))
            path.addLine(to: CGPoint(x: pos.x, y: tileSize * CGFloat(boardModel.rows)))
        }

        line.path = path
        line.strokeColor = SKColor(red: 0.3, green: 0.8, blue: 1.0, alpha: 1.0)
        line.lineWidth = 6
        line.glowWidth = 8
        line.zPosition = 60
        boardNode.addChild(line)

        let fade = SKAction.sequence([
            SKAction.wait(forDuration: 0.2),
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ])
        line.run(fade)
    }

    func animateBombEffect(at tile: TileModel) {
        let pos = positionForTile(row: tile.row, col: tile.col)

        let circle = SKShapeNode(circleOfRadius: tileSize * 1.5)
        circle.position = pos
        circle.fillColor = SKColor(red: 1.0, green: 0.5, blue: 0.0, alpha: 0.5)
        circle.strokeColor = SKColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 0.8)
        circle.lineWidth = 3
        circle.zPosition = 60
        circle.setScale(0.1)
        boardNode.addChild(circle)

        let expand = SKAction.sequence([
            SKAction.scale(to: 1.0, duration: 0.2),
            SKAction.fadeOut(withDuration: 0.2),
            SKAction.removeFromParent()
        ])
        circle.run(expand)
    }

    func animateGravityAndRefill(result: GravityResult, completion: @escaping () -> Void) {
        let duration: TimeInterval = 0.25

        // Animate moved tiles
        for move in result.movedTiles {
            if let sprite = tileSprites[move.tile.id] {
                let newPos = positionForTile(row: move.toRow, col: move.tile.col)
                let moveAction = SKAction.move(to: newPos, duration: duration)
                moveAction.timingMode = .easeIn
                sprite.run(moveAction)
            }
        }

        // Create and animate new tiles
        for tile in result.newTiles {
            let sprite = createTileSprite(for: tile)
            let finalPos = positionForTile(row: tile.row, col: tile.col)
            sprite.position = CGPoint(x: finalPos.x, y: CGFloat(boardModel.rows) * tileSize + tileSize)
            sprite.alpha = 0
            boardNode.addChild(sprite)
            tileSprites[tile.id] = sprite

            let moveDown = SKAction.move(to: finalPos, duration: duration + 0.1)
            moveDown.timingMode = .easeIn
            let fadeIn = SKAction.fadeIn(withDuration: 0.1)

            sprite.run(SKAction.group([moveDown, fadeIn]))
        }

        // Wait for animations to complete
        run(SKAction.wait(forDuration: duration + 0.15)) {
            completion()
        }
    }

    func showScorePopup(_ score: Int, at tile: TileModel) {
        let pos = positionForTile(row: tile.row, col: tile.col)

        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = "+\(score)"
        label.fontSize = 24
        label.fontColor = .yellow
        label.position = CGPoint(x: pos.x, y: pos.y + 20)
        label.zPosition = 200
        boardNode.addChild(label)

        let moveUp = SKAction.moveBy(x: 0, y: 60, duration: 0.8)
        moveUp.timingMode = .easeOut
        let fade = SKAction.fadeOut(withDuration: 0.5)
        let scale = SKAction.scale(to: 1.5, duration: 0.8)
        let remove = SKAction.removeFromParent()

        label.run(SKAction.sequence([
            SKAction.group([moveUp, fade, scale]),
            remove
        ]))
    }

    // MARK: - HUD

    func setupHUD() {
        hudNode = SKNode()
        hudNode.zPosition = 200
        addChild(hudNode)

        let hudY = size.height - 80

        // Back button
        let backBtn = SKNode()
        backBtn.name = "backButton"
        backBtn.position = CGPoint(x: 30, y: hudY + 20)
        let backBG = SKShapeNode(rectOf: CGSize(width: 50, height: 30), cornerRadius: 5)
        backBG.fillColor = SKColor(white: 0.3, alpha: 0.8)
        backBG.strokeColor = .clear
        backBtn.addChild(backBG)
        let backLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        backLabel.text = "←"
        backLabel.fontSize = 20
        backLabel.fontColor = .white
        backLabel.verticalAlignmentMode = .center
        backBtn.addChild(backLabel)
        hudNode.addChild(backBtn)

        // Score
        scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        scoreLabel.fontSize = 22
        scoreLabel.fontColor = .white
        scoreLabel.position = CGPoint(x: size.width / 2, y: hudY + 20)
        scoreLabel.horizontalAlignmentMode = .center
        scoreLabel.text = "Score: 0"
        hudNode.addChild(scoreLabel)

        // Timer / Moves
        timerLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        timerLabel.fontSize = 18
        timerLabel.fontColor = SKColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 1.0)
        timerLabel.position = CGPoint(x: size.width - 80, y: hudY + 20)
        timerLabel.horizontalAlignmentMode = .center
        hudNode.addChild(timerLabel)

        // Goal
        goalLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        goalLabel.fontSize = 16
        goalLabel.fontColor = SKColor(white: 0.8, alpha: 1.0)
        goalLabel.position = CGPoint(x: size.width / 2, y: hudY - 5)
        goalLabel.horizontalAlignmentMode = .center
        hudNode.addChild(goalLabel)

        // Streak
        streakLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        streakLabel.fontSize = 16
        streakLabel.fontColor = SKColor(red: 1.0, green: 0.5, blue: 0.0, alpha: 1.0)
        streakLabel.position = CGPoint(x: size.width / 2, y: hudY - 25)
        streakLabel.horizontalAlignmentMode = .center
        streakLabel.text = ""
        hudNode.addChild(streakLabel)

        updateHUD()
    }

    func updateHUD() {
        guard let state = gameState else { return }

        scoreLabel.text = "Score: \(state.score)"

        if let config = levelConfig {
            switch config.goalType {
            case .scoreTimed:
                let time = Int(state.timeRemaining)
                let mins = time / 60
                let secs = time % 60
                timerLabel.text = String(format: "%d:%02d", mins, secs)
                goalLabel.text = "Target: \(config.targetScore ?? 0)"
            case .clearIceMoves:
                let remaining = (config.moveLimit ?? 0) - state.movesUsed
                timerLabel.text = "Moves: \(remaining)"
                goalLabel.text = "Ice: \(state.iceTilesCleared)/\(config.iceTilesToClearTarget ?? 0)"
            }
        }

        if state.streakMultiplier > 1.0 {
            streakLabel.text = String(format: "Streak x%.1f!", state.streakMultiplier)
            streakLabel.alpha = 1.0
        } else {
            streakLabel.text = ""
        }

        // Update power-up counts
        updatePowerUpCounts()
    }

    // MARK: - Power-Up Bar

    func setupPowerUpBar() {
        powerUpBar = SKNode()
        powerUpBar.position = CGPoint(x: 0, y: 30)
        powerUpBar.zPosition = 200
        addChild(powerUpBar)

        let types: [PowerUpType] = [.hint, .bomb, .laser, .crossLaser, .mine]
        let buttonWidth: CGFloat = 60
        let totalWidth = buttonWidth * CGFloat(types.count)
        let startX = (size.width - totalWidth) / 2 + buttonWidth / 2

        for (i, type) in types.enumerated() {
            let btn = createPowerUpButton(type: type)
            btn.position = CGPoint(x: startX + CGFloat(i) * buttonWidth, y: 0)
            powerUpBar.addChild(btn)
            powerUpButtons[type] = btn
        }
    }

    func createPowerUpButton(type: PowerUpType) -> SKNode {
        let container = SKNode()
        container.name = "powerup_\(type.rawValue)"

        let bg = SKShapeNode(rectOf: CGSize(width: 50, height: 50), cornerRadius: 8)
        bg.fillColor = SKColor(white: 0.2, alpha: 0.9)
        bg.strokeColor = SKColor(white: 0.5, alpha: 0.5)
        bg.lineWidth = 1
        container.addChild(bg)

        let icon = SKLabelNode(fontNamed: "AvenirNext-Bold")
        icon.fontSize = 20
        icon.verticalAlignmentMode = .center

        switch type {
        case .hint: icon.text = "💡"
        case .bomb: icon.text = "💣"
        case .laser: icon.text = "⚡"
        case .crossLaser: icon.text = "✚"
        case .mine: icon.text = "💥"
        }

        icon.zPosition = 1
        container.addChild(icon)

        let countLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        countLabel.fontSize = 12
        countLabel.fontColor = .yellow
        countLabel.position = CGPoint(x: 18, y: -18)
        countLabel.zPosition = 2
        countLabel.name = "countLabel"
        container.addChild(countLabel)
        powerUpCountLabels[type] = countLabel

        return container
    }

    func updatePowerUpCounts() {
        guard let state = gameState else { return }
        powerUpCountLabels[.hint]?.text = "\(state.hintCount)"
        powerUpCountLabels[.bomb]?.text = "\(state.bombCount)"
        powerUpCountLabels[.laser]?.text = "\(state.laserCount)"
        powerUpCountLabels[.crossLaser]?.text = "\(state.crossLaserCount)"
        powerUpCountLabels[.mine]?.text = "\(state.mineCount)"
    }

    func checkPowerUpTap(at location: CGPoint) -> PowerUpType? {
        let types: [PowerUpType] = [.hint, .bomb, .laser, .crossLaser, .mine]
        for type in types {
            if let btn = powerUpButtons[type] {
                let btnPos = btn.convert(CGPoint.zero, to: self)
                let rect = CGRect(x: btnPos.x - 25, y: btnPos.y - 25, width: 50, height: 50)
                if rect.contains(location) {
                    return type
                }
            }
        }
        return nil
    }

    func handlePowerUpActivation(_ type: PowerUpType) {
        guard powerUpSystem.canUse(type) else { return }

        if type == .hint {
            // Execute immediately
            if let path = powerUpSystem.executeHint() {
                showHintHighlight(path: path)
            }
        } else {
            // Activate for next tap
            activePowerUp = type
            showPowerUpActivationIndicator(type)
        }
    }

    func executePowerUp(_ type: PowerUpType, on tile: TileModel) {
        var tilesToClear: [TileModel]?

        switch type {
        case .bomb:
            tilesToClear = powerUpSystem.executeBomb(at: tile)
            if tilesToClear != nil { animateBombEffect(at: tile) }
        case .laser:
            tilesToClear = powerUpSystem.executeLaser(at: tile, isRow: true)
            if tilesToClear != nil { animateLaserEffect(at: tile, isRow: true) }
        case .crossLaser:
            tilesToClear = powerUpSystem.executeCrossLaser(at: tile)
            if tilesToClear != nil {
                animateLaserEffect(at: tile, isRow: true)
                animateLaserEffect(at: tile, isRow: false)
            }
        case .mine:
            let _ = powerUpSystem.placeMine(on: tile)
            // Refresh tile sprite to show mine overlay
            if let sprite = tileSprites[tile.id] {
                let mine = SKShapeNode(circleOfRadius: 6)
                mine.fillColor = .red
                mine.strokeColor = .darkGray
                mine.position = CGPoint(x: tileSize / 2 - 10, y: -tileSize / 2 + 10)
                mine.zPosition = 3
                sprite.addChild(mine)
            }
            updateHUD()
            return
        case .hint:
            return
        }

        if let tiles = tilesToClear {
            gameState.movesUsed += 1
            animateExplosions(tiles: tiles) { [weak self] in
                guard let self = self else { return }
                let clearResult = self.boardModel.clearTiles(tiles)

                for tile in clearResult.iceHits where !tile.isIced {
                    self.gameState.iceTilesCleared += 1
                }

                let gravityResult = self.boardModel.applyGravityAndRefill()
                self.animateGravityAndRefill(result: gravityResult) { [weak self] in
                    self?.checkLevelCompletion()
                    self?.updateHUD()
                }
            }
        }
    }

    func showPowerUpActivationIndicator(_ type: PowerUpType) {
        // Simple visual indicator
        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = "Tap a tile to use \(type.rawValue)"
        label.fontSize = 16
        label.fontColor = .yellow
        label.position = CGPoint(x: size.width / 2, y: boardOriginY - 20)
        label.zPosition = 300
        label.name = "powerUpIndicator"
        addChild(label)

        let fade = SKAction.sequence([
            SKAction.wait(forDuration: 3.0),
            SKAction.fadeOut(withDuration: 0.5),
            SKAction.removeFromParent()
        ])
        label.run(fade)
    }

    func showHintHighlight(path: [TileModel]) {
        clearHintHighlights()

        for tile in path {
            if let sprite = tileSprites[tile.id] {
                let glow = SKShapeNode(rectOf: CGSize(width: tileSize, height: tileSize), cornerRadius: 8)
                glow.fillColor = SKColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 0.3)
                glow.strokeColor = SKColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 0.8)
                glow.lineWidth = 2
                glow.zPosition = 8
                glow.name = "hintGlow"
                sprite.addChild(glow)
                hintNodes.append(glow)

                // Pulse animation
                let pulse = SKAction.repeatForever(SKAction.sequence([
                    SKAction.fadeAlpha(to: 0.1, duration: 0.5),
                    SKAction.fadeAlpha(to: 0.5, duration: 0.5)
                ]))
                glow.run(pulse)
            }
        }

        // Auto-remove after 3 seconds
        run(SKAction.wait(forDuration: 3.0)) { [weak self] in
            self?.clearHintHighlights()
        }
    }

    func clearHintHighlights() {
        for node in hintNodes {
            node.removeFromParent()
        }
        hintNodes.removeAll()
    }

    // MARK: - Timer

    func startTimer() {
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            guard self.gameState.timerStarted && !self.gameState.isGameOver else { return }

            self.gameState.timeRemaining -= 1.0

            if self.gameState.timeRemaining <= 0 {
                self.gameState.timeRemaining = 0
                self.gameTimer?.invalidate()
                self.gameState.isGameOver = true
                self.handleLevelEnd()
            }

            self.updateHUD()
        }
    }

    // MARK: - Level Completion

    func checkLevelCompletion() {
        guard let config = levelConfig, !gameState.isGameOver, !gameState.isLevelComplete else { return }

        switch config.goalType {
        case .scoreTimed:
            if gameState.score >= (config.targetScore ?? 0) {
                gameState.isLevelComplete = true
                gameTimer?.invalidate()
                handleLevelEnd()
            }

        case .clearIceMoves:
            if gameState.iceTilesCleared >= (config.iceTilesToClearTarget ?? 0) {
                gameState.isLevelComplete = true
                handleLevelEnd()
            } else if gameState.movesUsed >= (config.moveLimit ?? 0) {
                gameState.isGameOver = true
                handleLevelEnd()
            }
        }
    }

    func handleLevelEnd() {
        // Calculate stars
        let stars: Int
        if let config = levelConfig {
            switch config.goalType {
            case .scoreTimed:
                stars = LevelManager.shared.starsEarned(for: config.levelNumber, score: gameState.score)
            case .clearIceMoves:
                if gameState.isLevelComplete {
                    stars = LevelManager.shared.starsEarnedForIceLevel(
                        for: config.levelNumber,
                        iceCleared: gameState.iceTilesCleared,
                        movesUsed: gameState.movesUsed
                    )
                } else {
                    stars = 0
                }
            }
        } else {
            stars = 0
        }

        // Save progress
        let persistence = PersistenceManager.shared
        var progress = persistence.loadProgress()

        let levelNum = levelConfig.levelNumber
        var levelProg = progress.levelProgress[levelNum] ?? LevelProgress()
        levelProg.bestScore = max(levelProg.bestScore, gameState.score)
        levelProg.stars = max(levelProg.stars, stars)

        if gameState.isLevelComplete {
            levelProg.completed = true
            if levelNum + 1 > progress.highestUnlockedLevel {
                progress.highestUnlockedLevel = levelNum + 1
            }
        }

        progress.levelProgress[levelNum] = levelProg
        progress.powerUpInventory = powerUpSystem.currentInventory()
        persistence.saveProgress(progress)

        // Show results screen
        showLevelCompleteScreen(score: gameState.score, stars: stars, completed: gameState.isLevelComplete)
    }

    func showLevelCompleteScreen(score: Int, stars: Int, completed: Bool) {
        let overlay = SKShapeNode(rectOf: size)
        overlay.fillColor = SKColor(white: 0.0, alpha: 0.7)
        overlay.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.zPosition = 500
        overlay.name = "resultOverlay"
        addChild(overlay)

        let panel = SKShapeNode(rectOf: CGSize(width: 280, height: 320), cornerRadius: 20)
        panel.fillColor = SKColor(red: 0.15, green: 0.15, blue: 0.3, alpha: 1.0)
        panel.strokeColor = SKColor(white: 0.5, alpha: 0.5)
        panel.lineWidth = 2
        panel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        panel.zPosition = 501
        panel.name = "resultPanel"
        addChild(panel)

        // Title
        let title = SKLabelNode(fontNamed: "AvenirNext-Bold")
        title.text = completed ? "Level Complete!" : "Time's Up!"
        title.fontSize = 28
        title.fontColor = completed ? .green : .red
        title.position = CGPoint(x: 0, y: 110)
        panel.addChild(title)

        // Stars
        let starsText = SKLabelNode(fontNamed: "AvenirNext-Bold")
        starsText.text = String(repeating: "⭐", count: stars) + String(repeating: "☆", count: 3 - stars)
        starsText.fontSize = 36
        starsText.position = CGPoint(x: 0, y: 60)
        panel.addChild(starsText)

        // Score
        let scoreText = SKLabelNode(fontNamed: "AvenirNext-Medium")
        scoreText.text = "Score: \(score)"
        scoreText.fontSize = 22
        scoreText.fontColor = .white
        scoreText.position = CGPoint(x: 0, y: 20)
        panel.addChild(scoreText)

        // Next Level button
        if completed && (levelConfig?.levelNumber ?? 10) < 10 {
            let nextBtn = createButton(text: "Next Level", width: 200, height: 44)
            nextBtn.position = CGPoint(x: 0, y: -40)
            nextBtn.name = "nextLevelBtn"
            panel.addChild(nextBtn)
        }

        // Retry button
        let retryBtn = createButton(text: "Retry", width: 200, height: 44)
        retryBtn.position = CGPoint(x: 0, y: -95)
        retryBtn.name = "retryBtn"
        panel.addChild(retryBtn)

        // Map button
        let mapBtn = createButton(text: "Level Map", width: 200, height: 44)
        mapBtn.position = CGPoint(x: 0, y: -145)
        mapBtn.name = "mapBtn"
        panel.addChild(mapBtn)

        // Handle button taps
        overlay.isUserInteractionEnabled = false
    }

    func createButton(text: String, width: CGFloat, height: CGFloat) -> SKNode {
        let container = SKNode()

        let bg = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 10)
        bg.fillColor = SKColor(red: 0.3, green: 0.5, blue: 0.8, alpha: 1.0)
        bg.strokeColor = .clear
        container.addChild(bg)

        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = text
        label.fontSize = 18
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        container.addChild(label)

        return container
    }

    // Handle result screen taps
    func handleResultScreenTap(at location: CGPoint) {
        if let panel = childNode(withName: "resultPanel") {
            let panelLocation = panel.convert(location, from: self)

            // Check Next Level
            if let nextBtn = panel.childNode(withName: "nextLevelBtn") {
                let btnRect = CGRect(x: nextBtn.position.x - 100, y: nextBtn.position.y - 22,
                                     width: 200, height: 44)
                if btnRect.contains(panelLocation) {
                    loadNextLevel()
                    return
                }
            }

            // Check Retry
            if let retryBtn = panel.childNode(withName: "retryBtn") {
                let btnRect = CGRect(x: retryBtn.position.x - 100, y: retryBtn.position.y - 22,
                                     width: 200, height: 44)
                if btnRect.contains(panelLocation) {
                    retryLevel()
                    return
                }
            }

            // Check Map
            if let mapBtn = panel.childNode(withName: "mapBtn") {
                let btnRect = CGRect(x: mapBtn.position.x - 100, y: mapBtn.position.y - 22,
                                     width: 200, height: 44)
                if btnRect.contains(panelLocation) {
                    goToLevelMap()
                    return
                }
            }
        }
    }

    func loadNextLevel() {
        guard let config = levelConfig else { return }
        let nextLevel = config.levelNumber + 1
        guard let nextConfig = LevelManager.shared.config(for: nextLevel) else { return }

        let progress = PersistenceManager.shared.loadProgress()
        let scene = GameScene(size: size)
        scene.scaleMode = scaleMode
        scene.configure(with: nextConfig, progress: progress)
        view?.presentScene(scene, transition: SKTransition.fade(withDuration: 0.5))
    }

    func retryLevel() {
        guard let config = levelConfig else { return }
        let progress = PersistenceManager.shared.loadProgress()
        let scene = GameScene(size: size)
        scene.scaleMode = scaleMode
        scene.configure(with: config, progress: progress)
        view?.presentScene(scene, transition: SKTransition.fade(withDuration: 0.5))
    }

    func goToLevelMap() {
        gameTimer?.invalidate()
        let scene = LevelMapScene(size: size)
        scene.scaleMode = scaleMode
        view?.presentScene(scene, transition: SKTransition.fade(withDuration: 0.5))
    }

    // Override touchesBegan for result screen
    func checkResultScreenTap(_ location: CGPoint) -> Bool {
        if childNode(withName: "resultPanel") != nil {
            handleResultScreenTap(at: location)
            return true
        }
        return false
    }

    // MARK: - Update Loop

    override func update(_ currentTime: TimeInterval) {
        // Timer is handled by Timer, not update loop
    }
}
