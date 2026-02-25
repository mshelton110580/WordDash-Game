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
    var lastDragPoint: CGPoint?

    // Power-up activation state (no longer used for tap-to-target, but kept for hint)
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

    // Hint highlight — persists until next word
    var hintNodes: [SKNode] = []
    var hintedTiles: [TileModel] = []

    // Laser direction picker
    var laserDirectionOverlay: SKNode?
    var pendingLaserTile: TileModel?

    // Economy
    var coinHUDLabel: SKLabelNode!
    var continueManager = ContinueManager()

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

        // Background — use image assets
        let imageName: String
        if let special = tile.specialType {
            switch special {
            case .bomb: imageName = "tile_special_bomb"
            case .laser: imageName = "tile_special_laser"
            case .crossLaser: imageName = "tile_special_cross"
            case .mine: imageName = "tile_special_mine"
            case .wildcard: imageName = "tile_special_wildcard"
            }
        } else {
            imageName = "tile_normal"
        }

        let bg = SKSpriteNode(imageNamed: imageName)
        bg.size = CGSize(width: tileSize - 2, height: tileSize - 2)
        bg.name = "tileBG"
        bg.zPosition = 0
        container.addChild(bg)

        // Ice overlay — use ice tile images
        if tile.isIced {
            let iceImageName = tile.iceState == .intact ? "tile_ice_1" : "tile_ice_2"
            let ice = SKSpriteNode(imageNamed: iceImageName)
            ice.size = CGSize(width: tileSize - 2, height: tileSize - 2)
            ice.name = "iceOverlay"
            ice.alpha = tile.iceState == .intact ? 0.8 : 0.5
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

        // Letter — dark text on light wood tiles, white on special dark tiles
        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.name = "letterLabel"
        if tile.specialType == .wildcard {
            label.text = "★"
            label.fontSize = tileSize * 0.5
            label.fontColor = .white
        } else {
            label.text = String(tile.letter)
            label.fontSize = tileSize * 0.45
            // Dark brown text on normal wood tiles for contrast
            label.fontColor = tile.specialType == nil ? SKColor(red: 0.25, green: 0.18, blue: 0.12, alpha: 1.0) : .white
        }
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.zPosition = 5
        container.addChild(label)

        // Point value (small) — bottom right
        if tile.specialType == nil {
            let pointLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
            let pts = GameConstants.letterValues[tile.letter] ?? 0
            pointLabel.text = "\(pts)"
            pointLabel.fontSize = tileSize * 0.2
            pointLabel.fontColor = SKColor(red: 0.45, green: 0.35, blue: 0.25, alpha: 0.7)
            pointLabel.position = CGPoint(x: tileSize * 0.3, y: -tileSize * 0.3)
            pointLabel.verticalAlignmentMode = .center
            pointLabel.horizontalAlignmentMode = .center
            pointLabel.zPosition = 5
            container.addChild(pointLabel)
        }

        // Special type label — bottom center
        if let special = tile.specialType {
            let specialLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
            let labels: [SpecialTileType: String] = [
                .bomb: "BOMB", .laser: "LASER", .crossLaser: "CROSS", .wildcard: "WILD", .mine: "MINE"
            ]
            specialLabel.text = labels[special] ?? ""
            specialLabel.fontSize = tileSize * 0.14
            specialLabel.fontColor = .white
            specialLabel.position = CGPoint(x: 0, y: -tileSize * 0.35)
            specialLabel.verticalAlignmentMode = .center
            specialLabel.horizontalAlignmentMode = .center
            specialLabel.zPosition = 6
            container.addChild(specialLabel)
        }

        // Letter multiplier badge (2x / 3x) — top right
        if tile.letterMultiplier > 1 {
            let badgeSize = CGSize(width: tileSize * 0.38, height: tileSize * 0.22)
            let badgePos = CGPoint(x: tileSize * 0.2, y: tileSize * 0.3)

            let badge = SKShapeNode(rectOf: badgeSize, cornerRadius: 4)
            badge.position = badgePos
            badge.zPosition = 7

            if tile.letterMultiplier == 3 {
                badge.fillColor = SKColor(red: 0.96, green: 0.25, blue: 0.37, alpha: 0.9)
                badge.strokeColor = SKColor(red: 1.0, green: 0.4, blue: 0.5, alpha: 1.0)
            } else {
                badge.fillColor = SKColor(red: 0.96, green: 0.62, blue: 0.04, alpha: 0.9)
                badge.strokeColor = SKColor(red: 1.0, green: 0.75, blue: 0.2, alpha: 1.0)
            }
            badge.lineWidth = 1
            badge.glowWidth = 3
            container.addChild(badge)

            let badgeLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
            badgeLabel.text = "\(tile.letterMultiplier)x"
            badgeLabel.fontSize = tileSize * 0.16
            badgeLabel.fontColor = .white
            badgeLabel.position = badgePos
            badgeLabel.verticalAlignmentMode = .center
            badgeLabel.horizontalAlignmentMode = .center
            badgeLabel.zPosition = 8
            container.addChild(badgeLabel)
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

    /// Improved tile detection: find nearest tile center within radius, with directional bias
    func nearestAdjacentTile(to point: CGPoint, from lastTile: TileModel) -> TileModel? {
        let boardPoint = CGPoint(x: point.x - boardOriginX, y: point.y - boardOriginY)

        // Get all adjacent tiles
        var candidates: [(tile: TileModel, dist: CGFloat, isDiagonal: Bool)] = []
        for dr in -1...1 {
            for dc in -1...1 {
                if dr == 0 && dc == 0 { continue }
                let r = lastTile.row + dr
                let c = lastTile.col + dc
                guard let tile = boardModel.tileAt(row: r, col: c) else { continue }
                if selectedPath.contains(where: { $0.id == tile.id }) { continue }

                let tilePos = CGPoint(
                    x: CGFloat(c) * tileSize + tileSize / 2,
                    y: CGFloat(boardModel.rows - 1 - r) * tileSize + tileSize / 2
                )
                let dist = hypot(boardPoint.x - tilePos.x, boardPoint.y - tilePos.y)
                let isDiag = dr != 0 && dc != 0
                candidates.append((tile: tile, dist: dist, isDiagonal: isDiag))
            }
        }

        // Orthogonal tiles: larger hit zone (48% of tile size)
        // Diagonal tiles: tighter hit zone (32% of tile size) + require drag direction alignment
        let orthoRadius = tileSize * 0.48
        let diagRadius = tileSize * 0.32

        // Check drag direction for diagonal intent
        var hasDiagonalIntent = false
        if let lastPoint = lastDragPoint {
            let dx = point.x - lastPoint.x
            let dy = point.y - lastPoint.y
            let dragLen = hypot(dx, dy)
            if dragLen > 5 {
                let normDx = dx / dragLen
                let normDy = dy / dragLen
                // Diagonal intent: both components are significant (> 0.5)
                hasDiagonalIntent = abs(normDx) > 0.5 && abs(normDy) > 0.5
            }
        }

        var bestTile: TileModel?
        var bestDist: CGFloat = .greatestFiniteMagnitude

        for candidate in candidates {
            let maxRadius = candidate.isDiagonal ? diagRadius : orthoRadius

            // Diagonal tiles also require diagonal drag intent
            if candidate.isDiagonal && !hasDiagonalIntent {
                continue
            }

            if candidate.dist < maxRadius && candidate.dist < bestDist {
                bestDist = candidate.dist
                bestTile = candidate.tile
            }
        }

        return bestTile
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

        // Check laser direction picker first
        if laserDirectionOverlay != nil {
            let tapped = nodes(at: location)
            for node in tapped {
                let name = node.name ?? ""
                if name == "laserRowBtn" || (node.parent?.name == "laserRowBtn") {
                    fireLaser(direction: "row")
                    return
                }
                if name == "laserColBtn" || (node.parent?.name == "laserColBtn") {
                    fireLaser(direction: "col")
                    return
                }
                if name == "laserCancelBtn" {
                    dismissLaserDirectionPicker()
                    return
                }
            }
            return // block other taps while picker is shown
        }

        // Check result screen first
        if checkResultScreenTap(location) { return }

        // Check if power-up button tapped
        if let powerUp = checkPowerUpTap(at: location) {
            handlePowerUpActivation(powerUp)
            return
        }

        // Check for back button
        if let node = atPoint(location) as? SKNode, node.name == "backButton" || node.parent?.name == "backButton" {
            goToLevelMap()
            return
        }

        // Start drag
        guard !gameState.isGameOver && !gameState.isLevelComplete else { return }

        if let tile = tileAt(point: location) {
            isDragging = true
            selectedPath = [tile]
            dragDirections = []
            lastDragPoint = location
            updateSelectionVisuals()
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isDragging, let touch = touches.first else { return }
        let location = touch.location(in: self)

        guard let lastTile = selectedPath.last else { return }

        // Check for backtracking: if pointer is near the second-to-last tile
        if selectedPath.count >= 2 {
            let prevTile = selectedPath[selectedPath.count - 2]
            let prevPos = positionForTile(row: prevTile.row, col: prevTile.col)
            let boardPoint = CGPoint(x: location.x - boardOriginX, y: location.y - boardOriginY)
            let distToPrev = hypot(boardPoint.x - prevPos.x, boardPoint.y - prevPos.y)
            if distToPrev < tileSize * 0.4 {
                selectedPath.removeLast()
                if !dragDirections.isEmpty { dragDirections.removeLast() }
                lastDragPoint = location
                updateSelectionVisuals()
                return
            }
        }

        // Use improved adjacent tile detection
        if let nextTile = nearestAdjacentTile(to: location, from: lastTile) {
            let dx = nextTile.col - lastTile.col
            let dy = nextTile.row - lastTile.row
            dragDirections.append((dx: dx, dy: dy))
            selectedPath.append(nextTile)
            lastDragPoint = location
            updateSelectionVisuals()
        }

        lastDragPoint = location
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isDragging else { return }
        isDragging = false
        lastDragPoint = nil

        if selectedPath.count >= GameConstants.minWordLength {
            attemptWord()
        } else {
            shakeSelection()
            clearSelection()
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        isDragging = false
        lastDragPoint = nil
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

        // Reset all tiles to normal appearance
        for (tileId, sprite) in tileSprites {
            // Remove any existing selection overlay
            sprite.childNode(withName: "selectionOverlay")?.removeFromParent()
            // Reset tile background to normal image
            if let bg = sprite.childNode(withName: "tileBG") as? SKSpriteNode {
                // Find the original tile to determine correct image
                if let tile = boardModel.allTilesOnBoard().first(where: { $0.id == tileId }) {
                    let imageName: String
                    if let special = tile.specialType {
                        switch special {
                        case .bomb: imageName = "tile_special_bomb"
                        case .laser: imageName = "tile_special_laser"
                        case .crossLaser: imageName = "tile_special_cross"
                        case .mine: imageName = "tile_special_mine"
                        case .wildcard: imageName = "tile_special_wildcard"
                        }
                    } else {
                        imageName = "tile_normal"
                    }
                    bg.texture = SKTexture(imageNamed: imageName)
                }
            }
        }

        // Highlight selected tiles with selected image
        for tile in selectedPath {
            if let sprite = tileSprites[tile.id],
               let bg = sprite.childNode(withName: "tileBG") as? SKSpriteNode {
                bg.texture = SKTexture(imageNamed: "tile_selected")
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
            SoundManager.shared.playWordFail()
            shakeSelection()
            clearSelection()
            return
        }

        // Valid word — clear hint highlights
        SoundManager.shared.playWordSuccess()
        clearHintHighlights()

        // Increment word submit count
        gameState.wordSubmitCount += 1

        // Valid word!
        processValidWord(resolvedWord)
    }

    func processValidWord(_ word: String) {
        // Track word for coin calculation
        gameState.wordsFound.append(word)

        // Snapshot score BEFORE award (for animated counter)
        let scoreBefore = gameState.score
        let coinsBefore = CoinManager.shared.balance

        // Calculate score (letterMultiplier applied inside baseLetterScore)
        let scoreResult = ScoringEngine.shared.calculateScore(tiles: selectedPath, gameState: gameState)
        gameState.score += scoreResult.totalScore

        // Track moves
        gameState.movesUsed += 1

        // Show score popup (legacy small-tier only; big/medium handled by RewardFeedbackManager below)
        showScorePopup(scoreResult.totalScore, at: selectedPath.last!)

        // Determine special tile spawn
        let spawnType = GameConstants.specialTileForWordLength(selectedPath.count)
        let lastTile = selectedPath.last!
        let spawnInfo: (row: Int, col: Int, type: SpecialTileType)? = spawnType.map {
            (row: lastTile.row, col: lastTile.col, type: $0)
        }

        // Check for dual-bomb board explosion
        let isDualBomb = boardModel.hasDualBombs(in: selectedPath)

        // Collect special tile effects
        let specialEvents: [ClearEvent]
        if isDualBomb {
            // Board explosion — skip individual bomb effects, but keep non-bomb effects
            specialEvents = boardModel.processSpecialEffects(wordTiles: selectedPath, dragDirections: dragDirections)
                .filter { event in
                    switch event.reason {
                    case .bomb: return false
                    default: return true
                    }
                }
        } else {
            specialEvents = boardModel.processSpecialEffects(wordTiles: selectedPath, dragDirections: dragDirections)
        }

        // Determine all tiles to clear
        var allTilesToClear: [TileModel]
        if isDualBomb {
            // Clear entire board
            allTilesToClear = boardModel.allTilesOnBoard()
        } else {
            allTilesToClear = selectedPath
            for event in specialEvents {
                for tile in event.tiles {
                    if !allTilesToClear.contains(where: { $0.id == tile.id }) {
                        allTilesToClear.append(tile)
                    }
                }
            }
        }

        // Award explosion points for all tiles destroyed by special effects (not the word tiles themselves)
        let explosionTiles = allTilesToClear.filter { tile in
            !selectedPath.contains(where: { $0.id == tile.id })
        }
        let explosionPts = ScoringEngine.shared.explosionScore(for: explosionTiles)
        gameState.score += explosionPts

        // Dual-bomb bonus
        if isDualBomb {
            gameState.cascadeStep += 1
            gameState.maxCascadeReached = max(gameState.maxCascadeReached, gameState.cascadeStep)
            let bonus = ScoringEngine.shared.boardExplosionBonus(step: gameState.cascadeStep)
            gameState.score += bonus
        }

        // Screen shake + shockwave for impressive clears
        if selectedPath.count >= 5 {
            // Big word — shockwave at midpoint + screen shake
            let midIdx = selectedPath.count / 2
            let midTile = selectedPath[midIdx]
            let midPos = positionForTile(row: midTile.row, col: midTile.col)
            spawnShockwaveRing(at: midPos, color: effectColor(for: nil))
            shakeScreen(intensity: 3, duration: 0.12)
        }

        // Animate explosions
        if isDualBomb {
            animateBoardExplosion()
        }

        animateExplosions(tiles: allTilesToClear) { [weak self] in
            guard let self = self else { return }

            // Actually clear from board
            let clearResult = self.boardModel.clearTiles(allTilesToClear)

            // Track ice clears
            for tile in clearResult.iceHits {
                if !tile.isIced {
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

            // Apply gravity and refill (with multiplier spawning)
            let gravityResult = self.boardModel.applyGravityAndRefill(
                specialTileSpawn: spawnInfo,
                wordSubmitCount: self.gameState.wordSubmitCount
            )
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

        // Real-time coin earning: award coins for long words during gameplay
        let wordLen = selectedPath.count
        var coinsForWord = 0
        for bonus in GameEconomyConfig.longWordBonus {
            if wordLen >= bonus.minLength {
                coinsForWord = bonus.coins
                break
            }
        }
        if coinsForWord > 0 {
            gameState.coinsEarnedThisLevel += coinsForWord
            CoinManager.shared.addCoins(coinsForWord, reason: .levelReward)
            SoundManager.shared.playCoinEarned()
        }

        // ── 3-Tier Explosion + Reward Feedback ──────────────────────────────────
        // Determine dominant cause from word path (highest-priority special tile)
        let dominantCause = dominantExplosionCause(from: specialEvents, isDualBomb: isDualBomb)

        // Select tier automatically
        let tier = ExplosionConfig.selectTier(
            points: scoreResult.totalScore,
            coins: coinsForWord,
            cause: dominantCause,
            streakMultiplier: gameState.streakMultiplier
        )

        // Explosion origin: centroid of cleared tiles (or mid-tile of word path)
        let midTile = selectedPath[selectedPath.count / 2]
        let explosionOrigin = boardNode.convert(positionForTile(row: midTile.row, col: midTile.col), to: effectsLayer)

        // Build HUD targets in scene space
        let hudTargets = HUDTargets(
            scoreLabelPosition: scoreLabel.convert(CGPoint.zero, to: self),
            coinLabelPosition: coinHUDLabel.convert(CGPoint.zero, to: self)
        )

        // Play per-tile VFX via the new manager (replaces old showScorePopup for medium/big)
        // playExplosion fires at the word centroid for a satisfying center-of-gravity burst
        ExplosionManager.shared.playExplosion(
            origin: explosionOrigin,
            tier: tier,
            cause: dominantCause,
            in: effectsLayer,
            tileSize: tileSize
        )

        // Show reward popups + HUD count-up (only if medium or big to avoid duplicate with showScorePopup)
        if tier == .medium || tier == .big {
            let rewardOrigin = hudNode.convert(
                boardNode.convert(positionForTile(row: midTile.row, col: midTile.col), to: self),
                from: self
            )
            RewardFeedbackManager.shared.showRewards(
                origin: explosionOrigin,
                tier: tier,
                points: scoreResult.totalScore,
                coins: coinsForWord,
                hudTargets: hudTargets,
                scoreLabel: scoreLabel,
                coinLabel: coinHUDLabel,
                currentScore: scoreBefore,
                currentCoins: coinsBefore,
                in: effectsLayer
            )
        }
        // ────────────────────────────────────────────────────────────────────────

        updateHUD()
    }

    /// Determine the highest-priority explosion cause from special clear events.
    private func dominantExplosionCause(from events: [ClearEvent], isDualBomb: Bool) -> ExplosionCause {
        if isDualBomb { return .chainResolve }
        var hasBomb = false
        var hasLaser = false
        var hasCrossLaser = false
        var hasMine = false
        for event in events {
            switch event.reason {
            case .bomb:       hasBomb = true
            case .laser:      hasLaser = true
            case .crossLaser: hasCrossLaser = true
            case .mine:       hasMine = true
            default:          break
            }
        }
        if hasCrossLaser { return .crossLaser }
        if hasBomb       { return .bomb }
        if hasLaser      { return .laser }
        if hasMine       { return .mine }
        return .normalClear
    }

    // MARK: - Coin Fly Animation

    func animateCoinFly(from tile: TileModel, amount: Int) {
        let startPos = positionForTile(row: tile.row, col: tile.col)
        let worldStart = boardNode.convert(startPos, to: self)
        let targetPos = coinHUDLabel.position

        let coin = SKShapeNode(circleOfRadius: 10)
        coin.fillColor = SKColor(red: 0.96, green: 0.62, blue: 0.04, alpha: 1.0)
        coin.strokeColor = SKColor(red: 0.98, green: 0.75, blue: 0.14, alpha: 1.0)
        coin.lineWidth = 1.5
        coin.position = worldStart
        coin.zPosition = 200
        effectsLayer.addChild(coin)

        let dollarSign = SKLabelNode(fontNamed: "AvenirNext-Bold")
        dollarSign.text = "$"
        dollarSign.fontSize = 10
        dollarSign.fontColor = .white
        dollarSign.verticalAlignmentMode = .center
        dollarSign.horizontalAlignmentMode = .center
        coin.addChild(dollarSign)

        // Amount label floating above
        let amountLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        amountLabel.text = "+\(amount)"
        amountLabel.fontSize = 14
        amountLabel.fontColor = SKColor(red: 0.98, green: 0.75, blue: 0.14, alpha: 1.0)
        amountLabel.position = CGPoint(x: 0, y: 18)
        amountLabel.verticalAlignmentMode = .center
        amountLabel.horizontalAlignmentMode = .center
        coin.addChild(amountLabel)

        // Bezier curve path
        let midPoint = CGPoint(
            x: (worldStart.x + targetPos.x) / 2,
            y: max(worldStart.y, targetPos.y) + 50
        )

        let path = CGMutablePath()
        path.move(to: worldStart)
        path.addQuadCurve(to: targetPos, control: midPoint)

        let followPath = SKAction.follow(path, asOffset: false, orientToPath: false, duration: 0.8)
        followPath.timingMode = .easeIn
        let fadeOut = SKAction.fadeOut(withDuration: 0.2)
        let scaleDown = SKAction.scale(to: 0.3, duration: 0.2)
        let endGroup = SKAction.group([fadeOut, scaleDown])
        let sequence = SKAction.sequence([followPath, endGroup, SKAction.removeFromParent()])

        // Fade amount label quickly
        amountLabel.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.4),
            SKAction.fadeOut(withDuration: 0.3)
        ]))

        coin.run(sequence) { [weak self] in
            // Pulse the coin HUD label
            self?.coinHUDLabel.run(SKAction.sequence([
                SKAction.scale(to: 1.3, duration: 0.1),
                SKAction.scale(to: 1.0, duration: 0.1)
            ]))
            self?.updateHUD()
        }
    }

    func processMineChain(mines: [TileModel]) {
        for mine in mines {
            let affected = boardModel.tilesAffectedByMine(center: mine)
            animateBombEffect(at: mine)

            // Award explosion points for mine chain
            gameState.cascadeStep += 1
            gameState.maxCascadeReached = max(gameState.maxCascadeReached, gameState.cascadeStep)
            let minePts = ScoringEngine.shared.explosionScore(for: affected)
            gameState.score += minePts

            // Mine chains are always a BIG moment — use big tier for dramatic effect
            animateExplosions(tiles: affected, tier: .big) { [weak self] in
                guard let self = self else { return }
                let result = self.boardModel.clearTiles(affected)

                // Chain resolve explosion at board center for full BIG treatment
                let centerPos = self.boardNode.convert(
                    CGPoint(
                        x: self.tileSize * CGFloat(self.boardModel.cols) / 2,
                        y: self.tileSize * CGFloat(self.boardModel.rows) / 2
                    ),
                    to: self.effectsLayer
                )
                ExplosionManager.shared.playExplosion(
                    origin: centerPos,
                    tier: .big,
                    cause: .chainResolve,
                    in: self.effectsLayer,
                    tileSize: self.tileSize
                )

                // Check for more mines
                let moreMines = result.removed.filter { $0.hasMineOverlay }
                if !moreMines.isEmpty {
                    self.gameState.cascadeStep += 1
                    self.processMineChain(mines: moreMines)
                } else {
                    let gravityResult = self.boardModel.applyGravityAndRefill(
                        wordSubmitCount: self.gameState.wordSubmitCount
                    )
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

    // MARK: - Premium Effects: Layered Explosions

    func animateExplosions(tiles: [TileModel], completion: @escaping () -> Void) {
        animateExplosions(tiles: tiles, tier: .small, completion: completion)
    }

    /// Animate tile sprites through squash→pop→fade using the given tier's timing,
    /// then spawn per-tile VFX via ExplosionManager.
    func animateExplosions(tiles: [TileModel], tier: ExplosionTier, completion: @escaping () -> Void) {
        let group = DispatchGroup()

        for (index, tile) in tiles.enumerated() {
            guard let sprite = tileSprites[tile.id] else { continue }
            group.enter()

            let staggerDelay = Double(index) * 0.015
            let cause = ExplosionManager.shared.cause(for: tile.specialType)

            // Spawn per-tile VFX after stagger delay
            sprite.run(SKAction.sequence([
                SKAction.wait(forDuration: staggerDelay),
                SKAction.run { [weak self] in
                    guard let self = self else { return }
                    let pos = sprite.position
                    // Per-tile particle burst (use existing layered system for backward compat)
                    self.spawnFlash(at: pos, color: self.effectColor(for: tile.specialType))
                    self.spawnLayeredParticles(at: pos, specialType: tile.specialType)
                    if tile.specialType != nil {
                        self.spawnShockwaveRing(at: pos, color: self.effectColor(for: tile.specialType))
                    }
                    // For medium/big tiers, also fire the ExplosionManager burst at each tile
                    if tier == .medium || tier == .big {
                        ExplosionManager.shared.playExplosion(
                            origin: pos,
                            tier: tier == .big && tile.specialType != nil ? .big : tier,
                            cause: cause,
                            in: self.boardNode,
                            tileSize: self.tileSize
                        )
                    }
                }
            ]))

            // Tile squash-pop-fade animation
            ExplosionManager.shared.animateTileExplosion(
                sprite: sprite,
                tier: tier,
                staggerDelay: staggerDelay
            ) {
                group.leave()
            }

            tileSprites.removeValue(forKey: tile.id)
        }

        group.notify(queue: .main) {
            completion()
        }
    }

    /// Get theme color for a special tile type
    func effectColor(for specialType: SpecialTileType?) -> SKColor {
        guard let special = specialType else {
            // Warm wood dust for normal tiles
            return SKColor(red: 0.83, green: 0.65, blue: 0.45, alpha: 1.0)
        }
        switch special {
        case .bomb: return SKColor(red: 1.0, green: 0.42, blue: 0.21, alpha: 1.0)    // warm orange
        case .laser: return SKColor(red: 0.3, green: 0.65, blue: 1.0, alpha: 1.0)     // cool blue
        case .crossLaser: return SKColor(red: 0.7, green: 0.4, blue: 1.0, alpha: 1.0) // purple
        case .mine: return SKColor(red: 1.0, green: 0.27, blue: 0.27, alpha: 1.0)     // red
        case .wildcard: return SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)  // gold
        }
    }

    /// White/yellow additive flash at tile position
    func spawnFlash(at position: CGPoint, color: SKColor) {
        let flash = SKShapeNode(circleOfRadius: tileSize * 0.6)
        flash.position = position
        flash.fillColor = .white
        flash.strokeColor = .clear
        flash.alpha = 0.9
        flash.zPosition = 55
        flash.blendMode = .add
        boardNode.addChild(flash)

        flash.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 1.5, duration: 0.1),
                SKAction.fadeOut(withDuration: 0.15)
            ]),
            SKAction.removeFromParent()
        ]))
    }

    /// Tint a color toward white (+) or dark (-), amount ∈ [-1, 1]
    private func tintColor(_ color: SKColor, by amount: CGFloat) -> SKColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        let c = amount > 0 ? amount : 0
        let d = amount < 0 ? -amount : 0
        return SKColor(red: min(1, r + c - d * r), green: min(1, g + c - d * g), blue: min(1, b + c - d * b), alpha: a)
    }

    /// Build an irregular convex shard polygon path centered at origin
    private func makeShardPath(w: CGFloat, h: CGFloat) -> CGPath {
        let sides = 4 + Int.random(in: 0...2)
        let path = CGMutablePath()
        for i in 0..<sides {
            let baseAngle = CGFloat(i) / CGFloat(sides) * 2 * .pi
            let jitter = CGFloat.random(in: -0.35...0.35)
            let r = CGFloat.random(in: 0.32...0.62)
            let px = cos(baseAngle + jitter) * r * w
            let py = sin(baseAngle + jitter) * r * h
            if i == 0 { path.move(to: CGPoint(x: px, y: py)) }
            else { path.addLine(to: CGPoint(x: px, y: py)) }
        }
        path.closeSubpath()
        return path
    }

    /// Multi-emitter particle system — shards, chips, debris (toward viewer), dust, sparkles
    func spawnLayeredParticles(at position: CGPoint, specialType: SpecialTileType?) {
        let container = SKNode()
        container.position = position
        container.zPosition = 50
        boardNode.addChild(container)

        let themeColor = effectColor(for: specialType)
        let grainLight = tintColor(themeColor, by: 0.18)
        let grainDark  = tintColor(themeColor, by: -0.15)
        let isBig = specialType != nil

        // ── Emitter 1: Shards (irregular polygon fragments in all directions) ──
        let shardCount = isBig ? 8 : 5
        for _ in 0..<shardCount {
            let w = CGFloat.random(in: 6...16)
            let h = CGFloat.random(in: 4...11)
            let shard = SKShapeNode(path: makeShardPath(w: w, h: h))
            shard.fillColor = Bool.random() ? themeColor : grainLight
            shard.strokeColor = grainDark.withAlphaComponent(0.4)
            shard.lineWidth = 0.6
            shard.zRotation = CGFloat.random(in: 0...(2 * .pi))

            let angle = CGFloat.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 55...130)
            let dx = cos(angle) * speed
            // Mix: some fly upward/sideways, ~25% fly downward (toward viewer in 2D)
            let isTowardViewer = CGFloat.random(in: 0...1) < 0.25
            let dyBase = sin(angle) * speed
            let dy = isTowardViewer ? CGFloat.random(in: -20...30) : dyBase
            let duration = Double.random(in: 0.3...0.55)

            let moveOut: SKAction
            if isTowardViewer {
                // Toward viewer: grow rapidly + slow down
                let growScale = CGFloat.random(in: 2.2...4.0)
                let grow = SKAction.scale(to: growScale, duration: duration)
                grow.timingMode = .easeIn
                let slowMove = SKAction.moveBy(x: dx * 0.3, y: dy, duration: duration)
                slowMove.timingMode = .easeOut
                let fade = SKAction.fadeOut(withDuration: duration * 0.85)
                let rotate = SKAction.rotate(byAngle: CGFloat.random(in: -1.5...1.5), duration: duration)
                shard.run(SKAction.group([grow, slowMove, fade, rotate,
                    SKAction.sequence([SKAction.wait(forDuration: duration), SKAction.removeFromParent()])]))
                continue
            } else {
                let move1 = SKAction.moveBy(x: dx, y: dy, duration: duration * 0.45)
                move1.timingMode = .easeOut
                let gravity = SKAction.moveBy(x: 0, y: -CGFloat.random(in: 25...55), duration: duration * 0.55)
                gravity.timingMode = .easeIn
                moveOut = SKAction.sequence([move1, gravity])
            }
            let rotate = SKAction.rotate(byAngle: CGFloat.random(in: -4...4), duration: duration)
            let fade = SKAction.fadeOut(withDuration: duration * 0.8)
            shard.run(SKAction.group([moveOut, rotate, fade,
                SKAction.sequence([SKAction.wait(forDuration: duration), SKAction.removeFromParent()])]))
            container.addChild(shard)
        }

        // ── Emitter 2: Chips (elongated wood splinters) ──────────────────────────
        let chipCount = isBig ? 10 : 6
        for _ in 0..<chipCount {
            let w = CGFloat.random(in: 6...18)
            let h = CGFloat.random(in: 2...4.5)
            let chip = SKShapeNode(rectOf: CGSize(width: w, height: h), cornerRadius: min(h / 2, 2))
            chip.fillColor = Bool.random() ? themeColor : grainDark
            chip.strokeColor = .clear
            chip.zRotation = CGFloat.random(in: 0...(2 * .pi))

            let angle = CGFloat.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 45...115)
            let dx = cos(angle) * speed
            let dy = sin(angle) * speed
            let duration = Double.random(in: 0.22...0.45)

            let move1 = SKAction.moveBy(x: dx, y: dy, duration: duration * 0.4)
            move1.timingMode = .easeOut
            let gravity = SKAction.moveBy(x: dx * 0.1, y: -CGFloat.random(in: 20...50), duration: duration * 0.6)
            gravity.timingMode = .easeIn
            let rotate = SKAction.rotate(byAngle: CGFloat.random(in: -5...5), duration: duration)
            let fade = SKAction.fadeOut(withDuration: duration)

            chip.run(SKAction.group([
                SKAction.sequence([move1, gravity]),
                rotate, fade,
                SKAction.sequence([SKAction.wait(forDuration: duration), SKAction.removeFromParent()])
            ]))
            container.addChild(chip)
        }

        // ── Emitter 3: Debris toward viewer (grow in scale, fast fade) ────────────
        let debrisCount = isBig ? 4 : 2
        for _ in 0..<debrisCount {
            let w = CGFloat.random(in: 8...16)
            let h = CGFloat.random(in: 5...11)
            let debris = SKShapeNode(path: makeShardPath(w: w, h: h))
            debris.fillColor = Bool.random() ? themeColor : grainLight
            debris.strokeColor = grainDark.withAlphaComponent(0.3)
            debris.lineWidth = 0.5
            debris.zRotation = CGFloat.random(in: 0...(2 * .pi))

            let duration = Double.random(in: 0.22...0.42)
            let growScale = CGFloat.random(in: 2.5...5.0) // rushes toward viewer
            let dx = CGFloat.random(in: -25...25)
            let dy = CGFloat.random(in: -15...20)

            let grow = SKAction.scale(to: growScale, duration: duration)
            grow.timingMode = .easeIn
            let move = SKAction.moveBy(x: dx, y: dy, duration: duration)
            let fade = SKAction.fadeOut(withDuration: duration * 0.75)
            let rotate = SKAction.rotate(byAngle: CGFloat.random(in: -2...2), duration: duration)

            debris.run(SKAction.group([grow, move, fade, rotate,
                SKAction.sequence([SKAction.wait(forDuration: duration), SKAction.removeFromParent()])]))
            container.addChild(debris)
        }

        // ── Emitter 4: Dust puffs ─────────────────────────────────────────────────
        let dustCount = isBig ? 5 : 3
        for _ in 0..<dustCount {
            let radius = CGFloat.random(in: 7...15)
            let dust = SKShapeNode(circleOfRadius: radius)
            dust.fillColor = themeColor.withAlphaComponent(0.28)
            dust.strokeColor = .clear
            dust.alpha = 0.5

            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 12...35)
            let duration = Double.random(in: 0.2...0.38)

            let move = SKAction.moveBy(x: cos(angle) * distance, y: sin(angle) * distance, duration: duration)
            move.timingMode = .easeOut
            let grow = SKAction.scale(to: 2.2, duration: duration)
            let fade = SKAction.fadeOut(withDuration: duration)

            dust.run(SKAction.group([move, grow, fade,
                SKAction.sequence([SKAction.wait(forDuration: duration), SKAction.removeFromParent()])]))
            container.addChild(dust)
        }

        // ── Emitter 5: Sparkles (additive glow, all directions + upward bias) ─────
        let sparkleCount = isBig ? 6 : 3
        for _ in 0..<sparkleCount {
            let sparkle = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...5))
            sparkle.fillColor = .white
            sparkle.strokeColor = .clear
            sparkle.blendMode = .add
            sparkle.alpha = 0.9

            let angle = CGFloat.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 20...60)
            let dx = cos(angle) * speed
            let dy = sin(angle) * speed + CGFloat.random(in: 10...35) // upward bias
            let duration = Double.random(in: 0.28...0.5)

            let move = SKAction.moveBy(x: dx, y: dy, duration: duration)
            move.timingMode = .easeOut
            let fade = SKAction.fadeOut(withDuration: duration)
            let shrink = SKAction.scale(to: 0.15, duration: duration)

            sparkle.run(SKAction.group([move, fade, shrink,
                SKAction.sequence([SKAction.wait(forDuration: duration), SKAction.removeFromParent()])]))
            container.addChild(sparkle)
        }

        // Clean up container after longest animation
        container.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.7),
            SKAction.removeFromParent()
        ]))
    }

    /// Expanding shockwave ring effect
    func spawnShockwaveRing(at position: CGPoint, color: SKColor) {
        let ring = SKShapeNode(circleOfRadius: tileSize * 0.3)
        ring.position = position
        ring.fillColor = .clear
        ring.strokeColor = color
        ring.lineWidth = 8
        ring.alpha = 0.8
        ring.zPosition = 55
        ring.blendMode = .add
        ring.setScale(0.2)
        boardNode.addChild(ring)

        ring.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 1.6, duration: 0.22),
                SKAction.fadeOut(withDuration: 0.25),
                SKAction.customAction(withDuration: 0.22) { node, elapsed in
                    // Thin out the line as it expands
                    if let shape = node as? SKShapeNode {
                        let progress = elapsed / 0.22
                        shape.lineWidth = max(1, 8 * (1 - progress))
                    }
                }
            ]),
            SKAction.removeFromParent()
        ]))
    }

    /// Screen shake for special clears
    func shakeScreen(intensity: CGFloat = 4, duration: TimeInterval = 0.15) {
        guard let boardNode = boardNode else { return }
        let originalPos = boardNode.position
        var actions: [SKAction] = []
        let shakeCount = Int(duration / 0.03)
        for _ in 0..<shakeCount {
            let dx = CGFloat.random(in: -intensity...intensity)
            let dy = CGFloat.random(in: -intensity...intensity)
            actions.append(SKAction.moveBy(x: dx, y: dy, duration: 0.03))
        }
        actions.append(SKAction.move(to: originalPos, duration: 0.03))
        boardNode.run(SKAction.sequence(actions))
    }

    func animateLaserEffect(at tile: TileModel, isRow: Bool) {
        let pos = positionForTile(row: tile.row, col: tile.col)

        // Inner bright line
        let line = SKShapeNode()
        let path = CGMutablePath()

        if isRow {
            path.move(to: CGPoint(x: -tileSize, y: pos.y))
            path.addLine(to: CGPoint(x: tileSize * CGFloat(boardModel.cols) + tileSize, y: pos.y))
        } else {
            path.move(to: CGPoint(x: pos.x, y: -tileSize))
            path.addLine(to: CGPoint(x: pos.x, y: tileSize * CGFloat(boardModel.rows) + tileSize))
        }

        line.path = path
        line.strokeColor = SKColor(red: 0.5, green: 0.9, blue: 1.0, alpha: 1.0)
        line.lineWidth = 4
        line.glowWidth = 12
        line.zPosition = 60
        line.blendMode = .add
        boardNode.addChild(line)

        // Outer glow line
        let outerLine = SKShapeNode(path: path)
        outerLine.strokeColor = SKColor(red: 0.2, green: 0.5, blue: 1.0, alpha: 0.5)
        outerLine.lineWidth = 14
        outerLine.zPosition = 59
        outerLine.blendMode = .add
        boardNode.addChild(outerLine)

        // Sparkles along the laser path
        let sparkleCount = boardModel.cols
        for i in 0..<sparkleCount {
            let sparkle = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...4))
            sparkle.fillColor = .white
            sparkle.strokeColor = .clear
            sparkle.blendMode = .add
            if isRow {
                sparkle.position = CGPoint(x: tileSize * CGFloat(i) + tileSize * 0.5, y: pos.y)
            } else {
                sparkle.position = CGPoint(x: pos.x, y: tileSize * CGFloat(i) + tileSize * 0.5)
            }
            sparkle.zPosition = 61
            boardNode.addChild(sparkle)

            let drift = SKAction.moveBy(
                x: isRow ? 0 : CGFloat.random(in: -15...15),
                y: isRow ? CGFloat.random(in: -15...15) : 0,
                duration: 0.3
            )
            sparkle.run(SKAction.sequence([
                SKAction.wait(forDuration: Double(i) * 0.02),
                SKAction.group([drift, SKAction.fadeOut(withDuration: 0.3)]),
                SKAction.removeFromParent()
            ]))
        }

        let fade = SKAction.sequence([
            SKAction.wait(forDuration: 0.15),
            SKAction.fadeOut(withDuration: 0.2),
            SKAction.removeFromParent()
        ])
        line.run(fade)
        outerLine.run(fade.copy() as! SKAction)

        // Screen shake for laser
        shakeScreen(intensity: 4, duration: 0.15)
    }

    func animateBombEffect(at tile: TileModel) {
        let pos = positionForTile(row: tile.row, col: tile.col)

        // Central flash
        let flash = SKShapeNode(circleOfRadius: tileSize * 1.2)
        flash.position = pos
        flash.fillColor = SKColor(red: 1.0, green: 0.7, blue: 0.2, alpha: 0.9)
        flash.strokeColor = .clear
        flash.zPosition = 62
        flash.blendMode = .add
        flash.setScale(0.1)
        boardNode.addChild(flash)

        flash.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 1.2, duration: 0.12),
                SKAction.fadeOut(withDuration: 0.18)
            ]),
            SKAction.removeFromParent()
        ]))

        // Expanding shockwave ring
        spawnShockwaveRing(at: pos, color: SKColor(red: 1.0, green: 0.42, blue: 0.21, alpha: 1.0))

        // Second larger ring with delay
        let ring2 = SKShapeNode(circleOfRadius: tileSize * 0.4)
        ring2.position = pos
        ring2.fillColor = .clear
        ring2.strokeColor = SKColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 0.6)
        ring2.lineWidth = 6
        ring2.zPosition = 55
        ring2.blendMode = .add
        ring2.setScale(0.3)
        boardNode.addChild(ring2)

        ring2.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.06),
            SKAction.group([
                SKAction.scale(to: 2.0, duration: 0.28),
                SKAction.fadeOut(withDuration: 0.3)
            ]),
            SKAction.removeFromParent()
        ]))

        // Debris particles
        spawnLayeredParticles(at: pos, specialType: .bomb)

        // Screen shake for bomb
        shakeScreen(intensity: 6, duration: 0.18)
    }

    /// Board-wide explosion visual for dual-bomb
    func animateBoardExplosion() {
        // Screen flash
        let flash = SKShapeNode(rectOf: size)
        flash.fillColor = SKColor(red: 1.0, green: 0.9, blue: 0.5, alpha: 0.9)
        flash.strokeColor = .clear
        flash.position = CGPoint(x: size.width / 2, y: size.height / 2)
        flash.zPosition = 500
        flash.blendMode = .add
        addChild(flash)

        let flashAction = SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.35),
            SKAction.removeFromParent()
        ])
        flash.run(flashAction)

        // Massive particle burst from center
        let centerPos = CGPoint(
            x: tileSize * CGFloat(boardModel.cols) / 2,
            y: tileSize * CGFloat(boardModel.rows) / 2
        )

        // Multiple shockwave rings from center
        for delay in stride(from: 0.0, to: 0.15, by: 0.05) {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self = self else { return }
                self.spawnShockwaveRing(at: centerPos, color: SKColor(red: 1.0, green: 0.7, blue: 0.2, alpha: 1.0))
            }
        }

        // Massive debris from center
        for _ in 0..<30 {
            let w = CGFloat.random(in: 4...10)
            let h = CGFloat.random(in: 3...6)
            let particle = SKShapeNode(rectOf: CGSize(width: w, height: h))
            particle.fillColor = [SKColor.yellow, .orange, .red, .white, SKColor(red: 0.83, green: 0.65, blue: 0.45, alpha: 1.0)].randomElement()!
            particle.strokeColor = .clear
            particle.position = centerPos
            particle.zPosition = 70
            particle.zRotation = CGFloat.random(in: 0...(2 * .pi))
            boardNode.addChild(particle)

            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 100...250)
            let dx = cos(angle) * distance
            let dy = sin(angle) * distance
            let duration = Double.random(in: 0.4...0.7)

            let moveOut = SKAction.moveBy(x: dx, y: dy * 0.7, duration: duration * 0.5)
            moveOut.timingMode = .easeOut
            let gravity = SKAction.moveBy(x: 0, y: -50, duration: duration * 0.5)
            gravity.timingMode = .easeIn
            let rotate = SKAction.rotate(byAngle: CGFloat.random(in: -4...4), duration: duration)
            let fade = SKAction.fadeOut(withDuration: duration)

            particle.run(SKAction.group([
                SKAction.sequence([moveOut, gravity]),
                rotate, fade,
                SKAction.sequence([SKAction.wait(forDuration: duration), SKAction.removeFromParent()])
            ]))
        }

        // Heavy screen shake
        shakeScreen(intensity: 8, duration: 0.25)
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

        // Coin display
        coinHUDLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        coinHUDLabel.fontSize = 16
        coinHUDLabel.fontColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)
        coinHUDLabel.position = CGPoint(x: size.width - 80, y: hudY - 5)
        coinHUDLabel.horizontalAlignmentMode = .center
        coinHUDLabel.text = "🪙 \(CoinManager.shared.balance)"
        hudNode.addChild(coinHUDLabel)

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

        // Update coin display — show balance + earned this level
        if state.coinsEarnedThisLevel > 0 {
            coinHUDLabel?.text = "🪙 \(CoinManager.shared.balance) (+\(state.coinsEarnedThisLevel))"
        } else {
            coinHUDLabel?.text = "🪙 \(CoinManager.shared.balance)"
        }
    }

    // MARK: - Power-Up Bar

    func setupPowerUpBar() {
        powerUpBar = SKNode()
        powerUpBar.position = CGPoint(x: 0, y: 30)
        powerUpBar.zPosition = 200
        addChild(powerUpBar)

        let types: [PowerUpType] = [.hint, .shuffle, .bomb, .laser, .crossLaser, .mine]
        let buttonWidth: CGFloat = 55
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

        let bg = SKShapeNode(rectOf: CGSize(width: 46, height: 46), cornerRadius: 8)
        bg.fillColor = SKColor(white: 0.2, alpha: 0.9)
        bg.strokeColor = SKColor(white: 0.5, alpha: 0.5)
        bg.lineWidth = 1
        container.addChild(bg)

        let icon = SKLabelNode(fontNamed: "AvenirNext-Bold")
        icon.fontSize = 20
        icon.verticalAlignmentMode = .center

        switch type {
        case .hint: icon.text = "💡"
        case .shuffle: icon.text = "🔀"
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
        countLabel.position = CGPoint(x: 16, y: -16)
        countLabel.zPosition = 2
        countLabel.name = "countLabel"
        container.addChild(countLabel)
        powerUpCountLabels[type] = countLabel

        return container
    }

    func updatePowerUpCounts() {
        guard let state = gameState else { return }
        powerUpCountLabels[.hint]?.text = "\(state.hintCount)"
        powerUpCountLabels[.shuffle]?.text = "\(state.shuffleCount)"
        powerUpCountLabels[.bomb]?.text = "\(state.bombCount)"
        powerUpCountLabels[.laser]?.text = "\(state.laserCount)"
        powerUpCountLabels[.crossLaser]?.text = "\(state.crossLaserCount)"
        powerUpCountLabels[.mine]?.text = "\(state.mineCount)"
    }

    func checkPowerUpTap(at location: CGPoint) -> PowerUpType? {
        let types: [PowerUpType] = [.hint, .shuffle, .bomb, .laser, .crossLaser, .mine]
        for type in types {
            if let btn = powerUpButtons[type] {
                let btnPos = btn.convert(CGPoint.zero, to: self)
                let rect = CGRect(x: btnPos.x - 23, y: btnPos.y - 23, width: 46, height: 46)
                if rect.contains(location) {
                    return type
                }
            }
        }
        return nil
    }

    func handlePowerUpActivation(_ type: PowerUpType) {
        guard powerUpSystem.canUse(type) else { return }
        SoundManager.shared.playPowerUp()

        switch type {
        case .hint:
            // Execute immediately — show hint path that persists until next word
            if let path = powerUpSystem.executeHint() {
                showHintHighlight(path: path)
            }

        case .shuffle:
            // Execute immediately — shuffle all normal tiles
            if powerUpSystem.executeShuffle() {
                renderBoard()
            }

        case .bomb:
            // Place bomb tile randomly on board
            if let tile = powerUpSystem.placeBomb() {
                refreshTileSprite(for: tile)
            }

        case .laser:
            // Place laser tile on board, then show direction picker
            if let tile = powerUpSystem.placeLaser() {
                refreshTileSprite(for: tile)
                pendingLaserTile = tile
                showLaserDirectionPicker()
            }

        case .crossLaser:
            // Place cross laser tile randomly on board
            if let tile = powerUpSystem.placeCrossLaser() {
                refreshTileSprite(for: tile)
            }

        case .mine:
            // Place mine overlay randomly on board
            if let tile = powerUpSystem.placeMine() {
                refreshTileSprite(for: tile)
            }
        }

        updateHUD()
    }

    /// Refresh a single tile's sprite after its properties changed
    func refreshTileSprite(for tile: TileModel) {
        if let oldSprite = tileSprites[tile.id] {
            oldSprite.removeFromParent()
        }
        let newSprite = createTileSprite(for: tile)
        boardNode.addChild(newSprite)
        tileSprites[tile.id] = newSprite

        // Flash animation to draw attention
        let flash = SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.15),
            SKAction.scale(to: 1.0, duration: 0.15)
        ])
        newSprite.run(flash)
    }

    // MARK: - Hint Highlights (persist until next word)

    func showHintHighlight(path: [TileModel]) {
        clearHintHighlights()
        hintedTiles = path

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

                // Pulse animation — persists indefinitely
                let pulse = SKAction.repeatForever(SKAction.sequence([
                    SKAction.fadeAlpha(to: 0.1, duration: 0.5),
                    SKAction.fadeAlpha(to: 0.5, duration: 0.5)
                ]))
                glow.run(pulse)
            }
        }

        // Draw hint path line
        if path.count >= 2 {
            let linePath = CGMutablePath()
            let firstPos = positionForTile(row: path[0].row, col: path[0].col)
            linePath.move(to: firstPos)
            for i in 1..<path.count {
                let pos = positionForTile(row: path[i].row, col: path[i].col)
                linePath.addLine(to: pos)
            }
            let hintLine = SKShapeNode(path: linePath)
            hintLine.strokeColor = SKColor(red: 1.0, green: 0.75, blue: 0.15, alpha: 0.6)
            hintLine.lineWidth = 3
            hintLine.lineCap = .round
            hintLine.lineJoin = .round
            hintLine.zPosition = 9
            hintLine.name = "hintLine"
            let dashPattern: [CGFloat] = [8, 4]
            hintLine.path = linePath.copy(dashingWithPhase: 0, lengths: dashPattern)
            boardNode.addChild(hintLine)
            hintNodes.append(hintLine)

            // Pulse the line too
            let linePulse = SKAction.repeatForever(SKAction.sequence([
                SKAction.fadeAlpha(to: 0.3, duration: 0.5),
                SKAction.fadeAlpha(to: 0.8, duration: 0.5)
            ]))
            hintLine.run(linePulse)
        }
    }

    func clearHintHighlights() {
        for node in hintNodes {
            node.removeFromParent()
        }
        hintNodes.removeAll()
        hintedTiles.removeAll()
    }

    // MARK: - Laser Direction Picker

    func showLaserDirectionPicker() {
        laserDirectionOverlay?.removeFromParent()

        let overlay = SKNode()
        overlay.zPosition = 300
        overlay.name = "laserDirectionOverlay"
        addChild(overlay)
        laserDirectionOverlay = overlay

        // Background pill
        let pillWidth: CGFloat = 280
        let pillHeight: CGFloat = 60
        let pill = SKShapeNode(rectOf: CGSize(width: pillWidth, height: pillHeight), cornerRadius: 14)
        pill.fillColor = SKColor(red: 0.1, green: 0.08, blue: 0.2, alpha: 0.95)
        pill.strokeColor = SKColor(red: 0.5, green: 0.4, blue: 0.9, alpha: 0.7)
        pill.lineWidth = 1.5
        pill.position = CGPoint(x: size.width / 2, y: 80)
        overlay.addChild(pill)

        // Prompt label
        let promptLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        promptLabel.text = "Laser direction:"
        promptLabel.fontSize = 13
        promptLabel.fontColor = SKColor(white: 0.7, alpha: 1.0)
        promptLabel.horizontalAlignmentMode = .center
        promptLabel.verticalAlignmentMode = .center
        promptLabel.position = CGPoint(x: 0, y: 12)
        pill.addChild(promptLabel)

        // Row button
        let rowBtn = createDirectionButton(text: "↔ Row", name: "laserRowBtn")
        rowBtn.position = CGPoint(x: -68, y: -10)
        pill.addChild(rowBtn)

        // Column button
        let colBtn = createDirectionButton(text: "↕ Column", name: "laserColBtn")
        colBtn.position = CGPoint(x: 52, y: -10)
        pill.addChild(colBtn)

        // Cancel
        let cancelLabel = SKLabelNode(fontNamed: "AvenirNext-Regular")
        cancelLabel.text = "✕"
        cancelLabel.fontSize = 14
        cancelLabel.fontColor = SKColor(white: 0.45, alpha: 1.0)
        cancelLabel.position = CGPoint(x: pillWidth / 2 - 16, y: pillHeight / 2 - 14)
        cancelLabel.name = "laserCancelBtn"
        pill.addChild(cancelLabel)

        // Pulse animation
        overlay.alpha = 0
        overlay.run(SKAction.fadeIn(withDuration: 0.2))
    }

    private func createDirectionButton(text: String, name: String) -> SKNode {
        let container = SKNode()
        container.name = name

        let bg = SKShapeNode(rectOf: CGSize(width: 110, height: 34), cornerRadius: 10)
        bg.fillColor = SKColor(red: 0.35, green: 0.22, blue: 0.7, alpha: 1.0)
        bg.strokeColor = .clear
        container.addChild(bg)

        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = text
        label.fontSize = 14
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.name = name
        container.addChild(label)

        return container
    }

    func dismissLaserDirectionPicker() {
        laserDirectionOverlay?.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.15),
            SKAction.removeFromParent()
        ]))
        laserDirectionOverlay = nil
        pendingLaserTile = nil
    }

    func fireLaser(direction: String) {
        guard let tile = pendingLaserTile else {
            dismissLaserDirectionPicker()
            return
        }
        dismissLaserDirectionPicker()

        let isRow = direction == "row"

        // Animate laser effect
        animateLaserEffect(at: tile, isRow: isRow)

        // Clear the row or column
        var tilesToClear: [TileModel] = []
        if isRow {
            for c in 0..<boardModel.cols {
                if let t = boardModel.tileAt(row: tile.row, col: c) {
                    tilesToClear.append(t)
                }
            }
        } else {
            for r in 0..<boardModel.rows {
                if let t = boardModel.tileAt(row: r, col: tile.col) {
                    tilesToClear.append(t)
                }
            }
        }

        // Score explosion points
        let pts = ScoringEngine.shared.explosionScore(for: tilesToClear)
        gameState.score += pts

        animateExplosions(tiles: tilesToClear) { [weak self] in
            guard let self = self else { return }
            let _ = self.boardModel.clearTiles(tilesToClear)
            let gravityResult = self.boardModel.applyGravityAndRefill(
                wordSubmitCount: self.gameState.wordSubmitCount
            )
            self.animateGravityAndRefill(result: gravityResult) { [weak self] in
                self?.checkLevelCompletion()
                self?.updateHUD()
            }
        }

        updateHUD()
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

        // Update lifetime stats (only on completion)
        if gameState.isLevelComplete {
            let longestWord = gameState.wordsFound.max(by: { $0.count < $1.count }) ?? ""
            persistence.updateStatsOnLevelComplete(
                levelNumber: levelNum,
                wordsFound: gameState.wordsFound.count,
                score: gameState.score,
                stars: stars,
                maxStreak: Double(gameState.maxStreakReached),
                maxCascade: gameState.maxCascadeReached,
                timeRemaining: Int(gameState.timeRemaining),
                coinsEarned: gameState.coinsEarnedThisLevel,
                longestWord: longestWord
            )
        }

        // Play level end sound
        if gameState.isLevelComplete {
            SoundManager.shared.playLevelComplete()
        }

        // Show results screen
        showLevelCompleteScreen(score: gameState.score, stars: stars, completed: gameState.isLevelComplete)
    }

    func showLevelCompleteScreen(score: Int, stars: Int, completed: Bool) {
        // Determine if this is a replay
        let persistence = PersistenceManager.shared
        let progress = persistence.loadProgress()
        let isReplay = progress.levelProgress[levelConfig?.levelNumber ?? 1]?.completed ?? false

        // Calculate remaining time/moves for efficiency bonus
        let timeRemaining = Int(gameState.timeRemaining)
        let totalTime = levelConfig?.timeLimitSeconds ?? 60
        let movesRemaining = (levelConfig?.moveLimit ?? 0) - gameState.movesUsed

        // Calculate coins earned
        let coinResult = LevelCoinCalculator.calculate(
            levelNumber: levelConfig?.levelNumber ?? 1,
            stars: stars,
            wordsFound: gameState.wordsFound,
            maxStreakReached: gameState.maxStreakReached,
            maxCascadeReached: gameState.maxCascadeReached,
            timeRemaining: timeRemaining,
            totalTime: totalTime,
            movesRemaining: movesRemaining,
            goalType: levelConfig?.goalType ?? .scoreTimed,
            isReplay: isReplay && completed
        )

        // Award coins if level completed
        if completed {
            CoinManager.shared.addCoins(coinResult.total, reason: .levelReward)
        }

        let overlay = SKShapeNode(rectOf: size)
        overlay.fillColor = SKColor(white: 0.0, alpha: 0.7)
        overlay.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.zPosition = 500
        overlay.name = "resultOverlay"
        addChild(overlay)

        let panelHeight: CGFloat = completed ? 440 : 400
        let panel = SKShapeNode(rectOf: CGSize(width: 300, height: panelHeight), cornerRadius: 20)
        panel.fillColor = SKColor(red: 0.15, green: 0.15, blue: 0.3, alpha: 1.0)
        panel.strokeColor = SKColor(white: 0.5, alpha: 0.5)
        panel.lineWidth = 2
        panel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        panel.zPosition = 501
        panel.name = "resultPanel"
        addChild(panel)

        // Title — correct failure text based on level type
        let title = SKLabelNode(fontNamed: "AvenirNext-Bold")
        if completed {
            title.text = "Level Complete!"
            title.fontColor = .green
        } else if let config = levelConfig, config.goalType == .clearIceMoves {
            title.text = "Out of Moves!"
            title.fontColor = .red
        } else {
            title.text = "Time's Up!"
            title.fontColor = .red
        }
        title.fontSize = 28
        title.position = CGPoint(x: 0, y: panelHeight / 2 - 40)
        panel.addChild(title)

        // Stars
        let starsText = SKLabelNode(fontNamed: "AvenirNext-Bold")
        starsText.text = String(repeating: "⭐", count: stars) + String(repeating: "☆", count: 3 - stars)
        starsText.fontSize = 36
        starsText.position = CGPoint(x: 0, y: panelHeight / 2 - 80)
        panel.addChild(starsText)

        // Score
        let scoreText = SKLabelNode(fontNamed: "AvenirNext-Medium")
        scoreText.text = "Score: \(score)"
        scoreText.fontSize = 22
        scoreText.fontColor = .white
        scoreText.position = CGPoint(x: 0, y: panelHeight / 2 - 115)
        panel.addChild(scoreText)

        // Coin breakdown (only if completed)
        if completed {
            let coinHeaderY = panelHeight / 2 - 145
            let coinHeader = SKLabelNode(fontNamed: "AvenirNext-Bold")
            coinHeader.text = "Coins Earned"
            coinHeader.fontSize = 16
            coinHeader.fontColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)
            coinHeader.position = CGPoint(x: 0, y: coinHeaderY)
            panel.addChild(coinHeader)

            var breakdownY = coinHeaderY - 20
            for transaction in coinResult.transactions {
                let row = SKLabelNode(fontNamed: "AvenirNext-Regular")
                row.text = "\(transaction.label): +\(transaction.amount)"
                row.fontSize = 12
                row.fontColor = SKColor(white: 0.7, alpha: 1.0)
                row.position = CGPoint(x: 0, y: breakdownY)
                panel.addChild(row)
                breakdownY -= 16
            }

            let totalLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
            totalLabel.text = "Total: +\(coinResult.total) 🪙"
            totalLabel.fontSize = 16
            totalLabel.fontColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)
            totalLabel.position = CGPoint(x: 0, y: breakdownY - 5)
            panel.addChild(totalLabel)
        }

        // Buttons
        var btnY: CGFloat = -panelHeight / 2 + 130

        if !completed && continueManager.canContinue {
            // --- Redesigned Continue/Forfeit Screen ---

            // Watch Ad option (free, 1 per level)
            if continueManager.canUseAdContinue {
                let adBtn = createButton(text: "▶ Watch Ad (Free Continue)", width: 260, height: 44)
                adBtn.position = CGPoint(x: 0, y: btnY + 55)
                adBtn.name = "adContinueBtn"
                panel.addChild(adBtn)

                // Ad label
                let adNote = SKLabelNode(fontNamed: "AvenirNext-Regular")
                adNote.text = "+1 minute · 1 per level"
                adNote.fontSize = 11
                adNote.fontColor = SKColor(white: 0.6, alpha: 1.0)
                adNote.position = CGPoint(x: 0, y: btnY + 30)
                panel.addChild(adNote)
            }

            // Continue with Coins option
            let cost = continueManager.currentCost
            let canAfford = CoinManager.shared.canAfford(cost)
            let coinBtnText = canAfford ? "Continue (🪙\(cost))" : "Need 🪙\(cost)"
            let coinBtn = createButton(text: coinBtnText, width: 260, height: 44)
            coinBtn.position = CGPoint(x: 0, y: btnY - 10)
            coinBtn.name = canAfford ? "continueBtn" : "continueDisabledBtn"
            panel.addChild(coinBtn)

            if !canAfford {
                // Grey out the button
                if let bg = coinBtn.children.first as? SKShapeNode {
                    bg.fillColor = SKColor(white: 0.3, alpha: 0.8)
                }
            }

            let coinNote = SKLabelNode(fontNamed: "AvenirNext-Regular")
            coinNote.text = "+1 minute · \(3 - continueManager.continueCount) remaining"
            coinNote.fontSize = 11
            coinNote.fontColor = SKColor(white: 0.6, alpha: 1.0)
            coinNote.position = CGPoint(x: 0, y: btnY - 35)
            panel.addChild(coinNote)

            // Forfeit option with coins-at-risk warning
            let coinsAtRisk = gameState.coinsEarnedThisLevel
            let forfeitBtn = createButton(text: "Forfeit Level", width: 260, height: 44)
            forfeitBtn.position = CGPoint(x: 0, y: btnY - 75)
            forfeitBtn.name = "forfeitBtn"
            // Red-tinted background
            if let bg = forfeitBtn.children.first as? SKShapeNode {
                bg.fillColor = SKColor(red: 0.6, green: 0.15, blue: 0.15, alpha: 1.0)
            }
            panel.addChild(forfeitBtn)

            if coinsAtRisk > 0 {
                let forfeitWarning = SKLabelNode(fontNamed: "AvenirNext-Bold")
                forfeitWarning.text = "⚠️ You will lose \(coinsAtRisk) coins earned this level"
                forfeitWarning.fontSize = 11
                forfeitWarning.fontColor = SKColor(red: 1.0, green: 0.4, blue: 0.4, alpha: 1.0)
                forfeitWarning.position = CGPoint(x: 0, y: btnY - 100)
                panel.addChild(forfeitWarning)
            } else {
                let forfeitNote = SKLabelNode(fontNamed: "AvenirNext-Regular")
                forfeitNote.text = "No coins at risk"
                forfeitNote.fontSize = 11
                forfeitNote.fontColor = SKColor(white: 0.5, alpha: 1.0)
                forfeitNote.position = CGPoint(x: 0, y: btnY - 100)
                panel.addChild(forfeitNote)
            }

        } else if completed {
            // --- Level Complete Buttons ---

            // Next Level button
            if (levelConfig?.levelNumber ?? 10) < 10 {
                let nextBtn = createButton(text: "Next Level", width: 200, height: 44)
                nextBtn.position = CGPoint(x: 0, y: btnY)
                nextBtn.name = "nextLevelBtn"
                panel.addChild(nextBtn)
                btnY -= 50
            }

            // Retry button
            let retryBtn = createButton(text: "Retry", width: 200, height: 44)
            retryBtn.position = CGPoint(x: 0, y: btnY)
            retryBtn.name = "retryBtn"
            panel.addChild(retryBtn)
            btnY -= 50

            // Map button
            let mapBtn = createButton(text: "Level Map", width: 200, height: 44)
            mapBtn.position = CGPoint(x: 0, y: btnY)
            mapBtn.name = "mapBtn"
            panel.addChild(mapBtn)

        } else {
            // No continues left — show retry and map only
            let retryBtn = createButton(text: "Retry", width: 200, height: 44)
            retryBtn.position = CGPoint(x: 0, y: btnY)
            retryBtn.name = "retryBtn"
            panel.addChild(retryBtn)
            btnY -= 50

            let mapBtn = createButton(text: "Level Map", width: 200, height: 44)
            mapBtn.position = CGPoint(x: 0, y: btnY)
            mapBtn.name = "mapBtn"
            panel.addChild(mapBtn)
        }

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

            // Check Continue
            if let continueBtn = panel.childNode(withName: "continueBtn") {
                let btnRect = CGRect(x: continueBtn.position.x - 120, y: continueBtn.position.y - 22,
                                     width: 240, height: 44)
                if btnRect.contains(panelLocation) {
                    continueLevel()
                    return
                }
            }

            // Check Ad Continue
            if let adBtn = panel.childNode(withName: "adContinueBtn") {
                let btnRect = CGRect(x: adBtn.position.x - 120, y: adBtn.position.y - 20,
                                     width: 240, height: 40)
                if btnRect.contains(panelLocation) {
                    continueWithAd()
                    return
                }
            }

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

            // Check Forfeit
            if let forfeitBtn = panel.childNode(withName: "forfeitBtn") {
                let btnRect = CGRect(x: forfeitBtn.position.x - 130, y: forfeitBtn.position.y - 22,
                                     width: 260, height: 44)
                if btnRect.contains(panelLocation) {
                    forfeitLevel()
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

    func forfeitLevel() {
        // Deduct coins earned this level
        let coinsToLose = gameState.coinsEarnedThisLevel
        if coinsToLose > 0 {
            CoinManager.shared.spendCoins(coinsToLose, reason: .continueSpend)
        }
        gameState.coinsEarnedThisLevel = 0

        // Return to level map
        gameTimer?.invalidate()
        let scene = LevelMapScene(size: size)
        scene.scaleMode = scaleMode
        view?.presentScene(scene, transition: SKTransition.fade(withDuration: 0.5))
    }

    func goToLevelMap() {
        gameTimer?.invalidate()
        let scene = LevelMapScene(size: size)
        scene.scaleMode = scaleMode
        view?.presentScene(scene, transition: SKTransition.fade(withDuration: 0.5))
    }

    func continueLevel() {
        guard continueManager.continueWithCoins() else { return }

        // Remove result overlay
        childNode(withName: "resultOverlay")?.removeFromParent()
        childNode(withName: "resultPanel")?.removeFromParent()

        // Reset game over state
        gameState.isGameOver = false

        // Apply continue bonus
        if let config = levelConfig {
            let bonus = continueManager.continueBonus(for: config.goalType)
            if bonus.time > 0 {
                gameState.timeRemaining += TimeInterval(bonus.time)
                startTimerIfNeeded()
            }
            if bonus.moves > 0 {
                // Reduce movesUsed to grant extra moves
                gameState.movesUsed = max(0, gameState.movesUsed - bonus.moves)
            }
        }

        updateHUD()
    }

    func continueWithAd() {
        guard continueManager.continueWithAd() else { return }

        // Remove result overlay
        childNode(withName: "resultOverlay")?.removeFromParent()
        childNode(withName: "resultPanel")?.removeFromParent()

        // Reset game over state
        gameState.isGameOver = false

        // Apply continue bonus
        if let config = levelConfig {
            let bonus = continueManager.continueBonus(for: config.goalType)
            if bonus.time > 0 {
                gameState.timeRemaining += TimeInterval(bonus.time)
                startTimerIfNeeded()
            }
            if bonus.moves > 0 {
                gameState.movesUsed = max(0, gameState.movesUsed - bonus.moves)
            }
        }

        updateHUD()
    }

    func startTimerIfNeeded() {
        guard gameTimer == nil || !(gameTimer?.isValid ?? false) else { return }
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let state = self.gameState else { return }
            if state.timerStarted {
                state.timeRemaining -= 1
                if state.timeRemaining <= 0 {
                    state.timeRemaining = 0
                    self.gameTimer?.invalidate()
                    self.checkLevelCompletion()
                }
                self.updateHUD()
            }
        }
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
