import SwiftUI

// MARK: - ResultView

struct ResultView: View {
    let result: GameResult
    var onRetry: () -> Void
    var onMenu: () -> Void
    var onLeaderboard: () -> Void

    @ObservedObject private var save = SaveData.shared
    @State private var animateXP = false

    var body: some View {
        ZStack {
            Color(red: 0.06, green: 0.05, blue: 0.16).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    Spacer().frame(height: 16)
                    scoreHeader
                    breakdownSection
                    xpProgressSection
                    if !result.unlockedAchievements.isEmpty {
                        newAchievementsSection
                    }
                    actionButtons
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 44)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 1.0, dampingFraction: 0.75)) {
                    animateXP = true
                }
            }
        }
    }

    // MARK: - Score Header

    private var scoreHeader: some View {
        VStack(spacing: 10) {
            Text(result.isDaily ? "⚡ デイリー完了！" : "🎯 ゲーム終了")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.4))
                .tracking(3)

            Text("\(result.totalScore)")
                .font(.system(size: 88, weight: .black, design: .rounded))
                .foregroundStyle(LinearGradient(
                    colors: [Color(red: 0.41, green: 0.94, blue: 0.68),
                             Color(red: 0, green: 0.85, blue: 0.9)],
                    startPoint: .leading, endPoint: .trailing
                ))

            Text("ポイント")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.32))

            // Best score info
            let currentBest = save.bestScores[result.difficultyID] ?? 0
            if result.totalScore > 0 && result.totalScore >= currentBest {
                HStack(spacing: 4) {
                    Image(systemName: "trophy.fill")
                    Text("NEW RECORD!")
                }
                .font(.system(size: 13, weight: .black))
                .foregroundColor(Color(red: 1, green: 0.84, blue: 0.25))
                .padding(.horizontal, 14)
                .padding(.vertical, 5)
                .background(Color(red: 1, green: 0.84, blue: 0.25).opacity(0.12))
                .cornerRadius(20)
            }
        }
    }

    // MARK: - Score Breakdown

    private var breakdownSection: some View {
        VStack(spacing: 10) {
            sectionLabel("スコア内訳")

            HStack(spacing: 10) {
                resultTile("🌀", "\(result.laps)", "周回",
                           Color(red: 0.47, green: 0.78, blue: 1))
                resultTile("🔥", "+\(result.bonus)", "ボーナス",
                           Color(red: 1, green: 0.84, blue: 0.25))
                resultTile("💥", "\(result.penalties)", "ペナルティ",
                           Color(red: 1, green: 0.32, blue: 0.32))
            }

            Text("難易度: \(result.difficultyLabel)" + (result.isDaily ? " (DAILY)" : ""))
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.35))
        }
    }

    private func resultTile(_ icon: String, _ value: String, _ label: String, _ color: Color) -> some View {
        VStack(spacing: 5) {
            Text(icon).font(.system(size: 26))
            Text(value)
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.38))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(color.opacity(0.07))
        .cornerRadius(12)
    }

    // MARK: - XP Progress

    private var xpProgressSection: some View {
        VStack(spacing: 10) {
            HStack {
                sectionLabel("獲得XP")
                Spacer()
                Text("+\(result.xpEarned) XP")
                    .font(.system(size: 17, weight: .black))
                    .foregroundColor(Color(red: 0.41, green: 0.94, blue: 0.68))
            }

            VStack(spacing: 6) {
                HStack {
                    Text("Lv.\(save.currentLevel)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.5))
                    Spacer()
                    Text("Lv.\(save.currentLevel + 1)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(red: 0.41, green: 0.94, blue: 0.68))
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.1))
                        Capsule()
                            .fill(LinearGradient(
                                colors: [Color(red: 0.41, green: 0.94, blue: 0.68),
                                         Color(red: 0, green: 0.7, blue: 1)],
                                startPoint: .leading, endPoint: .trailing
                            ))
                            .frame(width: animateXP
                                   ? max(0, geo.size.width * CGFloat(save.levelProgress))
                                   : 0)
                    }
                }
                .frame(height: 10)

                Text("\(save.xpInCurrentLevel) / \(save.xpToNextLevel) XP")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.35))
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(14)
    }

    // MARK: - Unlocked Achievements

    private var newAchievementsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("🎉 実績解除！")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Color(red: 1, green: 0.84, blue: 0.25))

            ForEach(result.unlockedAchievements) { a in
                HStack(spacing: 10) {
                    Text(a.icon).font(.system(size: 26))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(a.name)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                        Text(a.desc)
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    Spacer()
                    Text("NEW!")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(Color(red: 1, green: 0.84, blue: 0.25))
                }
                .padding(12)
                .background(Color(red: 1, green: 0.84, blue: 0.25).opacity(0.08))
                .cornerRadius(10)
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.03))
        .cornerRadius(14)
    }

    // MARK: - Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: onRetry) {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("もう一度")
                }
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(LinearGradient(
                    colors: [Color(red: 0.41, green: 0.94, blue: 0.68),
                             Color(red: 0, green: 0.85, blue: 0.9)],
                    startPoint: .leading, endPoint: .trailing
                ))
                .cornerRadius(16)
                .shadow(color: Color(red: 0.41, green: 0.94, blue: 0.68).opacity(0.4), radius: 12, y: 4)
            }
            .buttonStyle(ScaleButtonStyle())

            HStack(spacing: 10) {
                smallButton("house.fill", "メニュー", action: onMenu)
                smallButton("square.and.arrow.up", "シェア", action: shareResult)
                smallButton("chart.bar.fill", "記録", action: onLeaderboard)
            }
        }
    }

    private func smallButton(_ icon: String, _ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 17))
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.white.opacity(0.08))
            .cornerRadius(12)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .bold))
            .foregroundColor(.white.opacity(0.5))
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func shareResult() {
        let text = """
        🎯 まわれ！タイムアタック
        \(result.difficultyLabel) で \(result.totalScore)ポイント達成！
        現在 Lv.\(save.currentLevel)
        #まわれ #NippleTrace
        """
        guard let vc = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow })?.rootViewController
        else { return }

        let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let pop = av.popoverPresentationController {
            pop.sourceView = vc.view
            pop.sourceRect = CGRect(x: vc.view.bounds.midX,
                                    y: vc.view.bounds.maxY - 100,
                                    width: 0, height: 0)
        }
        vc.present(av, animated: true)
    }
}
