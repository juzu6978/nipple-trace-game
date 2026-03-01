import CoreHaptics
import UIKit

/// CoreHapticsを使ったバイブレーション管理クラス
class HapticsManager {
    static let shared = HapticsManager()

    private var engine: CHHapticEngine?
    private var isAvailable: Bool = false

    private init() {
        setup()
    }

    private func setup() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            engine = try CHHapticEngine()
            engine?.stoppedHandler = { [weak self] _ in self?.setup() }
            engine?.resetHandler  = { [weak self] in try? self?.engine?.start() }
            try engine?.start()
            isAvailable = true
        } catch {
            print("Haptics engine error: \(error)")
        }
    }

    // MARK: - Public API

    /// 周回成功時のバイブ（短く爽快）
    func playLap() {
        playPattern([
            (intensity: 0.6, sharpness: 0.8, duration: 0.08, delay: 0),
            (intensity: 0.9, sharpness: 0.9, duration: 0.12, delay: 0.1),
        ])
    }

    /// ボーナス時のバイブ（派手）
    func playBonus() {
        playPattern([
            (intensity: 0.7, sharpness: 0.5, duration: 0.1, delay: 0),
            (intensity: 1.0, sharpness: 1.0, duration: 0.15, delay: 0.12),
            (intensity: 0.8, sharpness: 0.8, duration: 0.1, delay: 0.28),
        ])
    }

    /// ペナルティ時のバイブ（重くガツン）
    func playPenalty() {
        playPattern([
            (intensity: 1.0, sharpness: 0.1, duration: 0.25, delay: 0),
            (intensity: 0.5, sharpness: 0.1, duration: 0.15, delay: 0.28),
        ])
    }

    /// レベルアップ時のバイブ
    func playLevelUp() {
        playPattern([
            (intensity: 0.5, sharpness: 0.9, duration: 0.08, delay: 0),
            (intensity: 0.7, sharpness: 0.9, duration: 0.08, delay: 0.1),
            (intensity: 0.9, sharpness: 1.0, duration: 0.15, delay: 0.2),
            (intensity: 1.0, sharpness: 1.0, duration: 0.2,  delay: 0.38),
        ])
    }

    /// 実績解除時のバイブ
    func playAchievement() {
        playPattern([
            (intensity: 0.6, sharpness: 1.0, duration: 0.1, delay: 0),
            (intensity: 0.8, sharpness: 0.8, duration: 0.1, delay: 0.15),
            (intensity: 1.0, sharpness: 1.0, duration: 0.2, delay: 0.3),
        ])
    }

    /// 軽いタップ
    func playTap() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    // MARK: - Private

    private typealias HapticEvent = (intensity: Double, sharpness: Double, duration: Double, delay: Double)

    private func playPattern(_ events: [HapticEvent]) {
        guard isAvailable, let engine else {
            // Fallback: UIKit
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            return
        }
        do {
            let hapticEvents: [CHHapticEvent] = events.map { ev in
                CHHapticEvent(
                    eventType: .hapticContinuous,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(ev.intensity)),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: Float(ev.sharpness)),
                    ],
                    relativeTime: ev.delay,
                    duration: ev.duration
                )
            }
            let pattern = try CHHapticPattern(events: hapticEvents, parameters: [])
            let player  = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }
}
