//
//  InventoryView.swift
//  Fantasy Fitness
//

import SwiftUI

struct InventoryView: View {
    @Environment(GameStore.self) private var store
    @State private var filter: Filter = .all

    private enum Filter: Hashable, CaseIterable {
        case all, slot(ItemSlot)

        static var allCases: [Filter] { [.all] + ItemSlot.allCases.map(Filter.slot) }

        var title: String {
            switch self {
            case .all: "All"
            case .slot(let slot): slot.name
            }
        }
    }

    private var visibleItems: [Item] {
        let items = store.inventory
        let filtered = switch filter {
        case .all: items
        case .slot(let slot): items.filter { $0.slot == slot }
        }
        return filtered.sorted { $0.rarity > $1.rarity }
    }

    var body: some View {
        BoardScreen(isRoot: false) {
            BoardSign(title: "Inventory")
            WoodSegmentedPicker(options: Filter.allCases, selection: $filter, title: \.title)

            ParchmentCard(padding: 16) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 18) {
                    ForEach(visibleItems) { item in
                        NavigationLink(value: GearRoute.item(item)) {
                            ItemTile(item: item, size: 72)
                                .overlay(alignment: .topTrailing) {
                                    if store.equippedIDs.contains(item.id) { equippedBadge }
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var equippedBadge: some View {
        Image(systemName: "checkmark")
            .font(.system(size: 11, weight: .heavy))
            .foregroundStyle(Theme.cream)
            .frame(width: 22, height: 22)
            .background(Circle().fill(Theme.progressGreen))
            .overlay(Circle().strokeBorder(Theme.outline, lineWidth: 2))
            .offset(x: 4, y: -6)
            .accessibilityLabel("Equipped")
    }
}

#Preview {
    NavigationStack {
        InventoryView()
            .gearDestinations()
    }
    .environment(GameStore.preview)
}
