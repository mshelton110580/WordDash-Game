import SpriteKit

// MARK: - RewardFeedbackManager
//
// Handles score/coin reward visuals for all 3 explosion tiers:
//   • SMALL  — floating "+points" text, instant counter update
//   • MEDIUM — pop-scaled text, smooth count-up over ~0.4s
//   • BIG    — large glowing text + fragment burst that flies to HUD, synced count-up
//
// Usage:
//   RewardFeedbackManager.shared.showRewards(
//       origin: pos, tier: .big, points: 2000, coins: 6,
//       hudTargets: hudTargets, scoreLabel: scoreLabel, coinLabel: coinLabel,
//       in: effectsLayer
//   )

final class RewardFeedbackManager {

    static let shared = RewardFeedbackManager()
    private init() {}

    // MARK: - Public API

    /// Show score/coin reward visuals and animate HUD counters.
    /// - Parameters:
    ///   - origin: Spawn point in `parent`'s coordinate space
    ///   - tier: Determines visual intensity
    ///   - points: Points awarded this clear (used for display + counter)
    ///   - coins: Coins awarded (0 = no coin visuals)
    ///   - hudTargets: Positions of score and coin labels in scene coords
    ///   - scoreLabel: The actual SKLabelNode showing total score
    ///   - coinLabel: The actual SKLabelNode showing coin balance
    ///   - currentScore: Score BEFORE this award (counter counts up to currentScore + points)
    ///   - currentCoins: Coin balance BEFORE this award
    ///   - parent: Node to attach popup nodes to
    func showRewards(
        origin: CGPoint,
        tier: ExplosionTier,
        points: Int,
        coins: Int,
        hudTargets: HUDTargets,
        scoreLabel: SKLabelNode,
        coinLabel: SKLabelNode?,
        currentScore: Int,
        currentCoins: Int,
        in parent: SKNode
    ) {
        switch tier {
        case .small:
            showSmallRewards(
                origin: origin, points: points, coins: coins,
                scoreLabel: scoreLabel, coinLabel: coinLabel,
                currentScore: currentScore, currentCoins: currentCoins,
                parent: parent
            )
        case .medium:
            showMediumRewards(
                origin: origin, points: points, coins: coins,
                hudTargets: hudTargets, scoreLabel: scoreLabel, coinLabel: coinLabel,
                currentScore: currentScore, currentCoins: currentCoins,
                parent: parent
            )
        case .big:
            showBigRewards(
                origin: origin, points: points, coins: coins,
                hudTargets: hudTargets, scoreLabel: scoreLabel, coinLabel: coinLabel,
                currentScore: currentScore, currentCoins: currentCoins,
                parent: parent
            )
        }
    }

    // MARK: - Small Tier

    private func showSmallRewards(
        origin: CGPoint, points: Int, coins: Int,
        scoreLabel: SKLabelNode, coinLabel: SKLabelNode?,
        currentScore: Int, currentCoins: Int,
        parent: SKNode
    ) {
        let cfg = ExplosionConfig.Small.self

        // Floating "+points"
        let popup = makePopupLabel(text: "+\(points)", fontSize: cfg.popupFontSize, color: .yellow)
        popup.position = CGPoint(x: origin.x, y: origin.y + 20)
        parent.addChild(popup)

        let drift = SKAction.moveBy(x: CGFloat.random(in: -8...8), y: 55, duration: cfg.popupDriftDuration)
        drift.timingMode = .easeOut
        popup.run(.sequence([
            .group([drift, .fadeOut(withDuration: cfg.popupDriftDuration)]),
            .removeFromParent()
        ]))

        // Tiny coin text if coins > 0
        if coins > 0 {
            let coinPopup = makePopupLabel(
                text: "+\(coins)🪙", fontSize: cfg.popupFontSize - 4,
                color: SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)
            )
            coinPopup.position = CGPoint(x: origin.x, y: origin.y)
            parent.addChild(coinPopup)
            coinPopup.run(.sequence([
                .group([
                    .moveBy(x: 0, y: 40, duration: cfg.popupDriftDuration),
                    .fadeOut(withDuration: cfg.popupDriftDuration)
                ]),
                .removeFromParent()
            ]))
        }

        // Quick counter increment
        animateCounter(
            label: scoreLabel,
            from: currentScore, to: currentScore + points,
            duration: cfg.scoreCountDuration,
            formatter: { "Score: \($0)" }
        )

        if coins > 0, let coinLabel = coinLabel {
            animateCounter(
                label: coinLabel,
                from: currentCoins, to: currentCoins + coins,
                duration: cfg.scoreCountDuration,
                formatter: { "🪙 \($0)" }
            )
        }
    }

    // MARK: - Medium Tier

    private func showMediumRewards(
        origin: CGPoint, points: Int, coins: Int,
        hudTargets: HUDTargets, scoreLabel: SKLabelNode, coinLabel: SKLabelNode?,
        currentScore: Int, currentCoins: Int,
        parent: SKNode
    ) {
        let cfg = ExplosionConfig.Medium.self

        // Pop-scaled points label
        let popup = makePopupLabel(text: "+\(points)", fontSize: cfg.popupFontSize, color: .yellow)
        popup.position = CGPoint(x: origin.x, y: origin.y + 24)
        popup.setScale(0.5)
        parent.addChild(popup)

        popup.run(.sequence([
            .group([
                .scale(to: 1.1, duration: 0.10),
                .fadeIn(withDuration: 0.10)
            ]),
            .scale(to: 1.0, duration: 0.05),
            .wait(forDuration: 0.25),
            .group([
                .moveBy(x: 0, y: 50, duration: 0.35),
                .fadeOut(withDuration: 0.35)
            ]),
            .removeFromParent()
        ]))

        if coins > 0 {
            let coinPopup = makePopupLabel(
                text: "+\(coins)🪙", fontSize: cfg.popupFontSize - 6,
                color: SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)
            )
            coinPopup.position = CGPoint(x: origin.x, y: origin.y + 6)
            coinPopup.setScale(0.7)
            parent.addChild(coinPopup)
            coinPopup.run(.sequence([
                .scale(to: 1.0, duration: 0.08),
                .wait(forDuration: 0.25),
                .group([
                    .moveBy(x: 0, y: 35, duration: 0.3),
                    .fadeOut(withDuration: 0.3)
                ]),
                .removeFromParent()
            ]))
        }

        // Smooth count-up
        animateCounter(
            label: scoreLabel,
            from: currentScore, to: currentScore + points,
            duration: cfg.scoreCountDuration,
            formatter: { "Score: \($0)" }
        )

        if coins > 0, let coinLabel = coinLabel {
            animateCounter(
                label: coinLabel,
                from: currentCoins, to: currentCoins + coins,
                duration: cfg.scoreCountDuration,
                formatter: { "🪙 \($0)" }
            )
        }

        // Light HUD pulse
        pulseLabel(scoreLabel, scale: 1.15)
    }

    // MARK: - Big Tier

    private func showBigRewards(
        origin: CGPoint, points: Int, coins: Int,
        hudTargets: HUDTargets, scoreLabel: SKLabelNode, coinLabel: SKLabelNode?,
        currentScore: Int, currentCoins: Int,
        parent: SKNode
    ) {
        let cfg = ExplosionConfig.Big.self

        // Large glowing "+POINTS" — appears at explosion peak
        let popup = makePopupLabel(
            text: "+\(points)", fontSize: cfg.popupFontSize,
            color: SKColor(red: 1.0, green: 0.95, blue: 0.4, alpha: 1.0)
        )
        popup.position = CGPoint(x: origin.x, y: origin.y + 30)
        popup.setScale(0.1)
        popup.alpha = 0
        // Glow via shadow (SpriteKit workaround)
        popup.fontColor = SKColor(red: 1.0, green: 0.95, blue: 0.4, alpha: 1.0)
        parent.addChild(popup)

        popup.run(.sequence([
            .wait(forDuration: cfg.popupAppearDelay),
            .group([
                .scale(to: 1.15, duration: 0.10),
                .fadeIn(withDuration: 0.08)
            ]),
            .scale(to: 1.0, duration: 0.06),
            .wait(forDuration: 0.20),
            .group([
                .moveBy(x: 0, y: 65, duration: 0.5),
                .sequence([
                    .wait(forDuration: 0.2),
                    .fadeOut(withDuration: 0.3)
                ])
            ]),
            .removeFromParent()
        ]))

        if coins > 0 {
            let coinPopup = makePopupLabel(
                text: "+\(coins)🪙", fontSize: cfg.popupFontSize - 10,
                color: SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)
            )
            coinPopup.position = CGPoint(x: origin.x, y: origin.y + 8)
            coinPopup.setScale(0.3)
            coinPopup.alpha = 0
            parent.addChild(coinPopup)
            coinPopup.run(.sequence([
                .wait(forDuration: cfg.popupAppearDelay + 0.05),
                .group([.scale(to: 1.0, duration: 0.10), .fadeIn(withDuration: 0.10)]),
                .wait(forDuration: 0.22),
                .group([
                    .moveBy(x: 0, y: 45, duration: 0.4),
                    .sequence([.wait(forDuration: 0.15), .fadeOut(withDuration: 0.25)])
                ]),
                .removeFromParent()
            ]))
        }

        // Fragment burst → fly to HUD (score fragments)
        let scene = parent.scene ?? (parent as? SKScene)
        let pointFragCount = min(
            Int.random(in: cfg.pointFragmentCountMin...cfg.pointFragmentCountMax),
            ExplosionConfig.maxActiveFragments / (coins > 0 ? 2 : 1)
        )
        let scoreTargetInScene = hudTargets.scoreLabelPosition

        spawnFlyingFragments(
            count: pointFragCount,
            from: origin,
            toScenePos: scoreTargetInScene,
            color: SKColor(red: 1.0, green: 0.92, blue: 0.3, alpha: 1.0),
            parent: parent,
            burstDuration: cfg.fragmentBurstDuration,
            flyDuration: TimeInterval.random(in: cfg.fragmentFlyMinDuration...cfg.fragmentFlyMaxDuration)
        ) { [weak scoreLabel, weak coinLabel] in
            // On last fragment arrival: pulse HUD + finalize counter
            guard let scoreLabel = scoreLabel else { return }
            scoreLabel.text = "Score: \(currentScore + points)"
            RewardFeedbackManager.shared.pulseLabel(scoreLabel, scale: 1.22)
        }

        // Coin fragments if awarded
        if coins > 0 {
            let coinFragCount = min(
                Int.random(in: cfg.coinFragmentCountMin...cfg.coinFragmentCountMax),
                ExplosionConfig.maxActiveFragments / 2
            )
            let coinTargetInScene = hudTargets.coinLabelPosition

            spawnFlyingFragments(
                count: coinFragCount,
                from: origin,
                toScenePos: coinTargetInScene,
                color: SKColor(red: 1.0, green: 0.78, blue: 0.0, alpha: 1.0),
                parent: parent,
                burstDuration: cfg.fragmentBurstDuration,
                flyDuration: TimeInterval.random(in: cfg.fragmentFlyMinDuration...cfg.fragmentFlyMaxDuration)
            ) { [weak coinLabel] in
                guard let coinLabel = coinLabel else { return }
                coinLabel.text = "🪙 \(currentCoins + coins)"
                RewardFeedbackManager.shared.pulseLabel(coinLabel, scale: 1.22)
            }
        }

        // Synchronized count-up (starts slightly after fragments begin flying)
        let countDelay = cfg.fragmentBurstDuration + 0.05
        let countDuration = cfg.scoreCountDuration

        DispatchQueue.main.asyncAfter(deadline: .now() + countDelay) { [weak scoreLabel, weak coinLabel] in
            guard let scoreLabel = scoreLabel else { return }
            RewardFeedbackManager.shared.animateCounter(
                label: scoreLabel,
                from: currentScore, to: currentScore + points,
                duration: countDuration,
                formatter: { "Score: \($0)" }
            )
            if coins > 0, let coinLabel = coinLabel {
                RewardFeedbackManager.shared.animateCounter(
                    label: coinLabel,
                    from: currentCoins, to: currentCoins + coins,
                    duration: countDuration,
                    formatter: { "🪙 \($0)" }
                )
            }
        }
    }

    // MARK: - Fragment Burst → Fly to HUD

    private func spawnFlyingFragments(
        count: Int,
        from origin: CGPoint,
        toScenePos target: CGPoint,
        color: SKColor,
        parent: SKNode,
        burstDuration: TimeInterval,
        flyDuration: TimeInterval,
        onLastArrival: @escaping () -> Void
    ) {
        // Convert target from scene to parent's coordinate space
        let targetInParent: CGPoint
        if let scene = parent.scene {
            targetInParent = scene.convert(target, to: parent)
        } else {
            targetInParent = target
        }

        for i in 0..<count {
            let isLast = (i == count - 1)
            let frag = makeFragment(color: color)
            frag.position = origin
            parent.addChild(frag)

            // Staggered launch
            let launchDelay = Double(i) * (burstDuration / Double(count))

            // Burst: scatter outward briefly
            let burstAngle = CGFloat.random(in: 0...(2 * .pi))
            let burstDist  = CGFloat.random(in: 20...55)
            let burstDx    = cos(burstAngle) * burstDist
            let burstDy    = sin(burstAngle) * burstDist
            let burstEnd   = CGPoint(x: origin.x + burstDx, y: origin.y + burstDy)

            // Curve fly to target using Bezier control point above midpoint
            let midX = (burstEnd.x + targetInParent.x) / 2
            let midY = max(burstEnd.y, targetInParent.y) + CGFloat.random(in: 30...80)
            let controlPoint = CGPoint(x: midX, y: midY)

            let flyPath = CGMutablePath()
            flyPath.move(to: burstEnd)
            flyPath.addQuadCurve(to: targetInParent, control: controlPoint)

            let burstMove = SKAction.move(to: burstEnd, duration: burstDuration * 0.5)
            burstMove.timingMode = .easeOut

            let flyFollow = SKAction.follow(flyPath, asOffset: false, orientToPath: false, duration: flyDuration)
            flyFollow.timingMode = .easeIn

            let scaleDown = SKAction.scale(to: 0.15, duration: flyDuration)
            let fadeOut   = SKAction.sequence([
                .wait(forDuration: flyDuration * 0.7),
                .fadeOut(withDuration: flyDuration * 0.3)
            ])

            let flyGroup = SKAction.group([flyFollow, scaleDown, fadeOut])

            frag.run(.sequence([
                .wait(forDuration: launchDelay),
                burstMove,
                flyGroup,
                .removeFromParent()
            ])) {
                if isLast { onLastArrival() }
            }
        }
    }

    // MARK: - Counter Animation

    /// Smoothly count a label from `from` to `to` over `duration` seconds.
    func animateCounter(
        label: SKLabelNode,
        from: Int,
        to: Int,
        duration: TimeInterval,
        formatter: @escaping (Int) -> String
    ) {
        guard from != to, duration > 0 else {
            label.text = formatter(to)
            return
        }

        let steps = max(10, min(60, Int(duration * 60)))
        let stepDuration = duration / Double(steps)
        let delta = to - from

        var actions: [SKAction] = []
        for step in 0...steps {
            let progress = Double(step) / Double(steps)
            // Ease-out curve for natural feel
            let eased = 1 - pow(1 - progress, 2)
            let value = from + Int(Double(delta) * eased)
            actions.append(.customAction(withDuration: 0) { [weak label] _, _ in
                label?.text = formatter(value)
            })
            if step < steps {
                actions.append(.wait(forDuration: stepDuration))
            }
        }
        // Always land exactly on final value
        actions.append(.customAction(withDuration: 0) { [weak label] _, _ in
            label?.text = formatter(to)
        })

        label.run(.sequence(actions), withKey: "counterAnimation")
    }

    // MARK: - Label Pulse

    func pulseLabel(_ label: SKLabelNode, scale: CGFloat = 1.2) {
        label.run(.sequence([
            .scale(to: scale, duration: 0.10),
            .scale(to: 1.0,   duration: 0.10)
        ]))
    }

    // MARK: - Node Factories

    private func makePopupLabel(text: String, fontSize: CGFloat, color: SKColor) -> SKLabelNode {
        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = text
        label.fontSize = fontSize
        label.fontColor = color
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.zPosition = 210
        return label
    }

    private func makeFragment(color: SKColor) -> SKShapeNode {
        // Small glowing circle chip
        let radius = CGFloat.random(in: 3...6)
        let frag = SKShapeNode(circleOfRadius: radius)
        frag.fillColor = color
        frag.strokeColor = SKColor.white.withAlphaComponent(0.5)
        frag.lineWidth = 0.8
        frag.blendMode = .add
        frag.zPosition = 205
        frag.alpha = 0.92
        return frag
    }
}

// MARK: - Combined Convenience API

extension RewardFeedbackManager {

    /// One-shot call that plays explosion VFX AND reward feedback.
    /// - Parameters match both managers; tier is auto-selected if nil.
    func playExplosionWithRewards(
        origin: CGPoint,
        points: Int,
        coins: Int,
        cause: ExplosionCause,
        streakMultiplier: Double = 1.0,
        tier: ExplosionTier? = nil,
        hudTargets: HUDTargets,
        scoreLabel: SKLabelNode,
        coinLabel: SKLabelNode?,
        currentScore: Int,
        currentCoins: Int,
        explosionParent: SKNode,
        rewardParent: SKNode,
        tileSize: CGFloat = 48
    ) {
        let resolvedTier = tier ?? ExplosionConfig.selectTier(
            points: points,
            coins: coins,
            cause: cause,
            streakMultiplier: streakMultiplier
        )

        ExplosionManager.shared.playExplosion(
            origin: origin,
            tier: resolvedTier,
            cause: cause,
            in: explosionParent,
            tileSize: tileSize
        )

        showRewards(
            origin: origin,
            tier: resolvedTier,
            points: points,
            coins: coins,
            hudTargets: hudTargets,
            scoreLabel: scoreLabel,
            coinLabel: coinLabel,
            currentScore: currentScore,
            currentCoins: currentCoins,
            in: rewardParent
        )
    }
}
