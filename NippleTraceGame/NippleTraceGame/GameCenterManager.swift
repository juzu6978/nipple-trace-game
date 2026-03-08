import Foundation

/// Game Center stub — 実機テスト用。
/// App Store 申請時は GameKit を有効化し、Apple Developer Portal で
/// Game Center を App ID に追加してください。
final class GameCenterManager: NSObject {
    static let shared = GameCenterManager()

    private override init() {}

    // MARK: - Authentication (stub)

    func authenticate(presenting vc: AnyObject?) {
        print("GameCenter: stub — skipping authentication")
    }

    // MARK: - Submit Score (stub)

    func submitScore(_ score: Int, difficulty: String) {
        print("GameCenter: stub — would submit score \(score) for \(difficulty)")
    }

    // MARK: - Show Leaderboard (stub)

    func showLeaderboard(difficulty: String) {
        print("GameCenter: stub — leaderboard not available")
    }

    // MARK: - Report Achievement (stub)

    func reportAchievement(_ identifier: String, percentComplete: Double = 100.0) {
        print("GameCenter: stub — would report achievement \(identifier)")
    }
}
