//
//  QuestViewModel.swift
//  Questive
//
//  ViewModel for quest list and management
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class QuestViewModel {
    var showAddQuest = false
    var showPremiumPaywall = false
    var completionAnimation: UUID? = nil
    var errorMessage: String?

    func completeQuest(
        _ quest: QuestModel,
        hero: HeroCharacter,
        boss: BossEncounter?,
        context: ModelContext
    ) {
        guard !quest.isCompletedForFrequency else { return }
        GameEngine.shared.completeQuest(quest, hero: hero, boss: boss, context: context)
        completionAnimation = quest.id
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            self.completionAnimation = nil
        }
    }

    func deleteQuest(_ quest: QuestModel, context: ModelContext) {
        context.delete(quest)
    }

    func canAddQuest(currentCount: Int, isPremium: Bool) -> Bool {
        isPremium || currentCount < GameEngine.freeQuestLimit
    }

    func questsGroupedByCategory(_ quests: [QuestModel]) -> [(QuestCategory, [QuestModel])] {
        let grouped = Dictionary(grouping: quests, by: { $0.category })
        return QuestCategory.allCases.compactMap { cat in
            guard let items = grouped[cat], !items.isEmpty else { return nil }
            return (cat, items)
        }
    }

    func todayProgress(from quests: [QuestModel]) -> (completed: Int, total: Int) {
        let dailyQuests = quests.filter { $0.frequency == .daily && $0.isActive }
        let completed = dailyQuests.filter { $0.isCompletedToday }.count
        return (completed, dailyQuests.count)
    }
}
