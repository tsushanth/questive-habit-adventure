//
//  Models.swift
//  Questive
//
//  SwiftData models for Questive: Habit Adventure
//

import Foundation
import SwiftUI
import SwiftData

// MARK: - SwiftData Models

@Model
final class QuestModel {
    var id: UUID
    var title: String
    var questDescription: String
    var iconName: String
    var colorHex: String
    var frequencyRaw: String
    var categoryRaw: String
    var xpReward: Int
    var goldReward: Int
    var isActive: Bool
    var createdAt: Date
    var completionCount: Int
    var currentStreakDays: Int
    var bestStreakDays: Int
    var targetDays: Int
    var lastCompletedAt: Date?
    var isChainQuest: Bool
    var chainIndex: Int
    var chainTitle: String

    @Relationship(deleteRule: .cascade)
    var entries: [HabitEntryModel] = []

    var frequency: QuestFrequency {
        get { QuestFrequency(rawValue: frequencyRaw) ?? .daily }
        set { frequencyRaw = newValue.rawValue }
    }

    var category: QuestCategory {
        get { QuestCategory(rawValue: categoryRaw) ?? .health }
        set { categoryRaw = newValue.rawValue }
    }

    var isCompletedToday: Bool {
        guard let last = lastCompletedAt else { return false }
        return Calendar.current.isDateInToday(last)
    }

    var isCompletedThisWeek: Bool {
        guard let last = lastCompletedAt else { return false }
        return Calendar.current.isDate(last, equalTo: Date(), toGranularity: .weekOfYear)
    }

    var isCompletedForFrequency: Bool {
        switch frequency {
        case .daily: return isCompletedToday
        case .weekly: return isCompletedThisWeek
        }
    }

    init(
        title: String,
        questDescription: String = "",
        iconName: String = "star.fill",
        colorHex: String = "#7C3AED",
        frequency: QuestFrequency = .daily,
        category: QuestCategory = .health,
        xpReward: Int = 50,
        goldReward: Int = 10,
        isChainQuest: Bool = false,
        chainIndex: Int = 0,
        chainTitle: String = ""
    ) {
        self.id = UUID()
        self.title = title
        self.questDescription = questDescription
        self.iconName = iconName
        self.colorHex = colorHex
        self.frequencyRaw = frequency.rawValue
        self.categoryRaw = category.rawValue
        self.xpReward = xpReward
        self.goldReward = goldReward
        self.isActive = true
        self.createdAt = Date()
        self.completionCount = 0
        self.currentStreakDays = 0
        self.bestStreakDays = 0
        self.targetDays = 30
        self.lastCompletedAt = nil
        self.isChainQuest = isChainQuest
        self.chainIndex = chainIndex
        self.chainTitle = chainTitle
    }
}

@Model
final class HabitEntryModel {
    var id: UUID
    var completedAt: Date
    var xpEarned: Int
    var goldEarned: Int
    var noteText: String

    init(completedAt: Date = Date(), xpEarned: Int = 50, goldEarned: Int = 10, noteText: String = "") {
        self.id = UUID()
        self.completedAt = completedAt
        self.xpEarned = xpEarned
        self.goldEarned = goldEarned
        self.noteText = noteText
    }
}

@Model
final class HeroCharacter {
    var id: UUID
    var heroName: String
    var level: Int
    var currentXP: Int
    var totalXP: Int
    var goldBalance: Int
    var classRaw: String
    var equippedHatID: String?
    var equippedArmorID: String?
    var equippedWeaponID: String?
    var equippedPetID: String?
    var createdAt: Date
    var totalQuestsCompleted: Int
    var totalBossesDefeated: Int

    var heroClass: HeroClass {
        get { HeroClass(rawValue: classRaw) ?? .warrior }
        set { classRaw = newValue.rawValue }
    }

    var xpForNextLevel: Int {
        level * 100 + 50
    }

    var xpProgress: Double {
        let xpInCurrentLevel = currentXP - xpForPreviousLevels
        let xpNeeded = xpForNextLevel - xpForPreviousLevels
        guard xpNeeded > 0 else { return 1.0 }
        return min(1.0, Double(xpInCurrentLevel) / Double(xpNeeded))
    }

    private var xpForPreviousLevels: Int {
        // Sum of XP required for all levels before current
        var total = 0
        for lvl in 1..<level {
            total += lvl * 100 + 50
        }
        return total
    }

    init(heroName: String = "Hero", heroClass: HeroClass = .warrior) {
        self.id = UUID()
        self.heroName = heroName
        self.level = 1
        self.currentXP = 0
        self.totalXP = 0
        self.goldBalance = 100
        self.classRaw = heroClass.rawValue
        self.equippedHatID = nil
        self.equippedArmorID = nil
        self.equippedWeaponID = nil
        self.equippedPetID = nil
        self.createdAt = Date()
        self.totalQuestsCompleted = 0
        self.totalBossesDefeated = 0
    }

    func addXP(_ amount: Int) {
        currentXP += amount
        totalXP += amount
        // Level up check
        while currentXP >= xpForNextLevel {
            currentXP -= xpForNextLevel
            level += 1
        }
    }

    func addGold(_ amount: Int) {
        goldBalance += amount
    }

    func spendGold(_ amount: Int) -> Bool {
        guard goldBalance >= amount else { return false }
        goldBalance -= amount
        return true
    }
}

@Model
final class InventoryItemModel {
    var id: UUID
    var itemID: String
    var purchasedAt: Date
    var isEquipped: Bool
    var slotRaw: String

    var slot: ItemSlot {
        get { ItemSlot(rawValue: slotRaw) ?? .hat }
        set { slotRaw = newValue.rawValue }
    }

    init(itemID: String, slot: ItemSlot) {
        self.id = UUID()
        self.itemID = itemID
        self.purchasedAt = Date()
        self.isEquipped = false
        self.slotRaw = slot.rawValue
    }
}

@Model
final class AchievementRecord {
    var id: UUID
    var achievementID: String
    var unlockedAt: Date
    var notified: Bool

    init(achievementID: String) {
        self.id = UUID()
        self.achievementID = achievementID
        self.unlockedAt = Date()
        self.notified = false
    }
}

@Model
final class BossEncounter {
    var id: UUID
    var bossName: String
    var bossIconName: String
    var weekStartDate: Date
    var totalQuestsRequired: Int
    var questsCompleted: Int
    var isDefeated: Bool
    var defeatedAt: Date?
    var goldReward: Int
    var xpReward: Int

    var progressFraction: Double {
        guard totalQuestsRequired > 0 else { return 0 }
        return min(1.0, Double(questsCompleted) / Double(totalQuestsRequired))
    }

    init(
        bossName: String,
        bossIconName: String = "flame.fill",
        weekStartDate: Date = Date(),
        totalQuestsRequired: Int = 7,
        goldReward: Int = 200,
        xpReward: Int = 500
    ) {
        self.id = UUID()
        self.bossName = bossName
        self.bossIconName = bossIconName
        self.weekStartDate = weekStartDate
        self.totalQuestsRequired = totalQuestsRequired
        self.questsCompleted = 0
        self.isDefeated = false
        self.defeatedAt = nil
        self.goldReward = goldReward
        self.xpReward = xpReward
    }
}

// MARK: - Enums

enum QuestFrequency: String, Codable, CaseIterable {
    case daily = "Daily"
    case weekly = "Weekly"

    var icon: String {
        switch self {
        case .daily: return "sun.max.fill"
        case .weekly: return "calendar.badge.clock"
        }
    }
}

enum QuestCategory: String, Codable, CaseIterable {
    case health = "Health"
    case fitness = "Fitness"
    case mindfulness = "Mindfulness"
    case learning = "Learning"
    case social = "Social"
    case productivity = "Productivity"
    case creativity = "Creativity"
    case finance = "Finance"

    var icon: String {
        switch self {
        case .health: return "heart.fill"
        case .fitness: return "figure.run"
        case .mindfulness: return "brain.head.profile"
        case .learning: return "book.fill"
        case .social: return "person.2.fill"
        case .productivity: return "checkmark.circle.fill"
        case .creativity: return "paintbrush.fill"
        case .finance: return "banknote.fill"
        }
    }

    var color: Color {
        switch self {
        case .health: return .red
        case .fitness: return .orange
        case .mindfulness: return .blue
        case .learning: return .indigo
        case .social: return .pink
        case .productivity: return .green
        case .creativity: return .purple
        case .finance: return .yellow
        }
    }
}

enum HeroClass: String, Codable, CaseIterable {
    case warrior = "Warrior"
    case mage = "Mage"
    case rogue = "Rogue"
    case paladin = "Paladin"

    var icon: String {
        switch self {
        case .warrior: return "shield.fill"
        case .mage: return "wand.and.stars"
        case .rogue: return "eye.slash.fill"
        case .paladin: return "cross.fill"
        }
    }

    var avatarEmoji: String {
        switch self {
        case .warrior: return "⚔️"
        case .mage: return "🧙"
        case .rogue: return "🗡️"
        case .paladin: return "🛡️"
        }
    }

    var primaryColor: Color {
        switch self {
        case .warrior: return .red
        case .mage: return .purple
        case .rogue: return .gray
        case .paladin: return .yellow
        }
    }

    var bonusDescription: String {
        switch self {
        case .warrior: return "+20% XP from Fitness quests"
        case .mage: return "+20% XP from Learning quests"
        case .rogue: return "+20% Gold from all quests"
        case .paladin: return "+20% XP from Mindfulness quests"
        }
    }
}

enum ItemSlot: String, Codable, CaseIterable {
    case hat = "Hat"
    case armor = "Armor"
    case weapon = "Weapon"
    case pet = "Pet"

    var icon: String {
        switch self {
        case .hat: return "crown.fill"
        case .armor: return "shield.fill"
        case .weapon: return "bolt.fill"
        case .pet: return "pawprint.fill"
        }
    }
}

// MARK: - Non-persisted Shop Item

struct ShopItemDefinition: Identifiable {
    let id: String
    let name: String
    let description: String
    let iconEmoji: String
    let slot: ItemSlot
    let goldCost: Int
    let isPremium: Bool
    let rarityRaw: String

    var rarity: ItemRarity {
        ItemRarity(rawValue: rarityRaw) ?? .common
    }

    init(
        id: String,
        name: String,
        description: String,
        iconEmoji: String,
        slot: ItemSlot,
        goldCost: Int,
        isPremium: Bool = false,
        rarity: ItemRarity = .common
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.iconEmoji = iconEmoji
        self.slot = slot
        self.goldCost = goldCost
        self.isPremium = isPremium
        self.rarityRaw = rarity.rawValue
    }
}

enum ItemRarity: String, CaseIterable {
    case common = "Common"
    case rare = "Rare"
    case epic = "Epic"
    case legendary = "Legendary"

    var color: Color {
        switch self {
        case .common: return .gray
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return .orange
        }
    }
}

// MARK: - Achievement Definition

struct AchievementDefinition: Identifiable {
    let id: String
    let title: String
    let description: String
    let iconName: String
    let xpBonus: Int
    let goldBonus: Int
    let isPremium: Bool

    init(
        id: String,
        title: String,
        description: String,
        iconName: String,
        xpBonus: Int = 100,
        goldBonus: Int = 50,
        isPremium: Bool = false
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.iconName = iconName
        self.xpBonus = xpBonus
        self.goldBonus = goldBonus
        self.isPremium = isPremium
    }
}
