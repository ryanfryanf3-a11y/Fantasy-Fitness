//
//  ItemTile.swift
//  Fantasy Fitness
//

import SwiftUI

/// Rarity-colored square with the item's slot icon; optionally captioned with its name.
struct ItemTile: View {
    let item: Item
    var size: CGFloat = 64
    var showsName = true

    var body: some View {
        VStack(spacing: 6) {
            ItemIcon(slot: item.slot, size: size * 0.42)
                .frame(width: size, height: size)
                .background(CartoonSurface(shape: RoundedRectangle(cornerRadius: size * 0.2),
                                           fill: item.rarity.palette.fill,
                                           outline: item.rarity.palette.border, lineWidth: 3, shadowOffset: 4))

            if showsName {
                Text(item.name)
                    .font(.alegreyaSans(14, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                    .lineLimit(2, reservesSpace: true)
                    .frame(width: size + 16)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(item.name), \(item.rarity.name) \(item.slot.name.lowercased())")
    }
}

/// Glyph for an equipment slot.
struct ItemIcon: View {
    let slot: ItemSlot
    var size: CGFloat = 26

    var body: some View {
        Group {
            switch slot {
            case .weapon:
                SwordShape()
                    .stroke(Theme.cream, style: StrokeStyle(lineWidth: 2.5, lineJoin: .round))
                    .frame(width: size * 0.55, height: size)
                    .rotationEffect(.degrees(-45))
            case .head: Image(systemName: "crown.fill")
            case .chest: Image(systemName: "tshirt.fill")
            case .trinket: Image(systemName: "sparkles")
            }
        }
        .font(.system(size: size, weight: .bold))
        .foregroundStyle(Theme.cream)
    }
}

/// Small rarity label, e.g. on item detail and loot reveal.
struct RarityChip: View {
    let rarity: Rarity

    var body: some View {
        TagChip(label: rarity.name, fill: rarity.palette.fill, foreground: rarity.palette.text, fontSize: 14)
    }
}
