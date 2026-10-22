//
//  GearRoute.swift
//  Fantasy Fitness
//

import SwiftUI

/// Inventory and item detail can be reached from Character and from a dungeon Loadout.
/// Links push a `GearRoute` value; each stack registers the destinations once.
enum GearRoute: Hashable {
    case inventory
    case item(Item)
}

extension View {
    func gearDestinations() -> some View {
        navigationDestination(for: GearRoute.self) { route in
            switch route {
            case .inventory: InventoryView()
            case .item(let item): ItemDetailView(item: item)
            }
        }
    }
}
