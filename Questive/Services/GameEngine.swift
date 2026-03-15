//
//  GameEngine.swift
//  Questive
//
//  Core RPG game logic: XP, leveling, gold, boss battles
//

import Foundation
import SwiftData

@MainActor
final class GameEngine {
    static let shared = GameEngine()
    private init() {}

    // MARK: - Free Tier Limit

    static let freeQuestLimit = 5

    // MARK: - XP Tables

    static let baseXPPerQuest = 50
    static let streakBonusMultiplier: Double = 0.1 // +10% per streak day, capped at 3x

    // MARK: - Complete Quest

    func completeQuest(
        _ quest: QuestModel,
        hero: HeroCharacter,
        boss: BossEncounter?,
        context: ModelContext
    ) {
        guard !quest.isCompletedForFrequency else { return }

        // Calculate rewards
        let streakBonus = min(1.0 + Double(quest.currentStreakDays) * Self.streakBonusMultiplier, 3.0)
        let xp = Int(Double(quest.xpReward) * streakBonus)
        let gold = quest.goldReward

        // Record entry
        let entry = HabitEntryModel(completedAt: Date(), xpEarned: xp, goldEarned: gold)
        quest.entries.append(entry)

        // Update quest stats
        quest.completionCount += 1
        quest.lastCompletedAt = Date()

        // Update streak
        if let prev = quest.entries.dropLast().last?.completedAt {
            let daysSince = Calendar.current.dateComponents([.day], from: prev, to: Date()).day ?? 0
            if daysSince <= 1 {
                quest.currentStreakDays += 1
            } else {
                quest.currentStreakDays = 1
            }
        } else {
            quest.currentStreakDays = 1
        }
        quest.bestStreakDays = max(quest.bestStreakDays, quest.currentStreakDays)

        // Award hero
        let previousLevel = hero.level
        hero.addXP(xp)
        hero.addGold(gold)
        hero.totalQuestsCompleted += 1

        // Analytics
        AnalyticsService.shared.track(.questCompleted(questID: quest.id.uuidString, xpEarned: xp))
        if hero.level > previousLevel {
            AnalyticsService.shared.track(.levelUp(newLevel: hero.level))
        }

        // Boss progress
        if let boss = boss, !boss.isDefeated {
            boss.questsCompleted += 1
            if boss.questsCompleted >= boss.totalQuestsRequired {
                boss.isDefeated = true
                boss.defeatedAt = Date()
                hero.addXP(boss.xpReward)
                hero.addGold(boss.goldReward)
                hero.totalBossesDefeated += 1
                AnalyticsService.shared.track(.bossDefeated(bossName: boss.bossName))
            }
        }
    }

    // MARK: - Shop Purchase

    func purchaseItem(
        _ item: ShopItemDefinition,
        hero: HeroCharacter,
        context: ModelContext
    ) -> Bool {
        guard hero.spendGold(item.goldCost) else { return false }
        let inventoryItem = InventoryItemModel(itemID: item.id, slot: item.slot)
        context.insert(inventoryItem)
        AnalyticsService.shared.track(.itemPurchased(itemID: item.id, goldSpent: item.goldCost))
        return true
    }

    // MARK: - Boss of the Week

    func generateWeeklyBoss(context: ModelContext) -> BossEncounter {
        let bosses = [
            ("Shadow Dragon", "dragon", 10, 300, 750),
            ("Iron Golem", "shield.lefthalf.filled", 7, 200, 500),
            ("Void Witch", "moon.stars.fill", 8, 250, 600),
            ("Storm Giant", "cloud.bolt.fill", 12, 400, 1000),
            ("Necromancer", "skull.fill", 9, 280, 700),
        ]
        let pick = bosses.randomElement()!
        let boss = BossEncounter(
            bossName: pick.0,
            bossIconName: pick.1,
            weekStartDate: Date(),
            totalQuestsRequired: pick.2,
            goldReward: pick.3,
            xpReward: pick.4
        )
        context.insert(boss)
        return boss
    }

    // MARK: - Shop Catalog

    static let shopCatalog: [ShopItemDefinition] = [
        // Hats
        ShopItemDefinition(id: "hat_crown", name: "Gold Crown", description: "Fit for royalty", iconEmoji: "👑", slot: .hat, goldCost: 150, isPremium: false, rarity: .rare),
        ShopItemDefinition(id: "hat_wizard", name: "Wizard Hat", description: "Ancient mystical power", iconEmoji: "🎩", slot: .hat, goldCost: 200, isPremium: false, rarity: .rare),
        ShopItemDefinition(id: "hat_hero", name: "Hero Helm", description: "Legendary armor crest", iconEmoji: "⛑️", slot: .hat, goldCost: 500, isPremium: true, rarity: .legendary),

        // Armor
        ShopItemDefinition(id: "armor_leather", name: "Leather Vest", description: "Light and flexible", iconEmoji: "🧥", slot: .armor, goldCost: 120, isPremium: false, rarity: .common),
        ShopItemDefinition(id: "armor_chain", name: "Chainmail", description: "Solid protection", iconEmoji: "🛡️", slot: .armor, goldCost: 250, isPremium: false, rarity: .rare),
        ShopItemDefinition(id: "armor_dragon", name: "Dragon Scale", description: "Forged from dragon hide", iconEmoji: "🐲", slot: .armor, goldCost: 800, isPremium: true, rarity: .legendary),

        // Weapons
        ShopItemDefinition(id: "weapon_sword", name: "Iron Sword", description: "Trusty blade", iconEmoji: "⚔️", slot: .weapon, goldCost: 100, isPremium: false, rarity: .common),
        ShopItemDefinition(id: "weapon_staff", name: "Mystic Staff", description: "Channels arcane energy", iconEmoji: "🪄", slot: .weapon, goldCost: 300, isPremium: false, rarity: .epic),
        ShopItemDefinition(id: "weapon_lightning", name: "Thunder Spear", description: "Crackles with lightning", iconEmoji: "⚡", slot: .weapon, goldCost: 600, isPremium: true, rarity: .legendary),

        // Pets
        ShopItemDefinition(id: "pet_cat", name: "Lucky Cat", description: "Brings good fortune", iconEmoji: "🐱", slot: .pet, goldCost: 200, isPremium: false, rarity: .common),
        ShopItemDefinition(id: "pet_dragon", name: "Mini Dragon", description: "A tiny fire-breather", iconEmoji: "🐉", slot: .pet, goldCost: 400, isPremium: true, rarity: .epic),
        ShopItemDefinition(id: "pet_phoenix", name: "Phoenix Chick", description: "Born from the ashes", iconEmoji: "🦅", slot: .pet, goldCost: 700, isPremium: true, rarity: .legendary),
    ]

    // MARK: - Achievement Catalog

    static let achievementCatalog: [AchievementDefinition] = [
        AchievementDefinition(id: "first_quest", title: "First Steps", description: "Complete your first quest", iconName: "star.fill", xpBonus: 100, goldBonus: 50),
        AchievementDefinition(id: "quest_10", title: "Getting Serious", description: "Complete 10 quests", iconName: "flame.fill", xpBonus: 200, goldBonus: 100),
        AchievementDefinition(id: "quest_100", title: "Century Hero", description: "Complete 100 quests", iconName: "trophy.fill", xpBonus: 500, goldBonus: 250),
        AchievementDefinition(id: "streak_7", title: "Week Warrior", description: "7-day streak on any quest", iconName: "calendar.badge.checkmark", xpBonus: 300, goldBonus: 150),
        AchievementDefinition(id: "streak_30", title: "Month Master", description: "30-day streak on any quest", iconName: "crown.fill", xpBonus: 1000, goldBonus: 500),
        AchievementDefinition(id: "level_5", title: "Rising Hero", description: "Reach level 5", iconName: "arrow.up.circle.fill", xpBonus: 200, goldBonus: 100),
        AchievementDefinition(id: "level_10", title: "Seasoned Adventurer", description: "Reach level 10", iconName: "medal.fill", xpBonus: 500, goldBonus: 250),
        AchievementDefinition(id: "boss_first", title: "Boss Slayer", description: "Defeat your first boss", iconName: "flame.fill", xpBonus: 400, goldBonus: 200, isPremium: true),
        AchievementDefinition(id: "shop_first", title: "Shopkeeper's Favorite", description: "Purchase your first item", iconName: "cart.fill", xpBonus: 100, goldBonus: 50),
    ]
}
