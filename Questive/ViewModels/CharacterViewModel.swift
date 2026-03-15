//
//  CharacterViewModel.swift
//  Questive
//
//  ViewModel for hero character management
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class CharacterViewModel {
    var showClassPicker = false
    var showLevelUpBanner = false

    func levelTitle(for level: Int) -> String {
        switch level {
        case 1...4: return "Apprentice"
        case 5...9: return "Journeyman"
        case 10...19: return "Veteran"
        case 20...34: return "Champion"
        case 35...49: return "Legend"
        default: return "Mythic Hero"
        }
    }

    func equippedItems(for hero: HeroCharacter, inventory: [InventoryItemModel]) -> [ItemSlot: ShopItemDefinition] {
        var result: [ItemSlot: ShopItemDefinition] = [:]
        let equippedIDs: [String?] = [
            hero.equippedHatID,
            hero.equippedArmorID,
            hero.equippedWeaponID,
            hero.equippedPetID
        ]
        for itemID in equippedIDs.compactMap({ $0 }) {
            if let def = GameEngine.shopCatalog.first(where: { $0.id == itemID }) {
                result[def.slot] = def
            }
        }
        return result
    }

    func equipItem(_ item: ShopItemDefinition, hero: HeroCharacter) {
        switch item.slot {
        case .hat: hero.equippedHatID = item.id
        case .armor: hero.equippedArmorID = item.id
        case .weapon: hero.equippedWeaponID = item.id
        case .pet: hero.equippedPetID = item.id
        }
    }

    func unequipSlot(_ slot: ItemSlot, hero: HeroCharacter) {
        switch slot {
        case .hat: hero.equippedHatID = nil
        case .armor: hero.equippedArmorID = nil
        case .weapon: hero.equippedWeaponID = nil
        case .pet: hero.equippedPetID = nil
        }
    }

    func ownedItemIDs(inventory: [InventoryItemModel]) -> Set<String> {
        Set(inventory.map(\.itemID))
    }
}
