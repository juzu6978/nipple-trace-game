import SpriteKit
import UIKit

// MARK: - Delegate

protocol GameSceneDelegate: AnyObject {
    func sceneDidUpdateState(_ state: GameSceneState)
    func sceneDidEndGame(_ result: GameResult)
    func sceneDidRequestRewardAd()
}

// MARK: - Observable State (SwiftUI HUD 用)

struct GameSceneState {
    var timeLeft: Double    = 30
    var score: Int          = 0
    var lapProgress: Double = 0  // 0〜1
    var timerDanger: Bool   = false
    var showAdButton: Bool  = false
    var adUsed: Bool        = false
}

// MARK: - Particle

private struct Particle {
    var x, y: CGFloat
    var vx, vy: CGFloat
    var life: CGFloat
    let decay: CGFloat
    let baseSize: CGFloat
    let color: UIColor
    weak var node: SKShapeNode?
}

// MARK: - GameScene

final class GameScene: SKScene {

    weak var gameDelegate: GameSceneDelegate?

    // ─── Constants ───────────────────────────────────────
    private let NIPPLE_R:  CGFloat = 28
    private let AREOLA_R:  CGFloat = 72

    // ─── Config ──────────────────────────────────────────
    private(set) var config: DifficultyConfig = .normal
    private(set) var isDaily: Bool = false

    // ─── State ───────────────────────────────────────────
    private var gameActive     = false
    private var timeLeft       = 30.0
    private var lapCount       = 0
    private var lapAngleAccum  = 0.0   // resets to 0 on each touch lift; ±2π = 1 lap
    private var lastAngle: Double?
    private var consecutiveLaps = 0
    private var bonusCount     = 0
    private var penaltyCount   = 0
    private var penaltyCooldown = 0
    private var touching       = false
    private var trailPoints: [CGPoint] = []
    private var animFrame      = 0
    private var flashAlpha: CGFloat = 0
    private var flashColor     = UIColor.white
    private var particles: [Particle] = []
    private var bonusCharTimer = 0
    private var adUsed         = false
    private var lastUpdateTime: TimeInterval = 0
    private var nippleOffset   = CGPoint.zero  // EXTREME wobble

    // ─── Nodes ───────────────────────────────────────────
    private var bgNode:         SKSpriteNode!
    private var flashNode:      SKSpriteNode!
    private var timerRingBg:    SKShapeNode!
    private var timerRingFill:  SKShapeNode!
    private var areaNode:       SKShapeNode!
    private var nippleNode:     SKShapeNode!
    private var ngZoneNode:     SKShapeNode!
    private var lapLabelNode:   SKLabelNode!
    private var trailNode:      SKShapeNode!
    private var cursorNode:     SKShapeNode!
    private var particleRoot:   SKNode!
    private var bonusCharNode:  SKSpriteNode?

    // MARK: - Setup

    override func didMove(to view: SKView) {
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = UIColor(red: 0.06, green: 0.05, blue: 0.16, alpha: 1)
        buildNodes()
    }

    private func buildNodes() {
        // Flash overlay
        flashNode = SKSpriteNode(color: .clear, size: UIScreen.main.bounds.size * 3)
        flashNode.zPosition = 5
        addChild(flashNode)

        // Timer ring (background)
        timerRingBg = SKShapeNode(circleOfRadius: AREOLA_R + 55)
        timerRingBg.strokeColor = UIColor.white.withAlphaComponent(0.08)
        timerRingBg.lineWidth = 6
        timerRingBg.fillColor = .clear
        timerRingBg.zPosition = 1
        addChild(timerRingBg)

        // Timer ring (fill) – path updated every frame
        timerRingFill = SKShapeNode()
        timerRingFill.strokeColor = UIColor(red: 0.41, green: 0.94, blue: 0.68, alpha: 1)
        timerRingFill.lineWidth = 6
        timerRingFill.lineCap = .round
        timerRingFill.fillColor = .clear
        timerRingFill.zPosition = 2
        addChild(timerRingFill)

        // Areola
        areaNode = SKShapeNode(circleOfRadius: AREOLA_R)
        areaNode.fillColor = UIColor(red: 0.78, green: 0.52, blue: 0.35, alpha: 1)
        areaNode.strokeColor = UIColor(red: 0.24, green: 0.08, blue: 0.0, alpha: 0.6)
        areaNode.lineWidth = 3
        areaNode.zPosition = 3
        addChild(areaNode)

        // Nipple
        nippleNode = SKShapeNode(circleOfRadius: NIPPLE_R)
        nippleNode.fillColor = UIColor(red: 0.80, green: 0.38, blue: 0.25, alpha: 1)
        nippleNode.strokeColor = .clear
        nippleNode.zPosition = 4
        addChild(nippleNode)

        // NG zone dashed ring
        ngZoneNode = SKShapeNode()
        ngZoneNode.strokeColor = UIColor(red: 1, green: 0.24, blue: 0.24, alpha: 0.6)
        ngZoneNode.lineWidth = 2
        ngZoneNode.fillColor = .clear
        ngZoneNode.zPosition = 4
        ngZoneNode.path = makeDashedCirclePath(radius: 40)
        addChild(ngZoneNode)

        // Lap ghost label (center)
        lapLabelNode = SKLabelNode(fontNamed: "-apple-system")
        lapLabelNode.fontSize = AREOLA_R
        lapLabelNode.fontColor = UIColor.white.withAlphaComponent(0.06)
        lapLabelNode.verticalAlignmentMode = .center
        lapLabelNode.zPosition = 3
        addChild(lapLabelNode)

        // Trail
        trailNode = SKShapeNode()
        trailNode.strokeColor = UIColor(red: 0.47, green: 0.78, blue: 1, alpha: 0.75)
        trailNode.lineWidth = 4
        trailNode.lineCap = .round
        trailNode.lineJoin = .round
        trailNode.fillColor = .clear
        trailNode.zPosition = 6
        addChild(trailNode)

        // Cursor dot
        cursorNode = SKShapeNode(circleOfRadius: 9)
        cursorNode.fillColor = UIColor(red: 0.47, green: 0.78, blue: 1, alpha: 0.9)
        cursorNode.strokeColor = .clear
        cursorNode.zPosition = 7
        cursorNode.isHidden = true
        addChild(cursorNode)

        // Particle root
        particleRoot = SKNode()
        particleRoot.zPosition = 8
        addChild(particleRoot)
    }

    // MARK: - Start / Reset

    func startGame(config: DifficultyConfig, isDaily: Bool) {
        self.config  = config
        self.isDaily = isDaily

        gameActive      = true
        timeLeft        = config.time
        lapCount        = 0
        lapAngleAccum   = 0
        lastAngle       = nil
        touching        = false
        trailPoints     = []
        animFrame       = 0
        flashAlpha      = 0
        consecutiveLaps = 0
        bonusCount      = 0
        penaltyCount    = 0
        penaltyCooldown = 0
        bonusCharTimer  = 0
        adUsed          = false
        nippleOffset    = .zero
        particles.removeAll()
        particleRoot.removeAllChildren()
        bonusCharNode?.removeFromParent()
        bonusCharNode = nil
        trailNode.path = nil
        cursorNode.isHidden = true
        lapLabelNode.text = "0"

        ngZoneNode.path = makeDashedCirclePath(radius: config.trackMin)

        updateTimerRingColor()
        notifyState()
        SoundManager.shared.playStart()
        HapticsManager.shared.playTap()
    }

    // MARK: - Pause / Resume / Cancel

    func pauseGame() {
        guard gameActive else { return }
        self.isPaused = true
    }

    func resumeGame() {
        self.isPaused = false
        lastUpdateTime = 0  // Avoid dt spike after pause
    }

    func cancelGame() {
        gameActive = false
        self.isPaused = false
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard gameActive, let touch = touches.first else { return }
        touching = true
        processTouch(touch.location(in: self))
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard gameActive, touching, let touch = touches.first else { return }
        processTouch(touch.location(in: self))
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        touching = false
        if gameActive { resetCurrentLap() }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }

    // MARK: - Game Logic

    private func processTouch(_ pos: CGPoint) {
        let nippleCenter = nippleOffset
        let dx = pos.x - nippleCenter.x
        let dy = pos.y - nippleCenter.y
        let dist = sqrt(dx * dx + dy * dy)

        if dist <= config.trackMin {
            if penaltyCooldown <= 0 {
                timeLeft = max(0, timeLeft - config.penalty)
                flashColor = UIColor(red: 1, green: 0.27, blue: 0.27, alpha: 1)
                flashAlpha = 1.0
                penaltyCooldown = 40
                consecutiveLaps = 0
                penaltyCount += 1
                SoundManager.shared.playPenalty()
                HapticsManager.shared.playPenalty()
                GameSceneEvents.shared.send(.penalty(seconds: config.penalty))
                resetCurrentLap()
            }
            return
        }

        // Limit trail length for performance
        trailPoints.append(pos)
        if trailPoints.count > 20 { trailPoints.removeFirst() }

        // Angle tracking
        let angle = atan2(Double(dy), Double(dx))
        if let last = lastAngle {
            var delta = angle - last
            if delta >  Double.pi { delta -= 2 * Double.pi }
            if delta < -Double.pi { delta += 2 * Double.pi }
            lapAngleAccum += delta

            // Lap detection: ±2π = 1 full lap (direction-independent)
            if abs(lapAngleAccum) >= 2 * Double.pi {
                lapCount += 1
                let sign = lapAngleAccum > 0 ? 1.0 : -1.0
                lapAngleAccum -= sign * 2 * Double.pi
                consecutiveLaps += 1

                // Time recovery
                if config.lapTimeBonus > 0 {
                    timeLeft = min(config.time, timeLeft + config.lapTimeBonus)
                    GameSceneEvents.shared.send(.timeRecovery(seconds: config.lapTimeBonus))
                }

                // Combo bonus
                if consecutiveLaps % config.comboBon == 0 {
                    let bonusAdd = config.bonusMult
                    bonusCount += bonusAdd
                    SoundManager.shared.playBonus()
                    HapticsManager.shared.playBonus()
                    GameSceneEvents.shared.send(.bonus(amount: bonusAdd))
                    startBonusChar()
                }

                GameSceneEvents.shared.send(.lap(combo: consecutiveLaps))
                SoundManager.shared.playLap()
                HapticsManager.shared.playLap()
                flashColor = UIColor(red: 0, green: 0.9, blue: 0.42, alpha: 1)
                flashAlpha = 0.7
                spawnParticles(at: .zero, count: 6)
                lapLabelNode.text = "\(lapCount)"
                trailPoints = []
            }
        }
        lastAngle = angle

        notifyState()
    }

    private func resetCurrentLap() {
        lapAngleAccum = 0   // Always reset to 0, direction-independent
        lastAngle  = nil
        trailPoints = []
        trailNode.path = nil
        cursorNode.isHidden = true
        notifyState()
    }

    // MARK: - Update Loop

    override func update(_ currentTime: TimeInterval) {
        guard gameActive else { return }
        let dt = lastUpdateTime == 0 ? 0 : currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        animFrame += 1

        if penaltyCooldown > 0 { penaltyCooldown -= 1 }
        timeLeft = max(0, timeLeft - dt)

        // Flash fade
        if flashAlpha > 0 {
            flashAlpha = max(0, flashAlpha - 0.05)
            flashNode.color = flashColor
            flashNode.colorBlendFactor = 0
            flashNode.alpha = flashAlpha * 0.35
        } else {
            flashNode.alpha = 0
        }

        // EXTREME: nipple wobble
        if config.id == "extreme" {
            let t = Double(animFrame)
            nippleOffset = CGPoint(x: CGFloat(sin(t * 0.07) * 3), y: CGFloat(cos(t * 0.05) * 3))
            nippleNode.position = nippleOffset
        }

        // Nipple pulse
        let pulse = CGFloat(sin(Double(animFrame) * 0.06) * 2)
        let s = (NIPPLE_R + pulse) / NIPPLE_R
        nippleNode.setScale(s)

        // 毎フレーム必須の更新のみ
        updateTrail()
        updateParticles()
        updateBonusChar()

        // タイマーリングは2フレームに1回（視覚的に差は出ない）
        if animFrame % 2 == 0 {
            updateTimerRing()
        }

        // SwiftUI HUD 更新は4フレームに1回（60fps→15Hz、十分滑らか）
        if animFrame % 4 == 0 {
            notifyState()
        }

        if timeLeft <= 0 {
            endGame()
        }
    }

    // MARK: - Timer Ring

    private func updateTimerRing() {
        let pct    = CGFloat(timeLeft / config.time)
        let r      = AREOLA_R + 55
        let start  = CGFloat.pi / 2
        let end    = start - pct * 2 * CGFloat.pi
        let path   = CGMutablePath()
        path.addArc(center: .zero, radius: r, startAngle: start, endAngle: end, clockwise: true)
        timerRingFill.path = path
        updateTimerRingColor()
    }

    private func updateTimerRingColor() {
        let pct = timeLeft / config.time
        let hue: CGFloat = pct > 0.3 ? 140/360 : pct > 0.15 ? 40/360 : 0
        timerRingFill.strokeColor = UIColor(hue: hue, saturation: 1, brightness: 0.85, alpha: 1)
    }

    // MARK: - Trail

    private func updateTrail() {
        guard trailPoints.count >= 2, touching else {
            if !touching { cursorNode.isHidden = true }
            return
        }
        let path = CGMutablePath()
        path.move(to: trailPoints[0])
        for pt in trailPoints.dropFirst() { path.addLine(to: pt) }
        trailNode.path = path

        if let last = trailPoints.last {
            cursorNode.position = last
            cursorNode.isHidden = false
        }
    }

    // MARK: - Particles

    private func spawnParticles(at center: CGPoint, count: Int, big: Bool = false) {
        for _ in 0..<count {
            let angle  = CGFloat.random(in: 0..<2*CGFloat.pi)
            let speed  = CGFloat.random(in: 2..<7) * (big ? 1.5 : 1.0)
            let size   = CGFloat.random(in: 3..<(big ? 10 : 6))
            let node   = SKShapeNode(circleOfRadius: size)
            let hue    = CGFloat.random(in: 0..<1)
            node.fillColor = UIColor(hue: hue, saturation: 1, brightness: 0.9, alpha: 1)
            node.strokeColor = .clear
            node.position = center
            node.zPosition = 8
            particleRoot.addChild(node)
            particles.append(Particle(
                x: center.x, y: center.y,
                vx: cos(angle) * speed, vy: sin(angle) * speed,
                life: 1.0,
                decay: CGFloat.random(in: 0.02..<0.04),
                baseSize: size,
                color: node.fillColor,
                node: node
            ))
        }
    }

    private func updateParticles() {
        for i in (0..<particles.count).reversed() {
            particles[i].x  += particles[i].vx
            particles[i].y  += particles[i].vy
            particles[i].vy -= 0.18  // gravity
            particles[i].life -= particles[i].decay
            if particles[i].life <= 0 {
                particles[i].node?.removeFromParent()
                particles.remove(at: i)
            } else {
                let p = particles[i]
                p.node?.position = CGPoint(x: p.x, y: p.y)
                p.node?.alpha    = p.life
                p.node?.setScale(p.life)
            }
        }
    }

    // MARK: - Bonus Character

    private func startBonusChar() {
        bonusCharTimer = 130
        bonusCharNode?.removeFromParent()
        bonusCharNode = makeBonusCharNode()
        if let cn = bonusCharNode {
            let xPos = min(130, (size.width / 2) - 50)
            cn.position = CGPoint(x: xPos, y: 0)
            cn.zPosition = 10
            addChild(cn)
        }
        spawnParticles(at: .zero, count: 10, big: true)
    }

    private func updateBonusChar() {
        guard bonusCharTimer > 0, let cn = bonusCharNode else { return }
        bonusCharTimer -= 1
        let elapsed = 130 - bonusCharTimer
        let t = bonusCharTimer

        var scale: CGFloat = 1
        var alpha: CGFloat = 1
        if elapsed < 18 {
            let p = CGFloat(elapsed) / 18
            scale = p < 0.65 ? (p / 0.65) * 1.3 : 1.3 - ((p - 0.65) / 0.35) * 0.3
        } else if t < 22 {
            alpha = CGFloat(t) / 22
            scale = alpha
        }
        let bob = CGFloat(sin(Double(elapsed) * 0.18)) * 5
        cn.alpha = alpha
        cn.setScale(scale)
        cn.position = CGPoint(x: cn.position.x, y: bob)

        if bonusCharTimer <= 0 {
            cn.removeFromParent()
            bonusCharNode = nil
        }
    }

    private func makeBonusCharNode() -> SKSpriteNode? {
        let imgSize = CGSize(width: 110, height: 160)
        let renderer = UIGraphicsImageRenderer(size: imgSize)
        let image = renderer.image { _ in
            drawKawaiiChar(in: imgSize)
        }
        let texture = SKTexture(image: image)
        return SKSpriteNode(texture: texture, size: imgSize)
    }

    private func drawKawaiiChar(in size: CGSize) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        let cx = size.width / 2
        let cy = size.height * 0.52
        let HR: CGFloat = 26

        // 吹き出し
        let bubbleRect = CGRect(x: cx - 52, y: cy - HR - 52, width: 104, height: 34)
        UIColor(red: 1, green: 0.99, blue: 0.88, alpha: 1).setFill()
        UIBezierPath(roundedRect: bubbleRect, cornerRadius: 8).fill()
        UIColor(red: 1, green: 0.84, blue: 0.25, alpha: 1).setStroke()
        let bubblePath = UIBezierPath(roundedRect: bubbleRect, cornerRadius: 8)
        bubblePath.lineWidth = 2; bubblePath.stroke()
        let tri = UIBezierPath()
        tri.move(to: CGPoint(x: cx - 7, y: cy - HR - 18))
        tri.addLine(to: CGPoint(x: cx + 7, y: cy - HR - 18))
        tri.addLine(to: CGPoint(x: cx, y: cy - HR - 7))
        tri.close()
        UIColor(red: 1, green: 0.99, blue: 0.88, alpha: 1).setFill(); tri.fill()
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 11),
            .foregroundColor: UIColor(red: 0.90, green: 0.32, blue: 0, alpha: 1)
        ]
        "🔥 BONUS!".draw(at: CGPoint(x: cx - 30, y: cy - HR - 49), withAttributes: attrs)

        // 猫耳
        func ear(flip: CGFloat) {
            let earPink = UIColor(red: 1, green: 0.70, blue: 0.78, alpha: 1)
            let earDark = UIColor(red: 1, green: 0.42, blue: 0.54, alpha: 1)
            let p = UIBezierPath()
            p.move(to: CGPoint(x: cx + flip * (HR - 3), y: cy - HR + 6))
            p.addLine(to: CGPoint(x: cx + flip * (HR + 10), y: cy - HR - 22))
            p.addLine(to: CGPoint(x: cx + flip * (HR - 16), y: cy - HR - 6))
            p.close(); earPink.setFill(); p.fill()
            let p2 = UIBezierPath()
            p2.move(to: CGPoint(x: cx + flip * (HR - 5), y: cy - HR + 2))
            p2.addLine(to: CGPoint(x: cx + flip * (HR + 4), y: cy - HR - 14))
            p2.addLine(to: CGPoint(x: cx + flip * (HR - 11), y: cy - HR - 3))
            p2.close(); earDark.setFill(); p2.fill()
        }
        ear(flip: -1); ear(flip: 1)

        // 顔
        let faceColor = UIColor(red: 1, green: 0.84, blue: 0.78, alpha: 1)
        faceColor.setFill()
        UIBezierPath(ovalIn: CGRect(x: cx - HR, y: cy - HR, width: HR * 2, height: HR * 2)).fill()

        // 髪
        ctx.setFillColor(UIColor(red: 0.24, green: 0.12, blue: 0, alpha: 1).cgColor)
        ctx.addArc(center: CGPoint(x: cx, y: cy - HR * 0.15), radius: HR * 1.04,
                   startAngle: .pi * 1.08, endAngle: .pi * 1.92, clockwise: false)
        ctx.fillPath()

        // 目（星形）
        func starEye(ex: CGFloat, ey: CGFloat, r: CGFloat) {
            UIColor.white.setFill()
            UIBezierPath(ovalIn: CGRect(x: ex - r, y: ey - r * 1.15, width: r * 2, height: r * 2.3)).fill()
            UIColor(red: 0.20, green: 0.31, blue: 0.80, alpha: 1).setFill()
            let star = UIBezierPath()
            for i in 0..<10 {
                let rad: CGFloat = i % 2 == 0 ? r * 0.72 : r * 0.36
                let a = CGFloat(i) / 10 * .pi * 2 - .pi / 2
                let pt = CGPoint(x: ex + cos(a) * rad, y: ey + sin(a) * rad)
                i == 0 ? star.move(to: pt) : star.addLine(to: pt)
            }
            star.close(); star.fill()
            UIColor.white.setFill()
            UIBezierPath(ovalIn: CGRect(x: ex - r * 0.56, y: ey - r * 0.56, width: r * 0.56, height: r * 0.56)).fill()
        }
        starEye(ex: cx - 10, ey: cy + 1, r: 7)
        starEye(ex: cx + 10, ey: cy + 1, r: 7)

        // ほっぺ
        UIColor(red: 1, green: 0.44, blue: 0.59, alpha: 0.45).setFill()
        UIBezierPath(ovalIn: CGRect(x: cx - 24, y: cy + 5, width: 16, height: 10)).fill()
        UIBezierPath(ovalIn: CGRect(x: cx + 8,  y: cy + 5, width: 16, height: 10)).fill()

        // 口
        UIColor(red: 0.75, green: 0.25, blue: 0.31, alpha: 1).setStroke()
        let mouth = UIBezierPath(arcCenter: CGPoint(x: cx, y: cy + 13), radius: 9,
                                 startAngle: 0.15, endAngle: .pi - 0.15, clockwise: true)
        mouth.lineWidth = 2; mouth.lineCapStyle = .round; mouth.stroke()

        // 体
        UIColor(red: 1, green: 0.49, blue: 0.70, alpha: 1).setFill()
        UIBezierPath(roundedRect: CGRect(x: cx - 15, y: cy + HR - 2, width: 30, height: 26),
                     cornerRadius: 6).fill()
    }

    // MARK: - End Game

    private func endGame() {
        guard gameActive else { return }
        gameActive = false
        spawnParticles(at: .zero, count: 15, big: true)
        SoundManager.shared.playGameOver()

        let save = SaveData.shared
        let cfg  = config
        let xpPerLap   = Int(10 * cfg.xpMult)
        let xpPerBonus = Int(25 * cfg.xpMult)
        var xp = lapCount * xpPerLap + bonusCount * xpPerBonus
        if (lapCount + bonusCount) >= 3 { xp += Int(20 * cfg.xpMult) }

        save.totalGames     += 1
        save.totalLaps      += lapCount
        save.totalPenalties += penaltyCount
        save.totalXP        += xp
        save.updateBestScore(difficultyID: cfg.id, score: lapCount + bonusCount)
        save.updateStreak()
        if isDaily && lapCount >= 1 { save.dailyCompletedDate = save.todayString() }

        let unlocked = AchievementList.checkAndUnlock(
            laps: lapCount, bonus: bonusCount, penalties: penaltyCount,
            diffID: cfg.id, isDaily: isDaily, save: save
        )
        if !unlocked.isEmpty {
            SoundManager.shared.playAchievement()
            HapticsManager.shared.playAchievement()
        }

        let result = GameResult(
            laps: lapCount, bonus: bonusCount, penalties: penaltyCount,
            difficultyID: cfg.id, difficultyLabel: cfg.label,
            isDaily: isDaily, xpEarned: xp, unlockedAchievements: unlocked
        )

        nativeSend_gameCenter(score: lapCount + bonusCount, difficulty: cfg.id)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            self?.gameDelegate?.sceneDidEndGame(result)
        }
    }

    // MARK: - Ad Reward (called from ResultView after game ends)

    func handleAdReward() {
        // No-op during gameplay; kept for protocol compatibility
    }

    // MARK: - Notify State

    private func notifyState() {
        let progress = min(abs(lapAngleAccum) / (2 * Double.pi), 1)
        let state = GameSceneState(
            timeLeft:     timeLeft,
            score:        lapCount + bonusCount,
            lapProgress:  progress,
            timerDanger:  timeLeft <= 5,
            showAdButton: false,   // 広告はゲーム終了後のみ
            adUsed:       adUsed
        )
        DispatchQueue.main.async { [weak self] in
            self?.gameDelegate?.sceneDidUpdateState(state)
        }
    }

    // MARK: - Helpers

    private func makeDashedCirclePath(radius: CGFloat) -> CGPath {
        let path = CGMutablePath()
        let total: CGFloat = 2 * .pi
        let dashArc: CGFloat = 0.15
        let gapArc:  CGFloat = 0.20
        var a: CGFloat = 0
        while a < total {
            let end = min(a + dashArc, total)
            path.addArc(center: .zero, radius: radius, startAngle: a, endAngle: end, clockwise: false)
            a += dashArc + gapArc
        }
        return path
    }

    private func nativeSend_gameCenter(score: Int, difficulty: String) {
        GameCenterManager.shared.submitScore(score, difficulty: difficulty)
    }
}

// MARK: - CGSize helper

private extension CGSize {
    static func * (lhs: CGSize, rhs: CGFloat) -> CGSize {
        CGSize(width: lhs.width * rhs, height: lhs.height * rhs)
    }
}

// MARK: - Event Bus (Scene → SwiftUI overlay)

enum GameEvent {
    case lap(combo: Int)
    case bonus(amount: Int)
    case penalty(seconds: Double)
    case timeRecovery(seconds: Double)
}

final class GameSceneEvents: ObservableObject {
    static let shared = GameSceneEvents()
    private init() {}
    var onEvent: ((GameEvent) -> Void)?
    func send(_ event: GameEvent) {
        DispatchQueue.main.async { self.onEvent?(event) }
    }
}
