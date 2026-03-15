//
//  ATTService.swift
//  Questive
//
//  App Tracking Transparency permission flow
//

import Foundation
import AppTrackingTransparency

@MainActor
@Observable
final class ATTService {
    static let shared = ATTService()

    var status: ATTrackingManager.AuthorizationStatus = .notDetermined

    var isAuthorized: Bool { status == .authorized }

    private init() {}

    func requestIfNeeded() async -> Bool {
        let current = ATTrackingManager.trackingAuthorizationStatus
        guard current == .notDetermined else {
            status = current
            return current == .authorized
        }
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        let result = await ATTrackingManager.requestTrackingAuthorization()
        status = result
        #if DEBUG
        print("[ATTService] Authorization: \(result.rawValue)")
        #endif
        return result == .authorized
    }
}
