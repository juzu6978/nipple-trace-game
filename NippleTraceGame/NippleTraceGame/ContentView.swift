import SwiftUI
import WebKit
import GameKit

// MARK: - WebView with JS Bridge

struct GameWebView: UIViewRepresentable {
    @Binding var webView: WKWebView?

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()

        // Register JS message handlers
        let handlers = ["haptic", "gameCenter", "ads", "share", "notifications"]
        handlers.forEach { name in
            config.userContentController.add(context.coordinator, name: name)
        }

        let wv = WKWebView(frame: .zero, configuration: config)
        wv.scrollView.isScrollEnabled = false
        wv.scrollView.bounces = false
        wv.isOpaque = false
        wv.backgroundColor = UIColor(red: 0.06, green: 0.05, blue: 0.16, alpha: 1)

        if let url = Bundle.main.url(forResource: "nipple_trace_game", withExtension: "html") {
            wv.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }

        context.coordinator.webView = wv
        DispatchQueue.main.async { self.webView = wv }
        return wv
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    // MARK: - Coordinator (JS Message Handler)

    class Coordinator: NSObject, WKScriptMessageHandler {
        weak var webView: WKWebView?

        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            guard let body = message.body as? [String: Any] else { return }

            switch message.name {

            // ---------- ハプティクス ----------
            case "haptic":
                let type = body["type"] as? String ?? ""
                DispatchQueue.main.async {
                    switch type {
                    case "lap":         HapticsManager.shared.playLap()
                    case "bonus":       HapticsManager.shared.playBonus()
                    case "penalty":     HapticsManager.shared.playPenalty()
                    case "levelup":     HapticsManager.shared.playLevelUp()
                    case "achievement": HapticsManager.shared.playAchievement()
                    default:            HapticsManager.shared.playTap()
                    }
                }

            // ---------- Game Center ----------
            case "gameCenter":
                let action = body["action"] as? String ?? ""
                DispatchQueue.main.async {
                    switch action {
                    case "authenticate":
                        if let vc = self.rootVC() {
                            GameCenterManager.shared.authenticate(presenting: vc)
                        }
                    case "submitScore":
                        let score = body["score"] as? Int ?? 0
                        let diff  = body["difficulty"] as? String ?? "normal"
                        GameCenterManager.shared.submitScore(score, difficulty: diff)
                    case "showLeaderboard":
                        let diff = body["difficulty"] as? String ?? "normal"
                        GameCenterManager.shared.showLeaderboard(difficulty: diff)
                    default: break
                    }
                }

            // ---------- 広告 ----------
            case "ads":
                let action = body["action"] as? String ?? ""
                if action == "showRewardAd" {
                    DispatchQueue.main.async {
                        AdsManager.shared.showRewardAd {
                            // 報酬付与: JS に通知
                            self.webView?.evaluateJavaScript("window.onAdRewarded && window.onAdRewarded();", completionHandler: nil)
                        }
                    }
                }

            // ---------- シェア ----------
            case "share":
                let text  = body["text"]  as? String ?? "乳首トレースゲームに挑戦！"
                let score = body["score"] as? Int    ?? 0
                let diff  = body["difficulty"] as? String ?? ""
                let level = body["level"] as? Int   ?? 1
                DispatchQueue.main.async {
                    self.showShareSheet(text: text, score: score, diff: diff, level: level)
                }

            // ---------- 通知 ----------
            case "notifications":
                let action = body["action"] as? String ?? ""
                if action == "requestPermission" {
                    DispatchQueue.main.async {
                        NotificationManager.shared.requestPermission()
                    }
                }

            default: break
            }
        }

        // MARK: - Share Sheet

        private func showShareSheet(text: String, score: Int, diff: String, level: Int) {
            guard let vc = rootVC() else { return }

            let shareText = """
            🎯 まわれ！タイムアタック
            \(diff.uppercased()) で \(score)ポイント達成！
            現在 Lv.\(level)
            #まわれ #NippleTrace
            """

            let activityVC = UIActivityViewController(
                activityItems: [shareText],
                applicationActivities: nil
            )
            // iPad対応
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = vc.view
                popover.sourceRect = CGRect(x: vc.view.bounds.midX, y: vc.view.bounds.maxY - 100, width: 0, height: 0)
            }
            vc.present(activityVC, animated: true)
        }

        // MARK: - Helper

        private func rootVC() -> UIViewController? {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first(where: { $0.isKeyWindow })?.rootViewController
        }
    }
}

// MARK: - ContentView

struct ContentView: View {
    @State private var webView: WKWebView?

    var body: some View {
        GameWebView(webView: $webView)
            .ignoresSafeArea()
            .onAppear {
                // 呼び戻し通知をキャンセル（アプリ起動時）
                NotificationManager.shared.cancelReEngagement()
            }
    }
}
