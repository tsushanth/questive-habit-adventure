//
//  PremiumManager.swift
//  Questive
//
//  Manages premium feature access and RevenueCat integration stub
//

import Foundation
import StoreKit

// MARK: - Premium Feature

enum QuestivePremiumFeature: String, CaseIterable, Identifiable {
    case unlimitedQuests = "unlimited_quests"
    case bossRaids = "boss_raids"
    case guildFeatures = "guild_features"
    case premiumCosmetics = "premium_cosmetics"
    case advancedStats = "advanced_stats"

    var id: String { rawValue }
    var isPremium: Bool { true }

    var displayName: String {
        switch self {
        case .unlimitedQuests: return "Unlimited Quests"
        case .bossRaids: return "Boss Raids"
        case .guildFeatures: return "Guild Features"
        case .premiumCosmetics: return "Premium Cosmetics"
        case .advancedStats: return "Advanced Stats"
        }
    }

    var description: String {
        switch self {
        case .unlimitedQuests: return "Create as many quests as you want"
        case .bossRaids: return "Take on epic weekly boss challenges"
        case .guildFeatures: return "Join and create guilds with friends"
        case .premiumCosmetics: return "Access exclusive character items"
        case .advancedStats: return "Deep analytics on your habits"
        }
    }

    var icon: String {
        switch self {
        case .unlimitedQuests: return "infinity"
        case .bossRaids: return "flame.fill"
        case .guildFeatures: return "person.3.fill"
        case .premiumCosmetics: return "paintpalette.fill"
        case .advancedStats: return "chart.line.uptrend.xyaxis"
        }
    }
}

// MARK: - Premium Manager

@MainActor
@Observable
final class PremiumManager {
    private let storeKitManager: StoreKitManager
    private let userDefaults: UserDefaults

    private enum Keys {
        static let isPremium = "com.appfactory.questive.isPremium"
        static let hasSeenPaywall = "com.appfactory.questive.hasSeenPaywall"
        static let lastPaywallDate = "com.appfactory.questive.lastPaywallDate"
    }

    var isPremium: Bool { storeKitManager.isPremium }
    var hasActiveSubscription: Bool { storeKitManager.hasActiveSubscription }
    var purchaseState: PurchaseState { storeKitManager.purchaseState }
    var isLoading: Bool { storeKitManager.isLoading }
    var errorMessage: String? { storeKitManager.errorMessage }
    var subscriptions: [Product] { storeKitManager.subscriptions }

    var hasSeenPaywall: Bool {
        get { userDefaults.bool(forKey: Keys.hasSeenPaywall) }
        set { userDefaults.set(newValue, forKey: Keys.hasSeenPaywall) }
    }

    var lastPaywallDate: Date? {
        get { userDefaults.object(forKey: Keys.lastPaywallDate) as? Date }
        set { userDefaults.set(newValue, forKey: Keys.lastPaywallDate) }
    }

    init(storeKitManager: StoreKitManager? = nil, userDefaults: UserDefaults = .standard) {
        self.storeKitManager = storeKitManager ?? StoreKitManager()
        self.userDefaults = userDefaults
        Task { await refreshPremiumStatus() }
    }

    func canAccess(_ feature: QuestivePremiumFeature) -> Bool {
        isPremium
    }

    func requiresPremium(_ feature: QuestivePremiumFeature) -> Bool {
        !canAccess(feature)
    }

    func purchase(_ product: Product) async throws {
        _ = try await storeKitManager.purchase(product)
    }

    func restorePurchases() async {
        await storeKitManager.restorePurchases()
    }

    func refreshPremiumStatus() async {
        await storeKitManager.updatePurchasedProducts()
    }

    func shouldShowPaywall() -> Bool {
        guard !isPremium else { return false }
        if !hasSeenPaywall { return true }
        if let last = lastPaywallDate {
            return Date().timeIntervalSince(last) > 86400
        }
        return true
    }

    func recordPaywallShown() {
        hasSeenPaywall = true
        lastPaywallDate = Date()
    }
}
