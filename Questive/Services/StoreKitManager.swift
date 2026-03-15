//
//  StoreKitManager.swift
//  Questive
//
//  StoreKit 2 implementation for subscriptions
//

import Foundation
import StoreKit

// MARK: - Product Identifiers

enum QuestiveProductID: String, CaseIterable {
    case monthly = "com.appfactory.questive.subscription.monthly"
    case yearly  = "com.appfactory.questive.subscription.yearly"

    var displayName: String {
        switch self {
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        }
    }

    static var allIDs: [String] { allCases.map(\.rawValue) }
}

// MARK: - Purchase State

enum PurchaseState: Equatable {
    case idle
    case loading
    case purchasing
    case purchased
    case failed(String)
    case pending
    case cancelled
}

// MARK: - StoreKit Error

enum QuestiveStoreKitError: LocalizedError {
    case productNotFound
    case purchaseFailed(Error)
    case verificationFailed
    case userCancelled
    case pending
    case unknown

    var errorDescription: String? {
        switch self {
        case .productNotFound: return "Product not found."
        case .purchaseFailed(let e): return "Purchase failed: \(e.localizedDescription)"
        case .verificationFailed: return "Purchase verification failed."
        case .userCancelled: return "Purchase cancelled."
        case .pending: return "Purchase pending approval."
        case .unknown: return "An unknown error occurred."
        }
    }
}

// MARK: - StoreKit Manager

@MainActor
@Observable
final class StoreKitManager {
    private(set) var subscriptions: [Product] = []
    private(set) var allProducts: [Product] = []
    private(set) var purchaseState: PurchaseState = .idle
    private(set) var isLoading: Bool = false
    private(set) var errorMessage: String?
    private(set) var purchasedSubscriptions: Set<String> = []

    private var updateListenerTask: Task<Void, Error>?

    var hasActiveSubscription: Bool { !purchasedSubscriptions.isEmpty }
    var isPremium: Bool { hasActiveSubscription }

    init() {
        updateListenerTask = listenForTransactions()
        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }

    func loadProducts() async {
        isLoading = true
        errorMessage = nil
        do {
            let storeProducts = try await Product.products(for: QuestiveProductID.allIDs)
            subscriptions = storeProducts
                .filter { $0.type == .autoRenewable || $0.type == .nonRenewable }
                .sorted { $0.price < $1.price }
            allProducts = subscriptions
        } catch {
            errorMessage = "Failed to load products: \(error.localizedDescription)"
        }
        isLoading = false
    }

    func purchase(_ product: Product) async throws -> Transaction? {
        purchaseState = .purchasing
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await updatePurchasedProducts()
                await transaction.finish()
                purchaseState = .purchased
                return transaction
            case .userCancelled:
                purchaseState = .cancelled
                throw QuestiveStoreKitError.userCancelled
            case .pending:
                purchaseState = .pending
                throw QuestiveStoreKitError.pending
            @unknown default:
                purchaseState = .failed("Unknown result")
                throw QuestiveStoreKitError.unknown
            }
        } catch QuestiveStoreKitError.userCancelled {
            purchaseState = .cancelled
            throw QuestiveStoreKitError.userCancelled
        } catch QuestiveStoreKitError.pending {
            purchaseState = .pending
            throw QuestiveStoreKitError.pending
        } catch {
            let msg = error.localizedDescription
            purchaseState = .failed(msg)
            errorMessage = msg
            throw QuestiveStoreKitError.purchaseFailed(error)
        }
    }

    func restorePurchases() async {
        purchaseState = .loading
        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
            purchaseState = isPremium ? .purchased : .idle
        } catch {
            errorMessage = "Restore failed: \(error.localizedDescription)"
            purchaseState = .failed(errorMessage ?? "Unknown error")
        }
    }

    func updatePurchasedProducts() async {
        var purchased: Set<String> = []
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result),
               transaction.revocationDate == nil {
                purchased.insert(transaction.productID)
            }
        }
        purchasedSubscriptions = purchased
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified: throw QuestiveStoreKitError.verificationFailed
        case .verified(let safe): return safe
        }
    }

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await self?.updatePurchasedProducts()
                    await transaction.finish()
                }
            }
        }
    }

    func resetState() {
        purchaseState = .idle
        errorMessage = nil
    }
}
