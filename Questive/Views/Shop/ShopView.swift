//
//  ShopView.swift
//  Questive
//
//  In-game shop to spend gold on cosmetic items
//

import SwiftUI
import SwiftData

struct ShopView: View {
    @Binding var showPaywall: Bool
    @Environment(\.modelContext) private var modelContext
    @Environment(PremiumManager.self) private var premiumManager

    @Query private var heroes: [HeroCharacter]
    @Query private var inventory: [InventoryItemModel]

    @State private var selectedSlot: ItemSlot? = nil
    @State private var showPurchaseAlert = false
    @State private var pendingItem: ShopItemDefinition? = nil
    @State private var purchaseResultMessage = ""
    @State private var showResultAlert = false

    private var hero: HeroCharacter? { heroes.first }
    private var ownedIDs: Set<String> { Set(inventory.map(\.itemID)) }

    private var filteredItems: [ShopItemDefinition] {
        GameEngine.shopCatalog.filter { item in
            if let slot = selectedSlot { return item.slot == slot }
            return true
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Gold balance header
                if let hero = hero {
                    GoldBalanceHeader(hero: hero)
                }

                // Slot filter
                SlotFilterBar(selection: $selectedSlot)
                    .padding(.horizontal)
                    .padding(.vertical, 10)

                // Items grid
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(filteredItems) { item in
                            ShopItemCard(
                                item: item,
                                isOwned: ownedIDs.contains(item.id),
                                isPremiumUser: premiumManager.isPremium,
                                goldBalance: hero?.goldBalance ?? 0,
                                onBuy: {
                                    if item.isPremium && !premiumManager.isPremium {
                                        showPaywall = true
                                    } else {
                                        pendingItem = item
                                        showPurchaseAlert = true
                                    }
                                },
                                onEquip: {
                                    equipItem(item)
                                }
                            )
                        }
                    }
                    .padding()
                    .padding(.bottom, 20)
                }
            }
            .background(
                LinearGradient(
                    colors: [Color.yellow.opacity(0.08), Color.orange.opacity(0.04)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("🏪 Shop")
            .navigationBarTitleDisplayMode(.large)
            .alert("Purchase Item?", isPresented: $showPurchaseAlert, presenting: pendingItem) { item in
                Button("Buy for \(item.goldCost)🪙") {
                    confirmPurchase(item)
                }
                Button("Cancel", role: .cancel) {}
            } message: { item in
                Text("Purchase \"\(item.name)\" for \(item.goldCost) gold?")
            }
            .alert(purchaseResultMessage, isPresented: $showResultAlert) {
                Button("OK") {}
            }
        }
    }

    private func confirmPurchase(_ item: ShopItemDefinition) {
        guard let hero = hero else { return }
        let success = GameEngine.shared.purchaseItem(item, hero: hero, context: modelContext)
        if success {
            purchaseResultMessage = "You bought \(item.iconEmoji) \(item.name)!"
        } else {
            purchaseResultMessage = "Not enough gold! Need \(item.goldCost - (hero.goldBalance)) more 🪙"
        }
        showResultAlert = true
    }

    private func equipItem(_ item: ShopItemDefinition) {
        guard let hero = hero else { return }
        switch item.slot {
        case .hat: hero.equippedHatID = item.id
        case .armor: hero.equippedArmorID = item.id
        case .weapon: hero.equippedWeaponID = item.id
        case .pet: hero.equippedPetID = item.id
        }
    }
}

// MARK: - Gold Balance Header

struct GoldBalanceHeader: View {
    let hero: HeroCharacter

    var body: some View {
        HStack {
            Spacer()
            HStack(spacing: 8) {
                Text("🪙")
                    .font(.title2)
                Text("\(hero.goldBalance) Gold")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.yellow)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color.yellow.opacity(0.15))
                    .overlay(Capsule().stroke(Color.yellow.opacity(0.4), lineWidth: 1))
            )
            Spacer()
        }
        .padding(.vertical, 10)
        .background(Color(.systemBackground).opacity(0.95))
    }
}

// MARK: - Slot Filter Bar

struct SlotFilterBar: View {
    @Binding var selection: ItemSlot?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "All", isSelected: selection == nil) {
                    selection = nil
                }
                ForEach(ItemSlot.allCases, id: \.self) { slot in
                    FilterChip(
                        title: slot.rawValue,
                        icon: slot.icon,
                        isSelected: selection == slot
                    ) {
                        selection = selection == slot ? nil : slot
                    }
                }
            }
        }
    }
}

// MARK: - Shop Item Card

struct ShopItemCard: View {
    let item: ShopItemDefinition
    let isOwned: Bool
    let isPremiumUser: Bool
    let goldBalance: Int
    let onBuy: () -> Void
    let onEquip: () -> Void

    private var canAfford: Bool { goldBalance >= item.goldCost }
    private var isPremiumLocked: Bool { item.isPremium && !isPremiumUser }

    var body: some View {
        VStack(spacing: 10) {
            // Rarity badge
            HStack {
                Spacer()
                Text(item.rarity.rawValue)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(item.rarity.color.opacity(0.2))
                    .foregroundStyle(item.rarity.color)
                    .clipShape(Capsule())
            }

            // Icon
            Text(item.iconEmoji)
                .font(.system(size: 48))

            // Name
            Text(item.name)
                .font(.headline)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)

            Text(item.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            // Action button
            if isOwned {
                Button(action: onEquip) {
                    Text("Equip")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.green.opacity(0.15))
                        .foregroundStyle(.green)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            } else if isPremiumLocked {
                Button(action: onBuy) {
                    HStack(spacing: 4) {
                        Image(systemName: "crown.fill")
                        Text("Premium")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.purple.opacity(0.15))
                    .foregroundStyle(.purple)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            } else {
                Button(action: onBuy) {
                    HStack(spacing: 4) {
                        Text("🪙 \(item.goldCost)")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(canAfford ? Color.yellow.opacity(0.2) : Color.gray.opacity(0.1))
                    .foregroundStyle(canAfford ? Color.orange : .gray)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .disabled(!canAfford)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isOwned ? Color.green.opacity(0.4) : Color.clear, lineWidth: 2)
        )
    }
}
