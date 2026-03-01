import GameKit
import UIKit

/// Game Center のリーダーボードと実績を管理するクラス
class GameCenterManager: NSObject {
    static let shared = GameCenterManager()

    private var isAuthenticated = false
    private var presentingVC: UIViewController?

    // MARK: - Leaderboard IDs (App Store Connect で同じIDを設定してください)
    private let leaderboardIDs: [String: String] = [
        "easy":    "com.masaki.NippleTraceGame.easy",
        "normal":  "com.masaki.NippleTraceGame.normal",
        "hard":    "com.masaki.NippleTraceGame.hard",
        "extreme": "com.masaki.NippleTraceGame.extreme",
        "daily":   "com.masaki.NippleTraceGame.daily",
    ]

    // MARK: - Authentication

    func authenticate(presenting vc: UIViewController) {
        presentingVC = vc
        let localPlayer = GKLocalPlayer.local
        localPlayer.authenticateHandler = { [weak self] viewController, error in
            if let vc = viewController {
                // Show Game Center login screen
                self?.presentingVC?.present(vc, animated: true)
            } else if GKLocalPlayer.local.isAuthenticated {
                self?.isAuthenticated = true
                print("Game Center: authenticated as \(GKLocalPlayer.local.displayName)")
            } else {
                print("Game Center: not authenticated — \(error?.localizedDescription ?? "unknown")")
            }
        }
    }

    // MARK: - Submit Score

    func submitScore(_ score: Int, difficulty: String) {
        guard isAuthenticated else { return }
        guard let leaderboardID = leaderboardIDs[difficulty] else { return }

        GKLeaderboard.submitScore(
            score,
            context: 0,
            player: GKLocalPlayer.local,
            leaderboardIDs: [leaderboardID]
        ) { error in
            if let error {
                print("GameCenter submitScore error: \(error)")
            } else {
                print("GameCenter: score \(score) submitted to \(leaderboardID)")
            }
        }
    }

    // MARK: - Show Leaderboard

    func showLeaderboard(difficulty: String) {
        guard isAuthenticated, let presentingVC else {
            showNotAvailableAlert()
            return
        }
        guard let leaderboardID = leaderboardIDs[difficulty] else { return }

        let gcVC = GKGameCenterViewController(
            leaderboardID: leaderboardID,
            playerScope: .global,
            timeScope: .allTime
        )
        gcVC.gameCenterDelegate = self
        presentingVC.present(gcVC, animated: true)
    }

    // MARK: - Report Achievement

    func reportAchievement(_ identifier: String, percentComplete: Double = 100.0) {
        guard isAuthenticated else { return }
        let achievement = GKAchievement(identifier: identifier)
        achievement.percentComplete = percentComplete
        achievement.showsCompletionBanner = true
        GKAchievement.report([achievement]) { error in
            if let error { print("GameCenter achievement error: \(error)") }
        }
    }

    // MARK: - Private

    private func showNotAvailableAlert() {
        let alert = UIAlertController(
            title: "Game Center 未ログイン",
            message: "「設定」→「Game Center」でサインインするとランキングが使えます",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        presentingVC?.present(alert, animated: true)
    }
}

extension GameCenterManager: GKGameCenterControllerDelegate {
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true)
    }
}
