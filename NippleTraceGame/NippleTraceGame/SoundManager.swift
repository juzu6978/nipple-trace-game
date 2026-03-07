import AVFoundation

/// Web Audio API 相当の合成サウンドを AVFoundation で実装
class SoundManager {
    static let shared = SoundManager()
    private var engine = AVAudioEngine()
    private var players: [AVAudioPlayerNode] = []
    private var isSetup = false

    private init() { setup() }

    private func setup() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, options: .mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch { print("Audio session error: \(error)") }
    }

    // MARK: - Public API

    func playLap()         { play([523, 659, 784], durs: [0.12, 0.12, 0.15], delays: [0, 0.09, 0.18]) }
    func playBonus()       { play([523, 659, 784, 1047], durs: [0.15]*4,   delays: [0, 0.08, 0.16, 0.24]) }
    func playPenalty()     { play([220, 180], type: .sawtooth, durs: [0.25, 0.2], delays: [0, 0.15]) }
    func playLevelUp()     { play([523, 659, 784, 1047, 1319], durs: [0.2]*5, delays: [0,0.1,0.2,0.3,0.4]) }
    func playAchievement() { play([784, 988, 1319, 784, 1047, 1568], durs: [0.15]*6, delays: [0,0.08,0.16,0.24,0.32,0.40]) }
    func playGameOver()    { play([400, 300, 200], durs: [0.3]*3, delays: [0, 0.18, 0.36]) }
    func playStart()       { play([392, 523, 659], durs: [0.12]*3, delays: [0, 0.08, 0.16]) }

    // MARK: - Synthesizer

    private enum WaveType { case sine, sawtooth }

    private func play(_ freqs: [Double],
                      type: WaveType = .sine,
                      durs: [Double],
                      delays: [Double]) {
        guard SaveData.shared.soundEnabled else { return }
        for (i, freq) in freqs.enumerated() {
            let delay = i < delays.count ? delays[i] : 0
            let dur   = i < durs.count   ? durs[i]   : 0.15
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.tone(freq: freq, duration: dur, type: type)
            }
        }
    }

    private func tone(freq: Double, duration: Double, type: WaveType) {
        let sampleRate: Double = 44100
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!,
            frameCapacity: frameCount
        ) else { return }

        buffer.frameLength = frameCount
        let data = buffer.floatChannelData![0]
        let volume: Float = 0.25

        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let envelope = Float(max(0, 1 - t / duration))
            let wave: Float
            switch type {
            case .sine:
                wave = Float(sin(2 * .pi * freq * t))
            case .sawtooth:
                let period = 1.0 / freq
                wave = Float(2 * (t / period - floor(0.5 + t / period)))
            }
            data[i] = wave * volume * envelope
        }

        let player = AVAudioPlayerNode()
        let format  = buffer.format

        // Re-create engine connections each time (simple approach)
        let eng = AVAudioEngine()
        eng.attach(player)
        eng.connect(player, to: eng.mainMixerNode, format: format)
        do {
            try eng.start()
            player.scheduleBuffer(buffer, completionHandler: nil)
            player.play()
            // Keep engine alive until playback completes
            DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.1) {
                eng.stop()
            }
        } catch {
            // Silently fail - sound is non-critical
        }
    }
}

private extension Array {
    static func * (lhs: Array, rhs: Int) -> Array {
        var result: Array = []
        for _ in 0..<rhs { result.append(contentsOf: lhs) }
        return result
    }
}
