import SwiftUI

// MARK: - DifficultyView

struct DifficultyView: View {
    var showDaily: Bool = false
    var onBack: () -> Void
    var onSelect: (DifficultyConfig, Bool) -> Void

    @ObservedObject private var save = SaveData.shared

    var body: some View {
        ZStack {
            Color(red: 0.06, green: 0.05, blue: 0.16).ignoresSafeArea()

            VStack(spacing: 0) {
                navigationBar

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        if showDaily {
                            dailyChallengeCard
                            Divider()
                                .background(Color.white.opacity(0.08))
                                .padding(.vertical, 4)
                        }

                        Text("難易度を選択")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white.opacity(0.45))
                            .frame(maxWidth: .infinity, alignment: .leading)

                        ForEach(DifficultyConfig.all, id: \.id) { cfg in
                            DifficultyCard(
                                config: cfg,
                                bestScore: save.bestScores[cfg.id]
                            ) {
                                onSelect(cfg, false)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
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
            Text(showDaily ? "デイリーチャレンジ" : "難易度選択")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Spacer()
            Color.clear.frame(width: 60, height: 1)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
    }

    // MARK: - Daily Challenge Card

    private var dailyChallengeCard: some View {
        let daily = DailyChallenge.today()
        let cfg = daily.resolve()
        let completed = save.dailyCompletedDate == save.todayString()

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("⚡ 今日のデイリーチャレンジ")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(red: 1, green: 0.84, blue: 0.25))
                Spacer()
                if completed {
                    Text("✅ 完了")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.green)
                }
            }

            Button(action: { onSelect(cfg, true) }) {
                HStack(spacing: 14) {
                    Text(daily.icon)
                        .font(.system(size: 40))

                    VStack(alignment: .leading, spacing: 5) {
                        Text(daily.name)
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                        Text(daily.desc)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.55))
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                        if !daily.bonusDesc.isEmpty {
                            Text(daily.bonusDesc)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Color(red: 0.41, green: 0.94, blue: 0.68))
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("XP×\(String(format: "%.1f", cfg.xpMult))")
                            .font(.system(size: 13, weight: .black))
                            .foregroundColor(Color(red: 1, green: 0.84, blue: 0.25))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.3))
                    }
                }
                .padding(16)
                .background(
                    LinearGradient(
                        colors: [Color(red: 0.32, green: 0.23, blue: 0.04),
                                 Color(red: 0.11, green: 0.08, blue: 0.01)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(red: 1, green: 0.84, blue: 0.25).opacity(0.45), lineWidth: 1.5)
                )
                .cornerRadius(16)
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }
}

// MARK: - DifficultyCard

struct DifficultyCard: View {
    let config: DifficultyConfig
    let bestScore: Int?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                Text(config.emoji)
                    .font(.system(size: 38))

                VStack(alignment: .leading, spacing: 5) {
                    Text(config.label)
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundColor(.white)

                    HStack(spacing: 10) {
                        Label("\(Int(config.time))秒", systemImage: "clock.fill")
                        Label("-\(Int(config.penalty))秒", systemImage: "xmark.circle.fill")
                        Label("×\(String(format: "%.1f", config.xpMult)) XP", systemImage: "star.fill")
                    }
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.43))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    if let best = bestScore {
                        Text("🏆 \(best)")
                            .font(.system(size: 15, weight: .black))
                            .foregroundColor(config.swiftUIColor)
                        Text("最高")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.35))
                    } else {
                        Text("未プレイ")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.28))
                    }
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.25))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [config.swiftUIColor.opacity(0.12),
                             config.swiftUIColor.opacity(0.04)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(config.swiftUIColor.opacity(0.28), lineWidth: 1)
            )
            .cornerRadius(14)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
