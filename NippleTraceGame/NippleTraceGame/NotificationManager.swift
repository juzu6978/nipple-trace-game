import UserNotifications
import UIKit

/// プッシュ通知管理クラス
class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    // MARK: - Permission Request

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    print("Notification permission granted")
                    self.scheduleDailyReminder()
                } else {
                    print("Notification permission denied: \(error?.localizedDescription ?? "")")
                }
            }
        }
    }

    // MARK: - Schedule Daily Reminder

    /// 毎日21時に「今日もプレイしよう！」通知を送る
    func scheduleDailyReminder() {
        let center = UNUserNotificationCenter.current()

        // 既存の通知を削除してから再スケジュール
        center.removePendingNotificationRequests(withIdentifiers: ["daily_reminder"])

        let content = UNMutableNotificationContent()
        content.title = "🎯 まわれ！タイムアタック"
        content.body  = "今日のデイリーチャレンジはもうやった？連続プレイを続けよう！"
        content.sound = .default
        content.badge = 1

        var dateComponents = DateComponents()
        dateComponents.hour   = 21
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "daily_reminder",
            content:    content,
            trigger:    trigger
        )

        center.add(request) { error in
            if let error { print("Notification schedule error: \(error)") }
            else         { print("Daily reminder scheduled for 21:00") }
        }
    }

    /// 3日間プレイしていない時の呼び戻し通知（アプリがバックグラウンドになった時にスケジュール）
    func scheduleReEngagementIfNeeded() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["re_engage"])

        let content = UNMutableNotificationContent()
        content.title = "🔥 連続プレイが途切れそう！"
        content.body  = "記録を守るために今すぐプレイしよう！"
        content.sound = .default

        // 3日後に発火
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 3 * 24 * 60 * 60,
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: "re_engage",
            content:    content,
            trigger:    trigger
        )
        center.add(request) { error in
            if let error { print("Re-engage notification error: \(error)") }
        }
    }

    /// アプリが起動したら呼び戻し通知をキャンセル
    func cancelReEngagement() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["re_engage"])
        UIApplication.shared.applicationIconBadgeNumber = 0
    }

    // MARK: - Score Achievement Notification

    func sendScoreNotification(score: Int, difficulty: String) {
        guard score >= 10 else { return }

        let content = UNMutableNotificationContent()
        content.title = "🏆 新記録達成！"
        content.body  = "\(difficulty) で \(score) ポイント達成！この勢いで挑戦し続けよう！"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "score_\(Int(Date().timeIntervalSince1970))",
            content:    content,
            trigger:    trigger
        )
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
}
