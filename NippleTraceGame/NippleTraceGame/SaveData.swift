import Foundation
import Combine

/// UserDefaults ベースの永続化データ管理（旧 localStorage の代替）
class SaveData: ObservableObject {
    static let shared = SaveData()

    private let ud = UserDefaults.standard

    // MARK: - XP / Level
    @Published var totalXP: Int        { didSet { ud.set(totalXP,        forKey: "totalXP") } }
    @Published var totalGames: Int     { didSet { ud.set(totalGames,      forKey: "totalGames") } }
    @Published var totalLaps: Int      { didSet { ud.set(totalLaps,       forKey: "totalLaps") } }
    @Published var totalPenalties: Int { didSet { ud.set(totalPenalties,  forKey: "totalPenalties") } }
    @Published var soundEnabled: Bool  { didSet { ud.set(soundEnabled,    forKey: "soundEnabled") } }

    // MARK: - Best Scores  [difficultyID: score]
    @Published private(set) var bestScores: [String: Int] = [:] {
        didSet { ud.set(bestScores, forKey: "bestScores") }
    }

    // MARK: - Achievements  [id: unixTimestamp]
    @Published private(set) var achievements: [String: Double] = [:] {
        didSet { ud.set(achievements, forKey: "achievements") }
    }

    // MARK: - Streak
    @Published var streakCount: Int    { didSet { ud.set(streakCount,     forKey: "streakCount") } }
    @Published var streakLastDate: String? { didSet { ud.set(streakLastDate, forKey: "streakLastDate") } }

    // MARK: - Daily
    @Published var dailyCompletedDate: String? { didSet { ud.set(dailyCompletedDate, forKey: "dailyCompletedDate") } }

    // MARK: - Init

    private init() {
        totalXP        = ud.integer(forKey: "totalXP")
        totalGames     = ud.integer(forKey: "totalGames")
        totalLaps      = ud.integer(forKey: "totalLaps")
        totalPenalties = ud.integer(forKey: "totalPenalties")
        streakCount    = ud.integer(forKey: "streakCount")
        streakLastDate = ud.string(forKey: "streakLastDate")
        dailyCompletedDate = ud.string(forKey: "dailyCompletedDate")
        bestScores     = (ud.dictionary(forKey: "bestScores") as? [String: Int]) ?? [:]
        achievements   = (ud.dictionary(forKey: "achievements") as? [String: Double]) ?? [:]
        // soundEnabled: nil → true (default ON)
        soundEnabled   = ud.object(forKey: "soundEnabled") == nil ? true : ud.bool(forKey: "soundEnabled")
    }

    // MARK: - Public Methods

    func updateBestScore(difficultyID: String, score: Int) {
        let current = bestScores[difficultyID] ?? 0
        if score > current { bestScores[difficultyID] = score }
    }

    /// 実績を解除。新たに解除された場合 true を返す
    @discardableResult
    func unlockAchievement(_ id: String) -> Bool {
        guard achievements[id] == nil else { return false }
        achievements[id] = Date().timeIntervalSince1970
        return true
    }

    func isUnlocked(_ id: String) -> Bool { achievements[id] != nil }

    /// 連続プレイを更新
    func updateStreak() {
        let today = todayString()
        guard streakLastDate != today else { return }
        let yesterday = yesterdayString()
        streakCount   = (streakLastDate == yesterday) ? streakCount + 1 : 1
        streakLastDate = today
    }

    func todayString() -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    // MARK: - Level System

    var currentLevel: Int { levelFromXP(totalXP) }

    /// 現在レベル内での進捗 0.0〜1.0
    var levelProgress: Double {
        let lv   = currentLevel
        let base = xpForLevel(lv)
        let need = xpNeededForLevel(lv)
        return need > 0 ? Double(totalXP - base) / Double(need) : 1
    }

    /// 現在レベル内でのXP
    var xpInCurrentLevel: Int {
        totalXP - xpForLevel(currentLevel)
    }

    /// 次のレベルまでに必要なXP
    var xpToNextLevel: Int {
        xpNeededForLevel(currentLevel)
    }

    private func levelFromXP(_ xp: Int) -> Int {
        Int((1 + sqrt(1 + 8 * Double(xp) / 100)) / 2)
    }
    private func xpForLevel(_ lv: Int) -> Int { lv * (lv - 1) / 2 * 100 }
    private func xpNeededForLevel(_ lv: Int) -> Int { lv * 100 }

    private func yesterdayString() -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date().addingTimeInterval(-86400))
    }
}
