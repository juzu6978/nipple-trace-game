import SwiftUI

// MARK: - App Screen

enum AppScreen {
    case home
    case difficulty
    case daily
    case game
    case result
    case achievements

    var id: String {
        switch self {
        case .home:         return "home"
        case .difficulty:   return "difficulty"
        case .daily:        return "daily"
        case .game:         return "game"
        case .result:       return "result"
        case .achievements: return "achievements"
        }
    }
}

// MARK: - ContentView (Navigation Coordinator)

struct ContentView: View {
    @State private var screen: AppScreen = .home
    @State private var gameConfig: DifficultyConfig = .normal
    @State private var gameIsDaily = false
    @State private var gameResult: GameResult? = nil
    @State private var gameID = 0   // Incrementing ID forces new GameContainerView instance

    var body: some View {
        Group {
            switch screen {

            case .home:
                HomeView(
                    onPlay:         { transition(to: .difficulty) },
                    onDaily:        { transition(to: .daily) },
                    onAchievements: { transition(to: .achievements) }
                )

            case .difficulty:
                DifficultyView(
                    showDaily: false,
                    onBack:    { transition(to: .home) },
                    onSelect:  { cfg, isDaily in startGame(cfg, isDaily: isDaily) }
                )

            case .daily:
                DifficultyView(
                    showDaily: true,
                    onBack:    { transition(to: .home) },
                    onSelect:  { cfg, isDaily in startGame(cfg, isDaily: isDaily) }
                )

            case .game:
                GameContainerView(
                    config:     gameConfig,
                    isDaily:    gameIsDaily,
                    onComplete: { result in
                        gameResult = result
                        transition(to: .result)
                    },
                    onMenu: { transition(to: .home) }
                )
                .id(gameID)
                .ignoresSafeArea()  // フルスクリーン — HUD位置はGeometryReaderで制御

            case .result:
                if let result = gameResult {
                    ResultView(
                        result:        result,
                        onRetry:       { retryGame() },
                        onMenu:        { transition(to: .home) },
                        onLeaderboard: { showLeaderboard(for: result.difficultyID) }
                    )
                }

            case .achievements:
                AchievementsView(
                    onBack: { transition(to: .home) }
                )
            }
        }
        .onAppear(perform: setupManagers)
    }

    // MARK: - Navigation Helpers

    private func transition(to next: AppScreen) {
        withAnimation(.easeInOut(duration: 0.22)) {
            screen = next
        }
    }

    private func startGame(_ config: DifficultyConfig, isDaily: Bool) {
        gameConfig  = config
        gameIsDaily = isDaily
        gameID += 1
        transition(to: .game)
    }

    private func retryGame() {
        gameID += 1
        transition(to: .game)
    }

    private func showLeaderboard(for difficultyID: String) {
        GameCenterManager.shared.showLeaderboard(difficulty: difficultyID)
    }

    // MARK: - Manager Setup

    private func setupManagers() {
        NotificationManager.shared.cancelReEngagement()
        guard let vc = rootViewController() else { return }
        GameCenterManager.shared.authenticate(presenting: vc)
        AdsManager.shared.initialize(presenting: vc)
        NotificationManager.shared.requestPermission()
    }
}

// MARK: - Root VC Helper

func rootViewController() -> UIViewController? {
    UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .flatMap { $0.windows }
        .first(where: { $0.isKeyWindow })?.rootViewController
}
