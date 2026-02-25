import SpriteKit

// MARK: - ExplosionManager
//
// Drives 3-tier layered explosion VFX for WordDash.
// All effects are < 1.0s (big tier max 1.2s), 60-FPS-safe with node pooling.
//
// Usage:
//   ExplosionManager.shared.playExplosion(origin: pos, tier: .big, cause: .bomb, in: scene)

final class ExplosionManager {

    static let shared = ExplosionManager()
    private init() {}

    // MARK: - Debug

    /// Set true to print active node/particle counts after each explosion.
    var debugEnabled: Bool = false

    // MARK: - Public API

    /// Play a layered explosion at `origin` (scene coordinates) for the given tier and cause.
    /// - Parameters:
    ///   - origin: Center of the explosion in the parent node's coordinate space.
    ///   - tier: small / medium / big
    ///   - cause: What triggered the explosion (affects color/ring)
    ///   - parent: The SKNode to attach effect nodes to (typically boardNode or effectsLayer)
    ///   - tileSize: Current tile size for flash radius scaling
    func playExplosion(
        origin: CGPoint,
        tier: ExplosionTier,
        cause: ExplosionCause,
        in parent: SKNode,
        tileSize: CGFloat = 48
    ) {
        let color = effectColor(for: cause)

        switch tier {
        case .small:  playSmallExplosion(at: origin, color: color, parent: parent, tileSize: tileSize)
        case .medium: playMediumExplosion(at: origin, color: color, cause: cause, parent: parent, tileSize: tileSize)
        case .big:    playBigExplosion(at: origin, color: color, cause: cause, parent: parent, tileSize: tileSize)
        }

        if debugEnabled {
            let count = parent.children.count
            print("[ExplosionManager] Active child nodes in parent after \(tier) explosion: \(count)")
        }
    }

    // MARK: - Small Tier

    private func playSmallExplosion(at pos: CGPoint, color: SKColor, parent: SKNode, tileSize: CGFloat) {
        let cfg = ExplosionConfig.Small.self

        // Additive flash burst
        spawnFlashBurst(
            at: pos, color: color, parent: parent, tileSize: tileSize,
            startScale: cfg.flashStartScale, endScale: cfg.flashEndScale,
            duration: cfg.flashDuration, fadeDuration: cfg.flashFadeDuration
        )

        // Sparks
        let sparkCount = Int.random(in: cfg.sparkCountMin...cfg.sparkCountMax)
        spawnSparks(
            count: min(sparkCount, ExplosionConfig.maxSparks),
            at: pos, color: color, parent: parent,
            speedRange: 30...80, sizeRange: 2...4,
            lifetimeMin: cfg.sparkLifetimeMin, lifetimeMax: cfg.sparkLifetimeMax,
            additive: true
        )
    }

    // MARK: - Medium Tier

    private func playMediumExplosion(
        at pos: CGPoint, color: SKColor, cause: ExplosionCause, parent: SKNode, tileSize: CGFloat
    ) {
        let cfg = ExplosionConfig.Medium.self

        // Flash burst
        spawnFlashBurst(
            at: pos, color: color, parent: parent, tileSize: tileSize,
            startScale: cfg.flashStartScale, endScale: cfg.flashEndScale,
            duration: cfg.flashDuration, fadeDuration: cfg.flashFadeDuration
        )

        // Shockwave ring (thin, additive)
        spawnShockwaveRing(
            at: pos, color: color, parent: parent, tileSize: tileSize,
            startScale: cfg.shockwaveStartScale, endScale: cfg.shockwaveEndScale,
            duration: cfg.shockwaveDuration, lineWidth: 6, alpha: 0.85,
            delay: 0
        )

        // Sparks
        let sparkCount = Int.random(in: cfg.sparkCountMin...cfg.sparkCountMax)
        spawnSparks(
            count: min(sparkCount, ExplosionConfig.maxSparks),
            at: pos, color: color, parent: parent,
            speedRange: 40...110, sizeRange: 2...5,
            lifetimeMin: 0.25, lifetimeMax: 0.45,
            additive: true
        )

        // Wood specks (alpha blend debris)
        let speckCount = Int.random(in: cfg.woodSpeckCountMin...cfg.woodSpeckCountMax)
        spawnWoodSplinters(
            count: min(speckCount, ExplosionConfig.maxDebris),
            at: pos, color: color, parent: parent,
            speedRange: 30...90, lifetimeMin: 0.25, lifetimeMax: 0.45,
            gravityStrength: 30
        )

        // Camera shake only for powerups
        switch cause {
        case .bomb, .laser, .crossLaser, .mine:
            if let scene = parent.scene {
                shakeScene(scene, intensity: cfg.cameraShakePx, duration: cfg.cameraShakeDuration)
            }
        default: break
        }
    }

    // MARK: - Big Tier

    private func playBigExplosion(
        at pos: CGPoint, color: SKColor, cause: ExplosionCause, parent: SKNode, tileSize: CGFloat
    ) {
        let cfg = ExplosionConfig.Big.self

        // Core flash burst
        spawnFlashBurst(
            at: pos, color: color, parent: parent, tileSize: tileSize,
            startScale: cfg.flashStartScale, endScale: cfg.flashEndScale,
            duration: cfg.flashDuration, fadeDuration: cfg.flashFadeDuration
        )

        // Primary shockwave ring
        spawnShockwaveRing(
            at: pos, color: color, parent: parent, tileSize: tileSize,
            startScale: cfg.shockwaveStartScale, endScale: cfg.shockwaveEndScale,
            duration: cfg.shockwaveDuration, lineWidth: 9, alpha: 0.9,
            delay: 0
        )

        // Secondary faint ring
        spawnShockwaveRing(
            at: pos, color: color.withAlphaComponent(0.5), parent: parent, tileSize: tileSize,
            startScale: 0.3, endScale: 2.2,
            duration: cfg.shockwaveDuration + 0.08, lineWidth: 4, alpha: 0.5,
            delay: cfg.secondRingDelay
        )

        // White inner burst ring
        spawnShockwaveRing(
            at: pos, color: SKColor.white.withAlphaComponent(0.7), parent: parent, tileSize: tileSize,
            startScale: 0.2, endScale: 1.0,
            duration: 0.18, lineWidth: 5, alpha: 0.7,
            delay: 0
        )

        // Micro sparks (short-lived, dense)
        let microCount = Int.random(in: cfg.microSparkCountMin...cfg.microSparkCountMax)
        spawnSparks(
            count: min(microCount, ExplosionConfig.maxSparks / 2),
            at: pos, color: .white, parent: parent,
            speedRange: 50...140, sizeRange: 1...3,
            lifetimeMin: 0.15, lifetimeMax: 0.30,
            additive: true
        )

        // Main sparks (slightly larger, colored)
        let mainCount = Int.random(in: cfg.mainSparkCountMin...cfg.mainSparkCountMax)
        spawnSparks(
            count: min(mainCount, ExplosionConfig.maxSparks / 2),
            at: pos, color: color, parent: parent,
            speedRange: 60...160, sizeRange: 3...6,
            lifetimeMin: 0.30, lifetimeMax: 0.55,
            additive: true
        )

        // Wood debris with gravity
        let debrisCount = Int.random(in: cfg.debrisCountMin...cfg.debrisCountMax)
        spawnWoodSplinters(
            count: min(debrisCount, ExplosionConfig.maxDebris),
            at: pos, color: color, parent: parent,
            speedRange: 60...160, lifetimeMin: 0.35, lifetimeMax: 0.60,
            gravityStrength: 60
        )

        // Camera shake
        if let scene = parent.scene {
            shakeScene(scene, intensity: cfg.cameraShakePx, duration: cfg.cameraShakeDuration)
        }

        // Warm gold screen tint pulse
        if let scene = parent.scene {
            spawnScreenTint(in: scene, color: SKColor(red: 1.0, green: 0.82, blue: 0.18, alpha: 0.18), duration: cfg.screenTintDuration)
        }
    }

    // MARK: - Primitive Builders

    /// Additive radial glow flash
    private func spawnFlashBurst(
        at pos: CGPoint, color: SKColor, parent: SKNode, tileSize: CGFloat,
        startScale: CGFloat, endScale: CGFloat,
        duration: TimeInterval, fadeDuration: TimeInterval
    ) {
        let radius = tileSize * 0.65
        let flash = SKShapeNode(circleOfRadius: radius)
        flash.position = pos
        flash.fillColor = .white
        flash.strokeColor = color.withAlphaComponent(0.6)
        flash.lineWidth = 2
        flash.alpha = 0.92
        flash.zPosition = 62
        flash.blendMode = .add
        flash.setScale(startScale)
        parent.addChild(flash)

        flash.run(.sequence([
            .group([
                .scale(to: endScale, duration: duration),
                .sequence([
                    .wait(forDuration: duration * 0.3),
                    .fadeOut(withDuration: fadeDuration - duration * 0.3)
                ])
            ]),
            .removeFromParent()
        ]))
    }

    /// Expanding shockwave ring (additive blend, line thins as it expands)
    private func spawnShockwaveRing(
        at pos: CGPoint, color: SKColor, parent: SKNode, tileSize: CGFloat,
        startScale: CGFloat, endScale: CGFloat,
        duration: TimeInterval, lineWidth: CGFloat, alpha: CGFloat,
        delay: TimeInterval
    ) {
        let ring = SKShapeNode(circleOfRadius: tileSize * 0.35)
        ring.position = pos
        ring.fillColor = .clear
        ring.strokeColor = color
        ring.lineWidth = lineWidth
        ring.alpha = alpha
        ring.zPosition = 60
        ring.blendMode = .add
        ring.setScale(startScale)
        parent.addChild(ring)

        let expand = SKAction.customAction(withDuration: duration) { node, elapsed in
            guard let shape = node as? SKShapeNode else { return }
            let progress = CGFloat(elapsed / duration)
            let currentScale = startScale + (endScale - startScale) * progress
            shape.xScale = currentScale
            shape.yScale = currentScale
            shape.lineWidth = max(0.5, lineWidth * (1 - progress * 0.85))
            shape.alpha = alpha * (1 - progress)
        }

        ring.run(.sequence([
            .wait(forDuration: delay),
            .group([expand, .sequence([.wait(forDuration: duration), .removeFromParent()])])
        ]))
    }

    /// Additive glow sparks scattered outward
    private func spawnSparks(
        count: Int, at pos: CGPoint, color: SKColor, parent: SKNode,
        speedRange: ClosedRange<CGFloat>, sizeRange: ClosedRange<CGFloat>,
        lifetimeMin: TimeInterval, lifetimeMax: TimeInterval,
        additive: Bool
    ) {
        for _ in 0..<count {
            let radius = CGFloat.random(in: sizeRange)
            let spark = SKShapeNode(circleOfRadius: radius)
            spark.position = pos
            spark.fillColor = additive ? .white : color
            spark.strokeColor = .clear
            spark.blendMode = additive ? .add : .alpha
            spark.zPosition = 58
            spark.alpha = additive ? 0.9 : 0.8
            parent.addChild(spark)

            let angle = CGFloat.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: speedRange)
            let dx = cos(angle) * speed
            let dy = sin(angle) * speed + CGFloat.random(in: 5...25) // slight upward bias
            let lifetime = TimeInterval.random(in: lifetimeMin...lifetimeMax)

            let move = SKAction.moveBy(x: dx, y: dy, duration: lifetime)
            move.timingMode = .easeOut
            let fade = SKAction.fadeOut(withDuration: lifetime)
            let shrink = SKAction.scale(to: 0.1, duration: lifetime)

            spark.run(.group([move, fade, shrink, .sequence([.wait(forDuration: lifetime), .removeFromParent()])]))
        }
    }

    /// Wood splinter debris with gravity and rotation
    private func spawnWoodSplinters(
        count: Int, at pos: CGPoint, color: SKColor, parent: SKNode,
        speedRange: ClosedRange<CGFloat>,
        lifetimeMin: TimeInterval, lifetimeMax: TimeInterval,
        gravityStrength: CGFloat
    ) {
        let grainLight = tintColor(color, by: 0.18)
        let grainDark  = tintColor(color, by: -0.15)

        for _ in 0..<count {
            let w = CGFloat.random(in: 6...18)
            let h = CGFloat.random(in: 2...5)
            let splinter = SKShapeNode(rectOf: CGSize(width: w, height: h), cornerRadius: min(h / 2, 2.5))
            splinter.fillColor = Bool.random() ? color : grainLight
            splinter.strokeColor = grainDark.withAlphaComponent(0.3)
            splinter.lineWidth = 0.5
            splinter.zRotation = CGFloat.random(in: 0...(2 * .pi))
            splinter.position = pos
            splinter.zPosition = 55
            splinter.blendMode = .alpha
            parent.addChild(splinter)

            let angle = CGFloat.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: speedRange)
            let dx = cos(angle) * speed
            let dy = sin(angle) * speed
            let lifetime = TimeInterval.random(in: lifetimeMin...lifetimeMax)

            let burst = SKAction.moveBy(x: dx, y: dy, duration: lifetime * 0.45)
            burst.timingMode = .easeOut
            let gravity = SKAction.moveBy(x: dx * 0.05, y: -gravityStrength, duration: lifetime * 0.55)
            gravity.timingMode = .easeIn
            let rotate = SKAction.rotate(byAngle: CGFloat.random(in: -5...5), duration: lifetime)
            let fade = SKAction.fadeOut(withDuration: lifetime * 0.85)

            splinter.run(.group([
                .sequence([burst, gravity]),
                rotate, fade,
                .sequence([.wait(forDuration: lifetime), .removeFromParent()])
            ]))
        }
    }

    /// Warm tint overlay on the full scene for a brief flash
    private func spawnScreenTint(in scene: SKScene, color: SKColor, duration: TimeInterval) {
        let tint = SKSpriteNode(color: color, size: scene.size)
        tint.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        tint.zPosition = 490
        tint.blendMode = .add
        tint.alpha = 0
        scene.addChild(tint)

        tint.run(.sequence([
            .fadeIn(withDuration: duration * 0.3),
            .fadeOut(withDuration: duration * 0.7),
            .removeFromParent()
        ]))
    }

    /// Shake the scene's camera/board by offsetting the boardNode temporarily
    func shakeScene(_ scene: SKScene, intensity: CGFloat, duration: TimeInterval) {
        // Find boardNode if available; fallback to scene camera
        let target: SKNode
        if let board = scene.childNode(withName: "//boardNode") ?? scene.children.first(where: { $0.children.count > 10 }) {
            target = board
        } else {
            target = scene
        }

        let originalPos = target.position
        var actions: [SKAction] = []
        let steps = max(4, Int(duration / 0.025))
        for _ in 0..<steps {
            let dx = CGFloat.random(in: -intensity...intensity)
            let dy = CGFloat.random(in: -intensity...intensity)
            actions.append(.moveBy(x: dx, y: dy, duration: duration / Double(steps)))
        }
        actions.append(.move(to: originalPos, duration: 0.02))
        target.run(.sequence(actions))
    }

    // MARK: - Tile Squash-Pop-Fade Animation

    /// Animate a tile sprite through squash → pop → shrink/fade based on tier.
    /// Calls completion when the tile has finished its animation.
    func animateTileExplosion(
        sprite: SKNode,
        tier: ExplosionTier,
        staggerDelay: TimeInterval,
        completion: @escaping () -> Void
    ) {
        let squash: TimeInterval
        let pop: TimeInterval
        let fade: TimeInterval

        switch tier {
        case .small:
            squash = ExplosionConfig.Small.squashDuration
            pop    = ExplosionConfig.Small.popDuration
            fade   = ExplosionConfig.Small.fadeDuration
        case .medium:
            squash = ExplosionConfig.Medium.squashDuration
            pop    = ExplosionConfig.Medium.popDuration
            fade   = ExplosionConfig.Medium.fadeDuration
        case .big:
            squash = ExplosionConfig.Big.squashDuration
            pop    = ExplosionConfig.Big.popDuration
            fade   = ExplosionConfig.Big.fadeDuration
        }

        sprite.run(.sequence([
            .wait(forDuration: staggerDelay),
            // Phase 1: Squash
            .group([
                .scaleX(to: 1.15, duration: squash),
                .scaleY(to: 0.85, duration: squash)
            ]),
            // Phase 2: Pop + brighten
            .group([
                .scale(to: 1.3, duration: pop),
                .fadeAlpha(to: 0.7, duration: pop)
            ]),
            // Phase 3: Shrink + fade
            .group([
                .scale(to: 0.0, duration: fade),
                .fadeOut(withDuration: fade)
            ]),
            .removeFromParent()
        ]), completion: completion)
    }

    // MARK: - Color Helpers

    func effectColor(for cause: ExplosionCause) -> SKColor {
        switch cause {
        case .normalClear:   return SKColor(red: 0.83, green: 0.65, blue: 0.45, alpha: 1.0) // warm wood
        case .chainResolve:  return SKColor(red: 1.0,  green: 0.84, blue: 0.0,  alpha: 1.0) // gold
        case .bomb:          return SKColor(red: 1.0,  green: 0.42, blue: 0.21, alpha: 1.0) // orange
        case .laser:         return SKColor(red: 0.3,  green: 0.65, blue: 1.0,  alpha: 1.0) // blue
        case .crossLaser:    return SKColor(red: 0.7,  green: 0.4,  blue: 1.0,  alpha: 1.0) // purple
        case .mine:          return SKColor(red: 1.0,  green: 0.27, blue: 0.27, alpha: 1.0) // red
        }
    }

    /// Convert a SpecialTileType to an ExplosionCause
    func cause(for specialType: SpecialTileType?) -> ExplosionCause {
        guard let special = specialType else { return .normalClear }
        switch special {
        case .bomb:       return .bomb
        case .laser:      return .laser
        case .crossLaser: return .crossLaser
        case .mine:       return .mine
        case .wildcard:   return .chainResolve  // wildcard treated as gold chain
        }
    }

    // MARK: - Private Helpers

    private func tintColor(_ color: SKColor, by amount: CGFloat) -> SKColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        let c = amount > 0 ? amount : 0
        let d = amount < 0 ? -amount : 0
        return SKColor(
            red:   min(1, r + c - d * r),
            green: min(1, g + c - d * g),
            blue:  min(1, b + c - d * b),
            alpha: a
        )
    }
}
