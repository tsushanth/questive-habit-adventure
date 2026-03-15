//
//  ContentView.swift
//  Questive
//
//  Root TabView with RPG navigation
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(PremiumManager.self) private var premiumManager
    @Query private var heroes: [HeroCharacter]
    @Query private var quests: [QuestModel]
    @Query private var bosses: [BossEncounter]

    @State private var selectedTab = 0
    @State private var showPaywall = false

    private var hero: HeroCharacter? { heroes.first }

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                QuestListView(showPaywall: $showPaywall)
                    .tabItem {
                        Label("Quests", systemImage: "scroll.fill")
                    }
                    .tag(0)

                CharacterView()
                    .tabItem {
                        Label("Hero", systemImage: "person.fill")
                    }
                    .tag(1)

                ShopView(showPaywall: $showPaywall)
                    .tabItem {
                        Label("Shop", systemImage: "cart.fill")
                    }
                    .tag(2)

                AchievementsView()
                    .tabItem {
                        Label("Feats", systemImage: "trophy.fill")
                    }
                    .tag(3)
            }
            .tint(.purple)
        }
        .sheet(isPresented: $showPaywall) {
            PremiumView()
                .environment(premiumManager)
        }
        .onAppear {
            setupInitialData()
        }
    }

    private func setupInitialData() {
        // Create default hero if none exists
        if heroes.isEmpty {
            let hero = HeroCharacter(heroName: "Hero", heroClass: .warrior)
            modelContext.insert(hero)
        }

        // Seed default quests if none exist
        if quests.isEmpty {
            let defaults: [(String, QuestCategory, String)] = [
                ("Morning Meditation", .mindfulness, "moon.stars.fill"),
                ("Exercise 30 min", .fitness, "figure.run"),
                ("Read 20 pages", .learning, "book.fill"),
                ("Drink 8 glasses of water", .health, "drop.fill"),
                ("Journal entry", .mindfulness, "pencil.and.outline"),
            ]
            for (title, cat, icon) in defaults {
                let q = QuestModel(title: title, iconName: icon, frequency: .daily, category: cat)
                modelContext.insert(q)
            }
        }

        // Generate this week's boss if none active
        let activeBosses = bosses.filter {
            !$0.isDefeated && Calendar.current.isDate($0.weekStartDate, equalTo: Date(), toGranularity: .weekOfYear)
        }
        if activeBosses.isEmpty {
            _ = GameEngine.shared.generateWeeklyBoss(context: modelContext)
        }
    }
}
