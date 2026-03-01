import UIKit

// ============================================================
// AdsManager - Google AdMob 広告管理
// ============================================================
//
// 【セットアップ手順】
// 1. Xcodeで File → Add Package Dependencies を開く
//    URL: https://github.com/googleads/swift-package-manager-google-mobile-ads
//    バージョン: 最新の安定版（11.x 以上）を選択して追加
//
// 2. Info.plist に以下を追加:
//    Key:   GADApplicationIdentifier
//    Value: ca-app-pub-3940256099942544~1458002511  (← テスト用)
//           ※本番用は AdMob コンソールで取得した実際のApp IDに変更
//
// 3. このファイル下部の「// MARK: - REAL ADMOB IMPLEMENTATION」
//    のコメントを外して実装を有効化する
//
// 現在はスタブ実装（広告なし）で動作します
// ============================================================

/// 広告の状態
enum AdState {
    case notLoaded, loading, ready, showing
}

class AdsManager: NSObject {
    static let shared = AdsManager()

    private var rewardAdState: AdState = .notLoaded
    private var onRewardEarned: (() -> Void)?
    private var presentingVC: UIViewController?

    // MARK: - Test Ad Unit IDs (本番は変更必須)
    // バナー広告:   ca-app-pub-3940256099942544/2934735716
    // リワード広告: ca-app-pub-3940256099942544/1712485313

    // MARK: - Public API

    func initialize(presenting vc: UIViewController) {
        presentingVC = vc
        loadRewardAd()
    }

    func loadRewardAd() {
        // スタブ: 2秒後にロード完了とする
        rewardAdState = .loading
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.rewardAdState = .ready
            print("AdsManager: reward ad ready (stub)")
        }
    }

    func showRewardAd(onRewarded: @escaping () -> Void) {
        onRewardEarned = onRewarded

        if rewardAdState == .ready {
            // スタブ: 実際の広告の代わりに即時報酬
            print("AdsManager: showing reward ad (stub - immediate reward)")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.onRewardEarned?()
                self?.rewardAdState = .notLoaded
                self?.loadRewardAd()
            }
        } else {
            // 広告未準備
            print("AdsManager: ad not ready")
            showAdNotReadyAlert()
        }
    }

    var isRewardAdReady: Bool { rewardAdState == .ready }

    // MARK: - Private

    private func showAdNotReadyAlert() {
        let alert = UIAlertController(
            title: "広告を準備中",
            message: "しばらくしてからもう一度お試しください",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        presentingVC?.present(alert, animated: true)
    }
}

// ============================================================
// MARK: - REAL ADMOB IMPLEMENTATION
// 上記スタブを削除し、以下のコメントを外して使用してください
// GoogleMobileAds SDKを追加後に動作します
// ============================================================
/*
import GoogleMobileAds

class AdsManager: NSObject {
    static let shared = AdsManager()

    private var rewardAd: GADRewardedAd?
    private var onRewardEarned: (() -> Void)?
    private var presentingVC: UIViewController?

    // ★ AdMob コンソールで取得したリワード広告のユニットIDに変更
    private let rewardAdUnitID = "ca-app-pub-3940256099942544/1712485313"

    func initialize(presenting vc: UIViewController) {
        presentingVC = vc
        GADMobileAds.sharedInstance().start { _ in
            print("AdMob initialized")
        }
        loadRewardAd()
    }

    func loadRewardAd() {
        let req = GADRequest()
        GADRewardedAd.load(withAdUnitID: rewardAdUnitID, request: req) { [weak self] ad, error in
            if let error {
                print("Reward ad load error: \(error)")
            } else {
                self?.rewardAd = ad
                self?.rewardAd?.fullScreenContentDelegate = self
                print("Reward ad loaded")
            }
        }
    }

    func showRewardAd(onRewarded: @escaping () -> Void) {
        onRewardEarned = onRewarded
        guard let rewardAd, let vc = presentingVC else {
            print("Reward ad not ready")
            return
        }
        rewardAd.present(fromRootViewController: vc) { [weak self] in
            // User watched the ad → give reward
            self?.onRewardEarned?()
        }
    }

    var isRewardAdReady: Bool { rewardAd != nil }
}

extension AdsManager: GADFullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        loadRewardAd() // 次の広告をプリロード
    }
}
*/
