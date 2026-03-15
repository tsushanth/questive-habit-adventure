//
//  QuestiveApp.swift
//  Questive
//
//  App entry point — Questive: Habit Adventure
//  Architecture follows CycleWise patterns: SwiftData, StoreKit 2, MVVM, ATT
//

import SwiftUI
import SwiftData

@main
struct QuestiveApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    let modelContainer: ModelContainer
    @State private var premiumManager = PremiumManager()

    init() {
        do {
            let schema = Schema([
                QuestModel.self,
                HabitEntryModel.self,
                HeroCharacter.self,
                InventoryItemModel.self,
                AchievementRecord.self,
                BossEncounter.self,
            ])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(premiumManager)
                .onAppear {
                    Task {
                        await premiumManager.refreshPremiumStatus()
                    }
                }
        }
        .modelContainer(modelContainer)
    }
}
