//
//  Emblems.swift
//  Fantasy Fitness
//
//  Round cartoon badges (wax seals, class crests, dungeon nodes) and the color
//  pairs that game concepts (classes, stats, rarity) map to.
//

import SwiftUI

/// Outlined circle with a hard shadow and a cream icon in the middle.
struct EmblemBadge<Content: View>: View {
    let palette: CartoonPalette
    var size: CGFloat = 50
    var shadowOffset: CGFloat = 3
    @ViewBuilder let content: Content

    var body: some View {
        ZStack { content }
            .font(.system(size: size * 0.4, weight: .bold))
            .foregroundStyle(palette.text)
            .frame(width: size, height: size)
            .background(CartoonSurface(shape: Circle(), fill: palette.fill, outline: palette.border,
                                       lineWidth: 3, shadowOffset: shadowOffset))
    }
}

/// A class's crest: its color and emblem in a badge.
struct ClassEmblem: View {
    let guildClass: GuildClass
    var size: CGFloat = 52

    var body: some View {
        EmblemBadge(palette: guildClass.palette, size: size) {
            switch guildClass {
            case .warrior:
                SwordShape()
                    .stroke(Theme.cream, style: StrokeStyle(lineWidth: 2, lineJoin: .round))
                    .frame(width: size * 0.29, height: size * 0.54)
                    .rotationEffect(.degrees(-45))
            case .ranger: Image(systemName: "leaf.fill")
            case .monk: Image(systemName: "figure.mind.and.body")
            case .paladin: Image(systemName: "shield.fill")
            }
        }
        .accessibilityLabel(guildClass.name)
    }
}

/// Simple outlined sword pointing up; rotate it to taste.
struct SwordShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height, cx = rect.midX
        var path = Path()
        // Blade
        path.move(to: CGPoint(x: cx, y: rect.minY))
        path.addLine(to: CGPoint(x: cx + w * 0.16, y: rect.minY + h * 0.14))
        path.addLine(to: CGPoint(x: cx + w * 0.16, y: rect.minY + h * 0.62))
        path.addLine(to: CGPoint(x: cx - w * 0.16, y: rect.minY + h * 0.62))
        path.addLine(to: CGPoint(x: cx - w * 0.16, y: rect.minY + h * 0.14))
        path.closeSubpath()
        // Crossguard
        path.addRoundedRect(in: CGRect(x: rect.minX, y: rect.minY + h * 0.62, width: w, height: h * 0.09),
                            cornerSize: CGSize(width: 2, height: 2))
        // Grip
        path.addRect(CGRect(x: cx - w * 0.09, y: rect.minY + h * 0.71, width: w * 0.18, height: h * 0.18))
        // Pommel
        path.addEllipse(in: CGRect(x: cx - w * 0.14, y: rect.minY + h * 0.89, width: w * 0.28, height: w * 0.28))
        return path
    }
}

// MARK: - Concept colors

extension GuildClass {
    var palette: CartoonPalette {
        switch self {
        case .warrior: .wax
        case .ranger: .emerald
        case .monk: .sapphire
        case .paladin: .amethyst
        }
    }
}

extension StatKind {
    var palette: CartoonPalette {
        switch self {
        case .strength: .wax
        case .endurance: .emerald
        case .speed: .sapphire
        case .agility: .amethyst
        case .vitality: CartoonPalette(fill: Theme.vitality, border: Theme.vitalityBorder, text: Theme.cream)
        }
    }

    var systemImage: String {
        switch self {
        case .strength: "dumbbell.fill"
        case .endurance: "figure.run"
        case .speed: "hare.fill"
        case .agility: "figure.jumprope"
        case .vitality: "heart.fill"
        }
    }
}

extension Rarity {
    var palette: CartoonPalette {
        switch self {
        case .common: CartoonPalette(fill: Theme.rarityCommon, border: Theme.rarityCommonBorder, text: Theme.cream)
        case .uncommon: .emerald
        case .rare: .sapphire
        case .epic: .amethyst
        case .legendary: CartoonPalette(fill: Theme.rarityLegendary, border: Theme.rarityLegendaryBorder, text: Theme.cream)
        }
    }
}
