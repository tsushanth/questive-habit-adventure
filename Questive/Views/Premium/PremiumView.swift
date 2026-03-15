//
//  PremiumView.swift
//  Questive
//
//  RevenueCat-ready premium paywall — broken into subviews to avoid type-check timeout
//

import SwiftUI
import StoreKit

// MARK: - Premium Feature Row Item

private struct PremiumFeatureItem: Identifiable {
    let id: String
    let icon: String
    let title: String
    let subtitle: String
}

private let premiumFeatures: [PremiumFeatureItem] = [
    PremiumFeatureItem(id: "quests", icon: "infinity", title: "Unlimited Quests", subtitle: "Create as many quests as you want"),
    PremiumFeatureItem(id: "boss", icon: "flame.fill", title: "Boss Raids", subtitle: "Take on epic weekly boss battles"),
    PremiumFeatureItem(id: "guild", icon: "person.3.fill", title: "Guild Features", subtitle: "Team up with friends"),
    PremiumFeatureItem(id: "cosmetics", icon: "paintpalette.fill", title: "Premium Cosmetics", subtitle: "Exclusive legendary items"),
    PremiumFeatureItem(id: "stats", icon: "chart.line.uptrend.xyaxis", title: "Advanced Stats", subtitle: "Deep habit analytics"),
]

// MARK: - Premium Hero Header

private struct PremiumHeroHeader: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("Questive Premium")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("Become the ultimate hero")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top)
    }
}

// MARK: - Premium Feature Row

private struct PremiumFeatureRow: View {
    let item: PremiumFeatureItem

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: item.icon)
                    .font(.headline)
                    .foregroundStyle(.purple)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.headline)
                Text(item.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.purple)
        }
    }
}

// MARK: - Premium Features Card

private struct PremiumFeaturesCard: View {
    var body: some View {
        VStack(spacing: 12) {
            ForEach(premiumFeatures) { item in
                PremiumFeatureRow(item: item)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
        )
        .padding(.horizontal)
    }
}

// MARK: - Product Options View

private struct ProductOptionsSection: View {
    let subscriptions: [StoreKit.Product]
    let isLoading: Bool
    @Binding var selectedProductID: String?

    var body: some View {
        Group {
            if isLoading {
                ProgressView().padding()
            } else if subscriptions.isEmpty {
                StaticProductOptions(selectedProductID: $selectedProductID)
            } else {
                DynamicProductOptions(
                    subscriptions: subscriptions,
                    selectedProductID: $selectedProductID
                )
            }
        }
    }
}

private struct StaticProductOptions: View {
    @Binding var selectedProductID: String?

    var body: some View {
        VStack(spacing: 12) {
            ProductOptionCard(
                title: "Monthly",
                price: "$4.99/month",
                savings: nil,
                isSelected: selectedProductID == QuestiveProductID.monthly.rawValue,
                isPopular: false
            ) {
                selectedProductID = QuestiveProductID.monthly.rawValue
            }
            ProductOptionCard(
                title: "Yearly",
                price: "$34.99/year",
                savings: "Save 42%",
                isSelected: selectedProductID == QuestiveProductID.yearly.rawValue,
                isPopular: true
            ) {
                selectedProductID = QuestiveProductID.yearly.rawValue
            }
        }
        .padding(.horizontal)
    }
}

private func periodLabelFor(_ product: StoreKit.Product) -> String {
    guard let subscription = product.subscription else { return "" }
    switch subscription.subscriptionPeriod.unit {
    case .day: return subscription.subscriptionPeriod.value == 7 ? "/week" : "/day"
    case .week: return "/week"
    case .month: return "/month"
    case .year: return "/year"
    @unknown default: return ""
    }
}

private struct DynamicProductOption: View {
    let product: StoreKit.Product
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        ProductOptionCard(
            title: product.displayName,
            price: product.displayPrice + periodLabelFor(product),
            savings: nil,
            isSelected: isSelected,
            isPopular: product.subscription?.subscriptionPeriod.unit == .year,
            onTap: onTap
        )
    }
}

private struct DynamicProductOptions: View {
    let subscriptions: [StoreKit.Product]
    @Binding var selectedProductID: String?

    var body: some View {
        VStack(spacing: 12) {
            ForEach(subscriptions, id: \.id) { product in
                DynamicProductOption(
                    product: product,
                    isSelected: selectedProductID == product.id
                ) {
                    selectedProductID = product.id
                }
            }
        }
        .padding(.horizontal)
        .onAppear {
            if selectedProductID == nil {
                selectedProductID = subscriptions.first?.id
            }
        }
    }
}

// MARK: - Subscribe CTA Button

private struct SubscribeCTAButton: View {
    let isLoading: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    HStack {
                        Image(systemName: "crown.fill")
                        Text("Start Adventure")
                            .fontWeight(.bold)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [.purple, .indigo],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .disabled(isLoading)
        .padding(.horizontal)
    }
}

// MARK: - Legal Footer

private struct PremiumLegalFooter: View {
    let onRestore: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Button("Restore Purchases", action: onRestore)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("Cancel anytime. Payment charged to your Apple ID. [Privacy Policy](https://example.com) · [Terms of Use](https://example.com)")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
                .padding(.bottom, 20)
        }
    }
}

// MARK: - Main Premium View

struct PremiumView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PremiumManager.self) private var premiumManager

    @State private var selectedProductID: String? = nil
    @State private var isLoading = false
    @State private var errorMessage: String? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    PremiumHeroHeader()
                    PremiumFeaturesCard()

                    ProductOptionsSection(
                        subscriptions: premiumManager.subscriptions,
                        isLoading: premiumManager.isLoading,
                        selectedProductID: $selectedProductID
                    )

                    if let error = errorMessage {
                        Text(error)
                            .font(.subheadline)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    SubscribeCTAButton(isLoading: isLoading) {
                        Task { await handleSubscribe() }
                    }

                    PremiumLegalFooter {
                        Task {
                            await premiumManager.restorePurchases()
                            if premiumManager.isPremium { dismiss() }
                        }
                    }
                }
            }
            .navigationTitle("Go Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(.secondary)
                }
            }
        }
        .onAppear {
            premiumManager.recordPaywallShown()
            AnalyticsService.shared.track(.paywallViewed(trigger: "sheet"))
            Task { await premiumManager.refreshPremiumStatus() }
        }
    }

    private func handleSubscribe() async {
        guard let productID = selectedProductID,
              let product = premiumManager.subscriptions.first(where: { $0.id == productID }) else {
            errorMessage = "Products not available. Please check your connection."
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            try await premiumManager.purchase(product)
            AnalyticsService.shared.track(.subscriptionPurchased(productID: product.id))
            dismiss()
        } catch {
            if case QuestiveStoreKitError.userCancelled = error {
                // Silent cancel
            } else {
                errorMessage = error.localizedDescription
            }
        }
        isLoading = false
    }
}

// MARK: - Product Option Card

struct ProductOptionCard: View {
    let title: String
    let price: String
    let savings: String?
    let isSelected: Bool
    let isPopular: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.headline)
                        if isPopular {
                            Text("BEST VALUE")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.orange.opacity(0.2))
                                .foregroundStyle(.orange)
                                .clipShape(Capsule())
                        }
                    }
                    if let savings = savings {
                        Text(savings)
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
                Spacer()
                Text(price)
                    .font(.headline)
                    .fontWeight(.bold)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .purple : .gray)
                    .font(.title3)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? Color.purple.opacity(0.08) : Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isSelected ? Color.purple : Color.gray.opacity(0.2), lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
