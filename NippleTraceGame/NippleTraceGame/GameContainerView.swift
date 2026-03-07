import SwiftUI
import SpriteKit

// MARK: - GameCoordinator

final class GameCoordinator: NSObject, ObservableObject, GameSceneDelegate {
    @Published var hudState = GameSceneState()

    let scene: GameScene
    var onGameEnd: ((GameResult) -> Void)?
    var onRequestAd: (() -> Void)?

    init(config: DifficultyConfig) {
        let size = UIScreen.main.bounds.size
        scene = GameScene(size: size)
        scene.scaleMode = .resizeFill
        super.init()
        scene.gameDelegate = self
    }

    func sceneDidUpdateState(_ state: GameSceneState) {
        hudState = state
    }

    func sceneDidEndGame(_ result: GameResult) {
        DispatchQueue.main.async { [weak self] in
            self?.onGameEnd?(result)
        }
    }

    func sceneDidRequestRewardAd() {
        DispatchQueue.main.async { [weak self] in
            self?.onRequestAd?()
        }
    }
}

// MARK: - GameContainerView

struct GameContainerView: View {
    let config: DifficultyConfig
    let isDaily: Bool
    var onComplete: (GameResult) -> Void
    var onMenu: () -> Void

    @StateObject private var coordinator: GameCoordinator
    @State private var countdown: Int = 3
    @State private var countdownActive = true
    @State private var popupText: String = ""
    @State private var popupColor: Color = .white
    @State private var popupVisible = false
    @State private var isPaused = false

    init(config: DifficultyConfig, isDaily: Bool,
         onComplete: @escaping (GameResult) -> Void,
         onMenu: @escaping () -> Void) {
        self.config = config
        self.isDaily = isDaily
        self.onComplete = onComplete
        self.onMenu = onMenu
        _coordinator = StateObject(wrappedValue: GameCoordinator(config: config))
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // SpriteKit scene (full screen)
                SpriteView(scene: coordinator.scene)
                    .ignoresSafeArea()

                // HUD — respects safe area via GeometryReader insets
                VStack(spacing: 0) {
                    hudTop
                        .padding(.horizontal, 20)
                        .padding(.top, geo.safeAreaInsets.top + 12)
                    Spacer()
                    hudBottom
                        .padding(.horizontal, 20)
                        .padding(.bottom, max(geo.safeAreaInsets.bottom, 20) + 10)
                }

                // Event popup
                if popupVisible {
                    Text(popupText)
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundColor(popupColor)
                        .shadow(color: popupColor.opacity(0.8), radius: 10)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.38))
                        .cornerRadius(20)
                        .offset(y: -90)
                        .transition(.opacity.combined(with: .scale))
                }

                // Countdown overlay
                if countdownActive {
                    countdownOverlay
                }

                // Pause overlay
                if isPaused {
                    pauseOverlay(safeTop: geo.safeAreaInsets.top)
                }
            }
        }
        .ignoresSafeArea()
        .onAppear(perform: setup)
        .onDisappear {
            GameSceneEvents.shared.onEvent = nil
        }
    }

    // MARK: - HUD Top

    private var hudTop: some View {
        HStack(alignment: .top) {
            // Timer
            VStack(alignment: .leading, spacing: 1) {
                Text(String(format: "%.1f", max(0, coordinator.hudState.timeLeft)))
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundColor(
                        coordinator.hudState.timerDanger
                            ? Color(red: 1, green: 0.3, blue: 0.3)
                            : .white
                    )
                Text("TIME")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.35))
                    .tracking(2)
            }

            Spacer()

            // Pause button (center-top)
            Button(action: {
                withAnimation(.easeInOut(duration: 0.18)) { isPaused = true }
                coordinator.scene.pauseGame()
            }) {
                Image(systemName: "pause.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.white.opacity(0.55))
            }

            Spacer()

            // Score
            VStack(alignment: .trailing, spacing: 1) {
                Text("\(coordinator.hudState.score)")
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundColor(Color(red: 0.41, green: 0.94, blue: 0.68))
                Text("SCORE")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.35))
                    .tracking(2)
                let best = SaveData.shared.bestScores[config.id] ?? 0
                if best > 0 {
                    Text("BEST \(best)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.28))
                }
            }
        }
    }

    // MARK: - HUD Bottom

    private var hudBottom: some View {
        VStack(spacing: 10) {
            // Lap progress bar
            VStack(spacing: 3) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.12))
                        Capsule()
                            .fill(LinearGradient(
                                colors: [Color(red: 0.47, green: 0.78, blue: 1),
                                         Color(red: 0.35, green: 0.45, blue: 1)],
                                startPoint: .leading, endPoint: .trailing
                            ))
                            .frame(width: max(0, geo.size.width * CGFloat(coordinator.hudState.lapProgress)))
                    }
                }
                .frame(height: 6)
                Text("1周の進捗")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.25))
            }

            // Difficulty chip
            Text(config.emoji + " " + config.label + (isDaily ? "  ⚡DAILY" : ""))
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(config.swiftUIColor.opacity(0.65))
        }
    }

    // MARK: - Pause Overlay

    private func pauseOverlay(safeTop: CGFloat) -> some View {
        ZStack {
            Color.black.opacity(0.68).ignoresSafeArea()

            VStack(spacing: 28) {
                Text("⏸ 一時停止")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundColor(.white)

                Button(action: {
                    coordinator.scene.resumeGame()
                    withAnimation(.easeInOut(duration: 0.18)) { isPaused = false }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                        Text("再開")
                    }
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundColor(.black)
                    .frame(width: 200, height: 54)
                    .background(LinearGradient(
                        colors: [Color(red: 0.41, green: 0.94, blue: 0.68),
                                 Color(red: 0, green: 0.85, blue: 0.9)],
                        startPoint: .leading, endPoint: .trailing
                    ))
                    .cornerRadius(14)
                }
                .buttonStyle(ScaleButtonStyle())

                Button(action: {
                    coordinator.scene.cancelGame()
                    onMenu()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "house.fill")
                        Text("ホームへ戻る")
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 200, height: 48)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(14)
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
    }

    // MARK: - Countdown Overlay

    private var countdownOverlay: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            VStack(spacing: 16) {
                if countdown > 0 {
                    Text("\(countdown)")
                        .font(.system(size: 100, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .id(countdown)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 1.5).combined(with: .opacity),
                            removal: .scale(scale: 0.5).combined(with: .opacity)
                        ))
                } else {
                    Text("GO!")
                        .font(.system(size: 80, weight: .black, design: .rounded))
                        .foregroundColor(Color(red: 0.41, green: 0.94, blue: 0.68))
                        .transition(.scale.combined(with: .opacity))
                }
                Text(countdown > 0 ? "準備して！" : "スタート！！")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.65), value: countdown)
    }

    // MARK: - Setup

    private func setup() {
        coordinator.onGameEnd = { result in
            onComplete(result)
        }
        coordinator.onRequestAd = {
            AdsManager.shared.showRewardAd {
                coordinator.scene.handleAdReward()
            }
        }
        GameSceneEvents.shared.onEvent = { event in
            showEventPopup(for: event)
        }
        startCountdown()
    }

    private func startCountdown() {
        countdown = 3
        countdownActive = true
        tickCountdown()
    }

    private func tickCountdown() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            withAnimation(.spring(response: 0.25)) {
                countdown -= 1
            }
            if countdown > 0 {
                tickCountdown()
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                    withAnimation { countdownActive = false }
                    coordinator.scene.startGame(config: config, isDaily: isDaily)
                }
            }
        }
    }

    private func showEventPopup(for event: GameEvent) {
        switch event {
        case .lap(let combo):
            popupText  = combo > 1 ? "🌀 \(combo)コンボ！" : "🌀 ラップ！"
            popupColor = Color(red: 0.47, green: 0.78, blue: 1)
        case .bonus(let amount):
            popupText  = "🔥 ボーナス +\(amount)！"
            popupColor = Color(red: 1, green: 0.84, blue: 0.25)
        case .penalty(let sec):
            popupText  = "💥 -\(Int(sec))秒"
            popupColor = Color(red: 1, green: 0.3, blue: 0.3)
        case .timeRecovery(let sec):
            popupText  = "⏰ +\(Int(sec))秒回復！"
            popupColor = Color(red: 0.41, green: 0.94, blue: 0.68)
        }
        withAnimation(.spring(response: 0.2)) { popupVisible = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeOut(duration: 0.3)) { popupVisible = false }
        }
    }
}
