import UIKit

// MARK: - Difficulty Config

struct DifficultyConfig {
    let id: String
    let label: String
    let emoji: String
    let time: Double       // 制限時間（秒）
    let trackMin: CGFloat  // NG ゾーン半径（乳首に触れる最小距離）
    let penalty: Double    // ペナルティ秒数
    let comboBon: Int      // コンボボーナス発生周回数
    let xpMult: Double     // XP 倍率
    let color: UIColor
    let bonusMult: Int     // ボーナス得点倍率
    let lapTimeBonus: Double // 1周ごとに回復する秒数（タイムラッシュ等）

    var swiftUIColor: Color {
        Color(uiColor: color)
    }
}

import SwiftUI

extension DifficultyConfig {
    static let easy = DifficultyConfig(
        id: "easy",    label: "EASY",    emoji: "😊",
        time: 45, trackMin: 48, penalty: 2, comboBon: 3, xpMult: 1.0,
        color: UIColor(red: 0.0,  green: 0.90, blue: 0.45, alpha: 1),
        bonusMult: 1, lapTimeBonus: 0
    )
    static let normal = DifficultyConfig(
        id: "normal",  label: "NORMAL",  emoji: "😐",
        time: 30, trackMin: 40, penalty: 3, comboBon: 3, xpMult: 1.5,
        color: UIColor(red: 1.0,  green: 0.84, blue: 0.25, alpha: 1),
        bonusMult: 1, lapTimeBonus: 0
    )
    static let hard = DifficultyConfig(
        id: "hard",    label: "HARD",    emoji: "😤",
        time: 20, trackMin: 36, penalty: 4, comboBon: 3, xpMult: 2.0,
        color: UIColor(red: 1.0,  green: 0.43, blue: 0.00, alpha: 1),
        bonusMult: 1, lapTimeBonus: 0
    )
    static let extreme = DifficultyConfig(
        id: "extreme", label: "EXTREME", emoji: "💀",
        time: 15, trackMin: 33, penalty: 5, comboBon: 3, xpMult: 3.0,
        color: UIColor(red: 1.0,  green: 0.09, blue: 0.27, alpha: 1),
        bonusMult: 1, lapTimeBonus: 0
    )

    static let all: [DifficultyConfig] = [.easy, .normal, .hard, .extreme]
    static func from(id: String) -> DifficultyConfig {
        all.first(where: { $0.id == id }) ?? .normal
    }
}

// MARK: - Daily Challenge

struct DailyChallengeType {
    let name: String
    let icon: String
    let desc: String
    let bonusDesc: String
    // オーバーライドする項目（nil = NORMAL のデフォルト使用）
    let time: Double?
    let trackMin: CGFloat?
    let penalty: Double?
    let comboBon: Int?
    let xpMult: Double?
    let bonusMult: Int?
    let lapTimeBonus: Double?

    /// NORMAL をベースに設定を合成して DifficultyConfig を返す
    func resolve() -> DifficultyConfig {
        let base = DifficultyConfig.normal
        return DifficultyConfig(
            id: "daily", label: "DAILY", emoji: icon,
            time:         time         ?? base.time,
            trackMin:     trackMin     ?? base.trackMin,
            penalty:      penalty      ?? base.penalty,
            comboBon:     comboBon     ?? base.comboBon,
            xpMult:       xpMult       ?? base.xpMult,
            color:        UIColor(red: 1.0, green: 0.76, blue: 0.03, alpha: 1),
            bonusMult:    bonusMult    ?? base.bonusMult,
            lapTimeBonus: lapTimeBonus ?? base.lapTimeBonus
        )
    }
}

struct DailyChallenge {
    static let all: [DailyChallengeType] = [
        DailyChallengeType(
            name: "タイムラッシュ", icon: "⚡",
            desc: "制限時間20秒！周回ごとに+2秒回復！ボーナスは2倍！",
            bonusDesc: "🌟 周回+2秒 / ボーナス2倍",
            time: 20, trackMin: nil, penalty: nil, comboBon: nil,
            xpMult: 2.5, bonusMult: 2, lapTimeBonus: 2
        ),
        DailyChallengeType(
            name: "狭軌道", icon: "🎯",
            desc: "コースが超狭い！ちょっとでも触れると即ペナルティ",
            bonusDesc: "",
            time: nil, trackMin: 34, penalty: nil, comboBon: nil,
            xpMult: nil, bonusMult: nil, lapTimeBonus: nil
        ),
        DailyChallengeType(
            name: "エンデュランス", icon: "🏃",
            desc: "60秒の持久戦！集中力が試される",
            bonusDesc: "🌟 超大量XP",
            time: 60, trackMin: nil, penalty: nil, comboBon: nil,
            xpMult: 2.0, bonusMult: nil, lapTimeBonus: nil
        ),
        DailyChallengeType(
            name: "スーパーコンボ", icon: "🔥",
            desc: "2連続クリアでボーナス発生！",
            bonusDesc: "🌟 コンボしやすい",
            time: nil, trackMin: nil, penalty: nil, comboBon: 2,
            xpMult: nil, bonusMult: nil, lapTimeBonus: nil
        ),
        DailyChallengeType(
            name: "ダブルペナルティ", icon: "💥",
            desc: "乳首に触れると-6秒の激辛ペナルティ！",
            bonusDesc: "",
            time: nil, trackMin: nil, penalty: 6, comboBon: nil,
            xpMult: nil, bonusMult: nil, lapTimeBonus: nil
        ),
    ]

    static func today() -> DailyChallengeType {
        let day = Int(Date().timeIntervalSince1970 / 86400)
        return all[day % all.count]
    }
}

// MARK: - Achievements

struct Achievement: Identifiable {
    let id: String
    let icon: String
    let name: String
    let desc: String
}

struct AchievementList {
    static let all: [Achievement] = [
        Achievement(id: "first_play",   icon: "👶", name: "はじめての一歩",   desc: "初めてゲームをプレイ"),
        Achievement(id: "five_laps",    icon: "🌀", name: "まわるくん",       desc: "1ゲームで5周以上達成"),
        Achievement(id: "combo_king",   icon: "🔥", name: "コンボキング",     desc: "1ゲームでボーナス3回以上"),
        Achievement(id: "no_miss",      icon: "✨", name: "ノーミス",         desc: "NORMAL以上でペナルティなし1周以上"),
        Achievement(id: "speed_master", icon: "⚡", name: "スピードマスター", desc: "HARDで8周以上"),
        Achievement(id: "streak_7",     icon: "📅", name: "毎日の習慣",       desc: "7日連続プレイ"),
        Achievement(id: "hundred_laps", icon: "💯", name: "百周達成",         desc: "累計100周以上"),
        Achievement(id: "legend",       icon: "👑", name: "レジェンド",       desc: "レベル10に到達"),
        Achievement(id: "daily_clear",  icon: "🗓️", name: "デイリークリア",   desc: "デイリーチャレンジで1周以上"),
        Achievement(id: "extreme_5",    icon: "💀", name: "極限への挑戦",     desc: "EXTREMEで5ポイント以上"),
    ]

    @discardableResult
    static func checkAndUnlock(laps: Int, bonus: Int, penalties: Int,
                               diffID: String, isDaily: Bool,
                               save: SaveData) -> [Achievement] {
        var unlocked: [Achievement] = []
        func check(_ id: String, _ cond: Bool) {
            if cond && save.unlockAchievement(id),
               let a = all.first(where: { $0.id == id }) {
                unlocked.append(a)
            }
        }
        let total = laps + bonus
        check("first_play",   save.totalGames >= 1)
        check("five_laps",    laps >= 5)
        check("combo_king",   bonus >= 3)
        check("no_miss",      penalties == 0 && ["normal","hard","extreme"].contains(diffID) && laps >= 1)
        check("speed_master", diffID == "hard" && laps >= 8)
        check("streak_7",     save.streakCount >= 7)
        check("hundred_laps", save.totalLaps >= 100)
        check("legend",       save.currentLevel >= 10)
        check("daily_clear",  isDaily && laps >= 1)
        check("extreme_5",    diffID == "extreme" && total >= 5)
        return unlocked
    }
}

// MARK: - Game Result

struct GameResult {
    let laps: Int
    let bonus: Int
    let penalties: Int
    let difficultyID: String
    let difficultyLabel: String
    let isDaily: Bool
    let xpEarned: Int
    let unlockedAchievements: [Achievement]
    var totalScore: Int { laps + bonus }
}
