//
//  CharacterView.swift
//  Questive
//
//  Hero character sheet with equipment and stats
//

import SwiftUI
import SwiftData

struct CharacterView: View {
    @Query private var heroes: [HeroCharacter]
    @Query private var inventory: [InventoryItemModel]
    @Query private var quests: [QuestModel]

    @State private var viewModel = CharacterViewModel()
    @State private var showRenameAlert = false
    @State private var newHeroName = ""

    private var hero: HeroCharacter? { heroes.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let hero = hero {
                        // Hero avatar card
                        HeroAvatarCard(hero: hero, viewModel: viewModel, inventory: inventory)

                        // Stats grid
                        HeroStatsGrid(hero: hero, quests: quests)

                        // Equipment slots
                        EquipmentSection(hero: hero, inventory: inventory, viewModel: viewModel)

                        // Class info
                        ClassInfoCard(heroClass: hero.heroClass, showPicker: $viewModel.showClassPicker)
                    } else {
                        ProgressView("Loading hero...")
                    }
                }
                .padding()
            }
            .background(
                LinearGradient(
                    colors: [Color.indigo.opacity(0.12), Color.purple.opacity(0.06)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("🧙 Hero")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if let hero = hero {
                            newHeroName = hero.heroName
                            showRenameAlert = true
                        }
                    } label: {
                        Image(systemName: "pencil.circle")
                            .foregroundStyle(.purple)
                    }
                }
            }
            .alert("Rename Hero", isPresented: $showRenameAlert) {
                TextField("Hero name", text: $newHeroName)
                Button("Save") {
                    if !newHeroName.trimmingCharacters(in: .whitespaces).isEmpty {
                        hero?.heroName = newHeroName.trimmingCharacters(in: .whitespaces)
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(isPresented: $viewModel.showClassPicker) {
                ClassPickerSheet(hero: hero)
            }
        }
    }
}

// MARK: - Hero Avatar Card

struct HeroAvatarCard: View {
    let hero: HeroCharacter
    let viewModel: CharacterViewModel
    let inventory: [InventoryItemModel]

    private var equipped: [ItemSlot: ShopItemDefinition] {
        viewModel.equippedItems(for: hero, inventory: inventory)
    }

    var body: some View {
        VStack(spacing: 16) {
            // Big avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [hero.heroClass.primaryColor.opacity(0.3), hero.heroClass.primaryColor.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)

                VStack(spacing: -8) {
                    // Hat
                    if let hat = equipped[.hat] {
                        Text(hat.iconEmoji)
                            .font(.title)
                    }
                    Text(hero.heroClass.avatarEmoji)
                        .font(.system(size: 56))
                    // Pet
                    if let pet = equipped[.pet] {
                        Text(pet.iconEmoji)
                            .font(.title3)
                            .offset(x: 30, y: -20)
                    }
                }

                // Weapon overlay
                if let weapon = equipped[.weapon] {
                    Text(weapon.iconEmoji)
                        .font(.title2)
                        .offset(x: -50, y: 10)
                }
            }

            // Name & Level
            Text(hero.heroName)
                .font(.title2)
                .fontWeight(.bold)

            HStack(spacing: 8) {
                Text(viewModel.levelTitle(for: hero.level))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Lv.\(hero.level)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.purple.opacity(0.15))
                    .foregroundStyle(.purple)
                    .clipShape(Capsule())
            }

            // XP bar
            VStack(spacing: 4) {
                HStack {
                    Text("XP")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(hero.currentXP) / \(hero.xpForNextLevel)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                ProgressView(value: hero.xpProgress)
                    .tint(.purple)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
        )
    }
}

// MARK: - Hero Stats Grid

struct HeroStatsGrid: View {
    let hero: HeroCharacter
    let quests: [QuestModel]

    private var totalStreak: Int {
        quests.map(\.currentStreakDays).max() ?? 0
    }

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(title: "Total XP", value: "\(hero.totalXP)", icon: "star.fill", color: .purple)
            StatCard(title: "Gold", value: "\(hero.goldBalance)🪙", icon: "coins.fill", color: .yellow)
            StatCard(title: "Quests Done", value: "\(hero.totalQuestsCompleted)", icon: "checkmark.circle.fill", color: .green)
            StatCard(title: "Best Streak", value: "\(totalStreak)🔥", icon: "flame.fill", color: .orange)
            StatCard(title: "Bosses Slain", value: "\(hero.totalBossesDefeated)", icon: "shield.fill", color: .red)
            StatCard(title: "Level", value: "\(hero.level)", icon: "arrow.up.circle.fill", color: .blue)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(color.opacity(0.08))
        )
    }
}

// MARK: - Equipment Section

struct EquipmentSection: View {
    let hero: HeroCharacter
    let inventory: [InventoryItemModel]
    let viewModel: CharacterViewModel

    private var equipped: [ItemSlot: ShopItemDefinition] {
        viewModel.equippedItems(for: hero, inventory: inventory)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Equipment")
                .font(.headline)
                .padding(.leading, 4)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(ItemSlot.allCases, id: \.self) { slot in
                    EquipmentSlotView(
                        slot: slot,
                        equippedItem: equipped[slot]
                    )
                }
            }
        }
    }
}

struct EquipmentSlotView: View {
    let slot: ItemSlot
    let equippedItem: ShopItemDefinition?

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(equippedItem != nil ? Color.purple.opacity(0.12) : Color.gray.opacity(0.08))
                    .frame(height: 64)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(equippedItem != nil ? Color.purple.opacity(0.4) : Color.gray.opacity(0.2), lineWidth: 1)
                    )

                if let item = equippedItem {
                    Text(item.iconEmoji)
                        .font(.largeTitle)
                } else {
                    Image(systemName: slot.icon)
                        .font(.title2)
                        .foregroundStyle(.tertiary)
                }
            }

            Text(equippedItem?.name ?? slot.rawValue)
                .font(.caption)
                .foregroundStyle(equippedItem != nil ? .primary : .secondary)
                .lineLimit(1)
        }
    }
}

// MARK: - Class Info Card

struct ClassInfoCard: View {
    let heroClass: HeroClass
    @Binding var showPicker: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Class: \(heroClass.rawValue)")
                    .font(.headline)
                HStack(spacing: 4) {
                    Image(systemName: heroClass.icon)
                        .foregroundStyle(heroClass.primaryColor)
                    Text(heroClass.bonusDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Button("Change") { showPicker = true }
                .font(.subheadline)
                .foregroundStyle(.purple)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(heroClass.primaryColor.opacity(0.08))
        )
    }
}

// MARK: - Class Picker Sheet

struct ClassPickerSheet: View {
    let hero: HeroCharacter?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(HeroClass.allCases, id: \.self) { heroClass in
                    Button {
                        hero?.heroClass = heroClass
                        dismiss()
                    } label: {
                        HStack(spacing: 14) {
                            Text(heroClass.avatarEmoji)
                                .font(.title)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(heroClass.rawValue)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text(heroClass.bonusDescription)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if hero?.heroClass == heroClass {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.purple)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Choose Class")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
