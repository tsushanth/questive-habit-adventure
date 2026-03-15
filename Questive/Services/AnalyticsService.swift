//
//  AnalyticsService.swift
//  Questive
//
//  Analytics events stub - ready for Firebase Analytics integration
//

import Foundation

enum QuestiveAnalyticsEvent {
    case appOpen
    case questCompleted(questID: String, xpEarned: Int)
    case questCreated(category: String)
    case questDeleted
    case levelUp(newLevel: Int)
    case itemPurchased(itemID: String, goldSpent: Int)
    case bossDefeated(bossName: String)
    case paywallViewed(trigger: String)
    case paywallDismissed
    case subscriptionPurchased(productID: String)
    case subscriptionRestored
    case screenView(name: String)

    var name: String {
        switch self {
        case .appOpen: return "app_open"
        case .questCompleted: return "quest_completed"
        case .questCreated: return "quest_created"
        case .questDeleted: return "quest_deleted"
        case .levelUp: return "level_up"
        case .itemPurchased: return "item_purchased"
        case .bossDefeated: return "boss_defeated"
        case .paywallViewed: return "paywall_viewed"
        case .paywallDismissed: return "paywall_dismissed"
        case .subscriptionPurchased: return "subscription_purchased"
        case .subscriptionRestored: return "subscription_restored"
        case .screenView: return "screen_view"
        }
    }

    var parameters: [String: Any] {
        switch self {
        case .questCompleted(let id, let xp):
            return ["quest_id": id, "xp_earned": xp]
        case .questCreated(let cat):
            return ["category": cat]
        case .levelUp(let lvl):
            return ["new_level": lvl]
        case .itemPurchased(let id, let gold):
            return ["item_id": id, "gold_spent": gold]
        case .bossDefeated(let name):
            return ["boss_name": name]
        case .paywallViewed(let trigger):
            return ["trigger": trigger]
        case .subscriptionPurchased(let id):
            return ["product_id": id]
        case .screenView(let name):
            return ["screen_name": name]
        default:
            return [:]
        }
    }
}

@MainActor
final class AnalyticsService {
    static let shared = AnalyticsService()
    private var isInitialized = false
    private init() {}

    func initialize() {
        guard !isInitialized else { return }
        isInitialized = true
        // TODO: FirebaseApp.configure() — add GoogleService-Info.plist
        #if DEBUG
        print("[Analytics] Initialized")
        #endif
    }

    func track(_ event: QuestiveAnalyticsEvent) {
        #if DEBUG
        print("[Analytics] \(event.name): \(event.parameters)")
        #endif
        // TODO: Analytics.logEvent(event.name, parameters: event.parameters)
    }
}
