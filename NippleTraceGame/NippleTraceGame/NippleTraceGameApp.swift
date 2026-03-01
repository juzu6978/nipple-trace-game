import SwiftUI
import UIKit

@main
struct NippleTraceGameApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// MARK: - AppDelegate

class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // バックグラウンド移行時に呼び戻し通知をスケジュール
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        return true
    }

    @objc private func appDidEnterBackground() {
        NotificationManager.shared.scheduleReEngagementIfNeeded()
    }

    @objc private func appDidBecomeActive() {
        NotificationManager.shared.cancelReEngagement()
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
}
