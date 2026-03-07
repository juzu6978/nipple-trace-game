import SwiftUI

// MARK: - HomeView

struct HomeView: View {
    @ObservedObject private var save = SaveData.shared
    var onPlay: () -> Void
    var onDaily: () -> Void
    var onAchievements: () -> Void

    var body: some View {
        ZStack {
            Color(red: 0.06, green: 0.05, blue: 0.16).ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                Spacer()
                titleSection
                Spacer()

                xpSection
                    .padding(.horizontal, 24)

                Spacer(minLength: 28)

                buttonSection
                    .padding(.horizontal, 24)

                Spacer()

                streakFooter
                    .padding(.bottom, 44)
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            HStack(spacing: 5) {
                Text("⭐")
                    .font(.system(size: 14))
                Text("Lv.\(save.currentLevel)")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundColor(Color(red: 1, green: 0.84, blue: 0.25))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.08))
            .cornerRadius(20)

            Spacer()

            Button(action: { save.soundEnabled.toggle() }) {
                Text(save.soundEnabled ? "🔊" : "🔇")
                    .font(.system(size: 22))
            }
        }
    }

    // MARK: - Title

    private var titleSection: some View {
        VStack(spacing: 8) {
            Text("まわれ！")
                .font(.system(size: 54, weight: .black, design: .rounded))
                .foregroundStyle(LinearGradient(
                    colors: [Color(red: 1, green: 0.5, blue: 0.7),
                             Color(red: 1, green: 0.84, blue: 0.3)],
                    startPoint: .leading, endPoint: .trailing
                ))
            Text("タイムアタック")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.35))
                .tracking(5)
        }
    }

    // MARK: - XP Section

    private var xpSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Lv.\(save.currentLevel)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.55))
                Spacer()
                Text("\(save.xpInCurrentLevel) / \(save.xpToNextLevel) XP")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.38))
                Text("→ Lv.\(save.currentLevel + 1)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(red: 0.41, green: 0.94, blue: 0.68))
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 8)
                    Capsule()
                        .fill(LinearGradient(
                            colors: [Color(red: 0.41, green: 0.94, blue: 0.68),
                                     Color(red: 0, green: 0.7, blue: 1)],
                            startPoint: .leading, endPoint: .trailing
                        ))
                        .frame(width: max(0, geo.size.width * CGFloat(save.levelProgress)), height: 8)
                        .animation(.spring(), value: save.levelProgress)
                }
            }
            .frame(height: 8)

            HStack(spacing: 0) {
                statChip("🎮", "\(save.totalGames)", "ゲーム")
                statChip("🌀", "\(save.totalLaps)", "周回")
                statChip("💯", "\(save.totalXP)", "XP合計")
            }
        }
    }

    private func statChip(_ icon: String, _ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(icon + " " + value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.35))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Buttons

    private var buttonSection: some View {
        VStack(spacing: 12) {
            // Main PLAY button
            Button(action: onPlay) {
                HStack {
                    Image(systemName: "gamecontroller.fill")
                    Text("PLAY")
                }
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                .background(LinearGradient(
                    colors: [Color(red: 0.41, green: 0.94, blue: 0.68),
                             Color(red: 0, green: 0.85, blue: 0.9)],
                    startPoint: .leading, endPoint: .trailing
                ))
                .cornerRadius(18)
                .shadow(color: Color(red: 0.41, green: 0.94, blue: 0.68).opacity(0.45),
                        radius: 14, y: 5)
            }
            .buttonStyle(ScaleButtonStyle())

            HStack(spacing: 12) {
                // Daily
                Button(action: onDaily) {
                    VStack(spacing: 4) {
                        Text(DailyChallenge.today().icon + " デイリー")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                        Text(save.dailyCompletedDate == save.todayString() ? "✅ 完了" : "未挑戦")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(
                                save.dailyCompletedDate == save.todayString()
                                    ? .green : .white.opacity(0.4)
                            )
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 62)
                    .background(Color.white.opacity(0.07))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color(red: 1, green: 0.84, blue: 0.25).opacity(0.35), lineWidth: 1)
                    )
                    .cornerRadius(14)
                }
                .buttonStyle(ScaleButtonStyle())

                // Achievements
                Button(action: onAchievements) {
                    VStack(spacing: 4) {
                        Text("🏆 実績")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                        Text("\(save.achievements.count)/\(AchievementList.all.count)")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 62)
                    .background(Color.white.opacity(0.07))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color(red: 0.75, green: 0.5, blue: 1).opacity(0.35), lineWidth: 1)
                    )
                    .cornerRadius(14)
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
    }

    // MARK: - Streak Footer

    private var streakFooter: some View {
        HStack(spacing: 5) {
            Text("🔥")
            Text(save.streakCount > 0
                 ? "\(save.streakCount)日連続プレイ中！"
                 : "今日もプレイしよう！")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.38))
        }
    }
}

// MARK: - Shared Button Style (used across all views)

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6),
                       value: configuration.isPressed)
    }
}
