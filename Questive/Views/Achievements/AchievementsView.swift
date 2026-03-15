//
//  AchievementsView.swift
//  Questive
//
//  Achievements and feats display
//

import SwiftUI
import SwiftData

struct AchievementsView: View {
    @Query private var heroes: [HeroCharacter]
    @Query private var achievementRecords: [AchievementRecord]
    @Query private var quests: [QuestModel]

    private var hero: HeroCharacter? { heroes.first }
    private var unlockedIDs: Set<String> { Set(achievementRecords.map(\.achievementID)) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Summary banner
                    if let hero = hero {
                        AchievementSummaryBanner(
                            unlocked: unlockedIDs.count,
                            total: GameEngine.achievementCatalog.count,
                            hero: hero
                        )
                        .padding(.horizontal)
                    }

                    // Achievement list
                    LazyVStack(spacing: 12) {
                        ForEach(GameEngine.achievementCatalog) { achievement in
                            AchievementRow(
                                achievement: achievement,
                                isUnlocked: unlockedIDs.contains(achievement.id),
                                hero: hero,
                                quests: quests
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 30)
                .padding(.top, 10)
            }
            .background(
                LinearGradient(
                    colors: [Color.orange.opacity(0.08), Color.yellow.opacity(0.04)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("🏆 Feats")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Summary Banner

struct AchievementSummaryBanner: View {
    let unlocked: Int
    let total: Int
    let hero: HeroCharacter

    private var progress: Double {
        guard total > 0 else { return 0 }
        return Double(unlocked) / Double(total)
    }

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Achievements")
                    .font(.headline)
                Text("\(unlocked) / \(total) unlocked")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                ProgressView(value: progress)
                    .tint(.orange)
            }

            ZStack {
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.orange, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                Text("🏆")
                    .font(.title2)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - Achievement Row

struct AchievementRow: View {
    let achievement: AchievementDefinition
    let isUnlocked: Bool
    let hero: HeroCharacter?
    let quests: [QuestModel]

    var body: some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(isUnlocked ? Color.orange.opacity(0.2) : Color.gray.opacity(0.1))
                    .frame(width: 52, height: 52)
                Image(systemName: achievement.iconName)
                    .font(.title2)
                    .foregroundStyle(isUnlocked ? .orange : .gray)
                    .opacity(isUnlocked ? 1.0 : 0.4)

                if !isUnlocked {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(.gray)
                        .offset(x: 16, y: 16)
                }
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(achievement.title)
                        .font(.headline)
                        .foregroundStyle(isUnlocked ? .primary : .secondary)
                    if achievement.isPremium {
                        Text("PRO")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.purple.opacity(0.2))
                            .foregroundStyle(.purple)
                            .clipShape(Capsule())
                    }
                }
                Text(achievement.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if isUnlocked {
                    HStack(spacing: 10) {
                        Label("+\(achievement.xpBonus)XP", systemImage: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.purple)
                        Label("+\(achievement.goldBonus)🪙", systemImage: "coins.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                    }
                }
            }

            Spacer()

            if isUnlocked {
                Image(systemName: "checkmark.seal.fill")
                    .font(.title3)
                    .foregroundStyle(.orange)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
        )
        .opacity(isUnlocked ? 1.0 : 0.75)
    }
}
