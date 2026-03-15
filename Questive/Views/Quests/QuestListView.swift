//
//  QuestListView.swift
//  Questive
//
//  Main quest list with RPG styling and boss battle banner
//

import SwiftUI
import SwiftData

struct QuestListView: View {
    @Binding var showPaywall: Bool
    @Environment(\.modelContext) private var modelContext
    @Environment(PremiumManager.self) private var premiumManager

    @Query(sort: \QuestModel.createdAt) private var quests: [QuestModel]
    @Query private var heroes: [HeroCharacter]
    @Query private var bosses: [BossEncounter]

    @State private var viewModel = QuestViewModel()
    @State private var filterFrequency: QuestFrequency? = nil

    private var hero: HeroCharacter? { heroes.first }
    private var activeBoss: BossEncounter? {
        bosses.first(where: {
            !$0.isDefeated &&
            Calendar.current.isDate($0.weekStartDate, equalTo: Date(), toGranularity: .weekOfYear)
        })
    }

    private var filteredQuests: [QuestModel] {
        quests.filter { q in
            q.isActive && (filterFrequency == nil || q.frequency == filterFrequency)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.purple.opacity(0.15), Color.indigo.opacity(0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Hero stats bar
                        if let hero = hero {
                            HeroStatsBar(hero: hero)
                                .padding(.horizontal)
                        }

                        // Boss battle banner
                        if let boss = activeBoss {
                            BossBattleBanner(boss: boss)
                                .padding(.horizontal)
                        }

                        // Progress section
                        if let hero = hero {
                            DailyProgressCard(quests: quests, hero: hero)
                                .padding(.horizontal)
                        }

                        // Frequency filter
                        FrequencyFilterPicker(selection: $filterFrequency)
                            .padding(.horizontal)

                        // Quest list
                        if filteredQuests.isEmpty {
                            EmptyQuestState(showAdd: $viewModel.showAddQuest)
                                .padding()
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredQuests) { quest in
                                    QuestRowCard(
                                        quest: quest,
                                        isAnimating: viewModel.completionAnimation == quest.id,
                                        onComplete: {
                                            guard let hero = hero else { return }
                                            viewModel.completeQuest(
                                                quest,
                                                hero: hero,
                                                boss: activeBoss,
                                                context: modelContext
                                            )
                                        }
                                    )
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            viewModel.deleteQuest(quest, context: modelContext)
                                        } label: {
                                            Label("Delete Quest", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }

                        // Free tier limit notice
                        if !premiumManager.isPremium {
                            FreeTierBanner(
                                current: quests.filter(\.isActive).count,
                                limit: GameEngine.freeQuestLimit,
                                showPaywall: $showPaywall
                            )
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("⚔️ Quests")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if viewModel.canAddQuest(
                            currentCount: quests.filter(\.isActive).count,
                            isPremium: premiumManager.isPremium
                        ) {
                            viewModel.showAddQuest = true
                        } else {
                            showPaywall = true
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.purple)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showAddQuest) {
                AddQuestView()
            }
        }
    }
}

// MARK: - Hero Stats Bar

struct HeroStatsBar: View {
    let hero: HeroCharacter

    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(hero.heroClass.primaryColor.opacity(0.2))
                    .frame(width: 44, height: 44)
                Text(hero.heroClass.avatarEmoji)
                    .font(.title2)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(hero.heroName)
                        .font(.headline)
                        .fontWeight(.bold)
                    Text("Lv.\(hero.level)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.purple.opacity(0.2))
                        .foregroundStyle(.purple)
                        .clipShape(Capsule())
                }
                // XP bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                        RoundedRectangle(cornerRadius: 4)
                            .fill(LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * hero.xpProgress)
                    }
                }
                .frame(height: 6)
            }

            Spacer()

            // Gold
            HStack(spacing: 4) {
                Text("🪙")
                Text("\(hero.goldBalance)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.yellow)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
        )
    }
}

// MARK: - Boss Battle Banner

struct BossBattleBanner: View {
    let boss: BossEncounter
    @State private var pulse = false

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .scaleEffect(pulse ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: pulse)
                Image(systemName: boss.bossIconName)
                    .font(.title2)
                    .foregroundStyle(.red)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("BOSS: \(boss.bossName)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.red)

                // Boss health bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.red.opacity(0.2))
                        RoundedRectangle(cornerRadius: 4)
                            .fill(LinearGradient(colors: [.orange, .red], startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * (1 - boss.progressFraction))
                    }
                }
                .frame(height: 8)

                Text("\(boss.questsCompleted)/\(boss.totalQuestsRequired) quests to defeat")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack {
                Text("🏆")
                    .font(.title2)
                Text("+\(boss.goldReward)🪙")
                    .font(.caption2)
                    .foregroundStyle(.yellow)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.red.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
        )
        .onAppear { pulse = true }
    }
}

// MARK: - Daily Progress Card

struct DailyProgressCard: View {
    let quests: [QuestModel]
    let hero: HeroCharacter

    private var dailyQuests: [QuestModel] { quests.filter { $0.frequency == .daily && $0.isActive } }
    private var completedToday: Int { dailyQuests.filter(\.isCompletedToday).count }
    private var totalToday: Int { dailyQuests.count }
    private var progress: Double {
        guard totalToday > 0 else { return 0 }
        return Double(completedToday) / Double(totalToday)
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("Today's Progress")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("\(completedToday) / \(totalToday) Quests")
                    .font(.title3)
                    .fontWeight(.bold)

                ProgressView(value: progress)
                    .tint(.purple)
                    .scaleEffect(x: 1, y: 1.5, anchor: .center)
            }

            Spacer()

            ZStack {
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.purple, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .frame(width: 56, height: 56)
                    .rotationEffect(.degrees(-90))
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .fontWeight(.bold)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - Frequency Filter

struct FrequencyFilterPicker: View {
    @Binding var selection: QuestFrequency?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "All", isSelected: selection == nil) {
                    selection = nil
                }
                ForEach(QuestFrequency.allCases, id: \.self) { freq in
                    FilterChip(
                        title: freq.rawValue,
                        icon: freq.icon,
                        isSelected: selection == freq
                    ) {
                        selection = selection == freq ? nil : freq
                    }
                }
            }
        }
    }
}

struct FilterChip: View {
    let title: String
    var icon: String? = nil
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? Color.purple : Color.gray.opacity(0.12))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
    }
}

// MARK: - Quest Row Card

struct QuestRowCard: View {
    let quest: QuestModel
    let isAnimating: Bool
    let onComplete: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(quest.category.color.opacity(0.18))
                    .frame(width: 46, height: 46)
                Image(systemName: quest.iconName)
                    .font(.title3)
                    .foregroundStyle(quest.category.color)
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(quest.title)
                    .font(.headline)
                    .strikethrough(quest.isCompletedForFrequency, color: .gray)
                    .foregroundStyle(quest.isCompletedForFrequency ? .secondary : .primary)

                HStack(spacing: 8) {
                    // Frequency badge
                    Label(quest.frequency.rawValue, systemImage: quest.frequency.icon)
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    // Streak
                    if quest.currentStreakDays > 0 {
                        Label("\(quest.currentStreakDays)🔥", systemImage: "flame")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }

                    // XP reward
                    Text("+\(quest.xpReward)XP")
                        .font(.caption2)
                        .foregroundStyle(.purple)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.purple.opacity(0.12))
                        .clipShape(Capsule())
                }
            }

            Spacer()

            // Complete button
            Button(action: onComplete) {
                ZStack {
                    Circle()
                        .fill(quest.isCompletedForFrequency ? Color.green : Color.gray.opacity(0.2))
                        .frame(width: 36, height: 36)
                        .scaleEffect(isAnimating ? 1.4 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isAnimating)
                    Image(systemName: quest.isCompletedForFrequency ? "checkmark" : "circle")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(quest.isCompletedForFrequency ? .white : .gray)
                }
            }
            .disabled(quest.isCompletedForFrequency)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    isAnimating ? Color.green.opacity(0.6) : Color.clear,
                    lineWidth: 2
                )
        )
    }
}

// MARK: - Empty State

struct EmptyQuestState: View {
    @Binding var showAdd: Bool

    var body: some View {
        VStack(spacing: 20) {
            Text("🗺️")
                .font(.system(size: 64))
            Text("No Quests Yet!")
                .font(.title2)
                .fontWeight(.bold)
            Text("Start your adventure by creating your first quest.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Create First Quest") {
                showAdd = true
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
        }
        .padding(40)
    }
}

// MARK: - Free Tier Banner

struct FreeTierBanner: View {
    let current: Int
    let limit: Int
    @Binding var showPaywall: Bool

    var body: some View {
        HStack {
            Image(systemName: "lock.fill")
                .foregroundStyle(.purple)
            Text("\(current)/\(limit) quests used")
                .font(.subheadline)
            Spacer()
            Button("Upgrade") {
                showPaywall = true
            }
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.purple)
            .clipShape(Capsule())
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.purple.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.purple.opacity(0.25), lineWidth: 1)
                )
        )
    }
}
