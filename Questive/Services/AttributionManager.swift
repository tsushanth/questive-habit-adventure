//
//  AttributionManager.swift
//  Questive
//
//  Apple Search Ads attribution via AdServices
//

import Foundation
import AdServices

@MainActor
final class AttributionManager {
    static let shared = AttributionManager()

    private let requestedKey = "com.appfactory.questive.hasRequestedAttribution"

    private var hasRequested: Bool {
        get { UserDefaults.standard.bool(forKey: requestedKey) }
        set { UserDefaults.standard.set(newValue, forKey: requestedKey) }
    }

    private init() {}

    func requestAttributionIfNeeded() async {
        guard !hasRequested else { return }
        hasRequested = true
        do {
            let token = try AAAttribution.attributionToken()
            #if DEBUG
            print("[Attribution] Token: \(token.prefix(40))...")
            #endif
        } catch {
            #if DEBUG
            print("[Attribution] Error: \(error.localizedDescription)")
            #endif
        }
    }
}
