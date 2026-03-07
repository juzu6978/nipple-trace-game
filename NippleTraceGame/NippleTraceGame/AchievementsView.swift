import SwiftUI

// MARK: - AchievementsView

struct AchievementsView: View {
    var onBack: () -> Void

    @ObservedObject private var save = SaveData.shared
    @State private var selectedTab = 0

    var body: some View {
        ZStack {
            Color(red: 0.06, green: 0.05, blue: 0.16).ignoresSafeArea()

            VStack(spacing: 0) {
                navigationBar
                tabSelector
                ScrollView(showsIndicators: false) {
                    if selectedTab == 0 {
                        achievementsGrid
                    } else {
                        statsContent
                    }
                }
            }
        }
    }

    // MARK: - Navigation Bar

    private var navigationBar: some View {
        HStack {
            Button(action: onBack) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                    Text("戻る")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.white.opacity(0.7))
            }
            Spacer()
            Text("実績 & 統計")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Spacer()
            Color.clear.frame(width: 60, height: 1)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        HStack(spacing: 0) {
            tabBtn("🏆 実績", index: 0)
            tabBtn("📊 統計", index: 1)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 14)
    }

    private func tabBtn(_ title: String, index: Int) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3)) { selectedTab = index }
        }) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(selectedTab == index ? .white : .white.opacity(0.35))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(selectedTab == index
                             ? Color.white.opacity(0.1)
                             : Color.clear)
                .cornerRadius(10)
        }
    }

    // MARK: - Achievements Grid

    private var achievementsGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 12) {
            ForEach(AchievementList.all) { a in
                achievementCell(a)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
    }

    private func achievementCell(_ a: Achievement) -> some View {
        let unlocked = save.isUnlocked(a.id)
        return VStack(spacing: 8) {
            Text(a.icon)
                .font(.system(size: 38))
                .opacity(unlocked ? 1.0 : 0.25)
                .grayscale(unlocked ? 0 : 1)

            Text(a.name)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(unlocked ? .white : .white.opacity(0.28))
                .multilineTextAlignment(.center)

            Text(a.desc)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.35))
                .multilineTextAlignment(.center)
                .lineLimit(2)

            Text(unlocked ? "✅ 解除済" : "🔒 未解除")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(unlocked
                                 ? Color(red: 0.41, green: 0.94, blue: 0.68)
                                 : .white.opacity(0.2))
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(unlocked
                    ? Color(red: 1, green: 0.84, blue: 0.25).opacity(0.07)
                    : Color.white.opacity(0.04))
        .overlay(
            RoundedRectangle(cornerRadius: 13)
                .stroke(unlocked
                        ? Color(red: 1, green: 0.84, blue: 0.25).opacity(0.25)
                        : Color.white.opacity(0.07),
                        lineWidth: 1)
        )
        .cornerRadius(13)
    }

    // MARK: - Stats Content

    private var statsContent: some View {
        VStack(spacing: 14) {
            levelCard
            generalStatsCard
            bestScoresCard
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
    }

    private var levelCard: some View {
        VStack(spacing: 10) {
            HStack {
                Text("🌟 レベル")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white.opacity(0.55))
                Spacer()
                Text("Lv.\(save.currentLevel)")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundColor(Color(red: 1, green: 0.84, blue: 0.25))
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.1)).frame(height: 8)
                    Capsule()
                        .fill(LinearGradient(
                            colors: [Color(red: 1, green: 0.84, blue: 0.25),
                                     Color(red: 1, green: 0.5, blue: 0.1)],
                            startPoint: .leading, endPoint: .trailing
                        ))
                        .frame(width: max(0, geo.size.width * CGFloat(save.levelProgress)), height: 8)
                }
            }
            .frame(height: 8)

            HStack {
                Text("\(save.xpInCurrentLevel) XP")
                    .font(.system(size: 12)).foregroundColor(.white.opacity(0.35))
                Spacer()
                Text("次まで \(save.xpToNextLevel - save.xpInCurrentLevel) XP")
                    .font(.system(size: 12)).foregroundColor(.white.opacity(0.35))
            }
        }
        .padding(16)
        .background(Color(red: 1, green: 0.84, blue: 0.25).opacity(0.06))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(red: 1, green: 0.84, blue: 0.25).opacity(0.18), lineWidth: 1)
        )
        .cornerRadius(14)
    }

    private var generalStatsCard: some View {
        VStack(spacing: 12) {
            Text("📊 全体統計")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white.opacity(0.5))
                .frame(maxWidth: .infinity, alignment: .leading)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                statTile("🎮", "\(save.totalGames)", "ゲーム数")
                statTile("🌀", "\(save.totalLaps)", "総周回数")
                statTile("💯", "\(save.totalXP)", "総XP")
                statTile("💥", "\(save.totalPenalties)", "ペナルティ")
                statTile("🔥", "\(save.streakCount)日", "連続プレイ")
                statTile("🏆", "\(save.achievements.count)/\(AchievementList.all.count)", "実績")
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.04))
        .cornerRadius(14)
    }

    private func statTile(_ icon: String, _ value: String, _ label: String) -> some View {
        VStack(spacing: 4) {
            Text(icon + "  " + value)
                .font(.system(size: 16, weight: .black))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.35))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.04))
        .cornerRadius(10)
    }

    private var bestScoresCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("🏆 最高スコア")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white.opacity(0.5))

            ForEach(DifficultyConfig.all, id: \.id) { cfg in
                HStack {
                    Text(cfg.emoji + "  " + cfg.label)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(cfg.swiftUIColor)
                    Spacer()
                    if let best = save.bestScores[cfg.id] {
                        Text("\(best) pt")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Text("未プレイ")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.28))
                    }
                }
                .padding(.vertical, 5)
                if cfg.id != "extreme" {
                    Divider().background(Color.white.opacity(0.08))
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.04))
        .cornerRadius(14)
    }
}
