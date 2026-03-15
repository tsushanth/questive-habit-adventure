//
//  AppDelegate.swift
//  Questive
//
//  UIApplicationDelegate — Firebase + Facebook SDK init, ATT, AdServices
//

import UIKit

// MARK: - Facebook SDK Stub
// To enable: add FacebookCore SPM package and uncomment imports
// import FacebookCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Firebase Analytics
        // FirebaseApp.configure()
        AnalyticsService.shared.initialize()
        AnalyticsService.shared.track(.appOpen)

        // Facebook SDK
        // ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)

        // ATT + AdServices (delayed to after first screen)
        Task { @MainActor in
            _ = await ATTService.shared.requestIfNeeded()
            await AttributionManager.shared.requestAttributionIfNeeded()
        }

        return true
    }

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        // Facebook URL handling
        // return ApplicationDelegate.shared.application(app, open: url, sourceApplication: options[.sourceApplication] as? String, annotation: options[.annotation])
        return false
    }
}
