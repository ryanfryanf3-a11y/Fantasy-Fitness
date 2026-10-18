//
//  Surfaces.swift
//  Fantasy Fitness
//
//  The two base materials every screen is built from: wood boards and cartoon
//  surfaces (flat fill, thick outline, hard drop shadow).
//

import SwiftUI

// MARK: - Cartoon surfaces

/// Fill / outline / label colors for a cartoon surface (buttons, emblems, tiles).
struct CartoonPalette {
    let fill: Color
    let border: Color
    let text: Color

    /// Primary action (Begin quest, Log meal, Enter dungeon).
    static let wax = CartoonPalette(fill: Theme.waxRed, border: Theme.waxBorder, text: Theme.cream)
    /// Positive / progress action (Save, Collect loot).
    static let emerald = CartoonPalette(fill: Theme.emerald, border: Theme.emeraldBorder, text: Theme.cream)
    /// The single most important action on a screen (title Log in).
    static let gold = CartoonPalette(fill: Theme.gold, border: Theme.outline, text: Theme.ink)
    /// Secondary action on wood.
    static let wood = CartoonPalette(fill: Theme.darkWood, border: Theme.darkestWood, text: Theme.cream)
    static let sapphire = CartoonPalette(fill: Theme.sapphire, border: Theme.sapphireBorder, text: Theme.cream)
    static let amethyst = CartoonPalette(fill: Theme.amethyst, border: Theme.amethystBorder, text: Theme.cream)
    /// Secondary action on the night sky.
    static let dusk = CartoonPalette(fill: Theme.mountainFar, border: Theme.mountainNear, text: Theme.cream)
}


/// Flat fill, thick outline and a hard (unblurred) drop shadow.
struct CartoonSurface<S: InsettableShape>: View {
    let shape: S
    let fill: Color
    var outline: Color = Theme.outline
    var lineWidth: CGFloat = 3
    var shadowOffset: CGFloat = 4
    var shadowColor: Color = Theme.darkestWood.opacity(0.55)

    var body: some View {
        ZStack {
            shape.fill(shadowColor).offset(y: shadowOffset)
            shape.fill(fill)
            shape.strokeBorder(outline, lineWidth: lineWidth)
        }
    }
}

extension View {
    func cartoonBackground<S: InsettableShape>(
        _ shape: S,
        fill: Color,
        outline: Color = Theme.outline,
        lineWidth: CGFloat = 3,
        shadowOffset: CGFloat = 4
    ) -> some View {
        background(CartoonSurface(shape: shape, fill: fill, outline: outline,
                                  lineWidth: lineWidth, shadowOffset: shadowOffset))
    }
}

/// Cartoon fill for shapes that can't be inset (pennants, ribbons): centered stroke.
struct CartoonShape<S: Shape>: View {
    let shape: S
    let fill: Color
    var outline: Color = Theme.outline
    var lineWidth: CGFloat = 3
    var shadowOffset: CGFloat = 4
    var shadowColor: Color = Theme.darkestWood.opacity(0.55)

    var body: some View {
        ZStack {
            shape.fill(shadowColor).offset(y: shadowOffset)
            shape.fill(fill)
            shape.stroke(outline, style: StrokeStyle(lineWidth: lineWidth, lineJoin: .round))
        }
    }
}

// MARK: - Wood background

/// Vertical wood planks with horizontal grain and dark seams.
struct WoodBackground: View {
    var plankCount = 4

    var body: some View {
        Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Theme.wood))

            let plankWidth = size.width / CGFloat(plankCount)
            for plank in 0..<plankCount {
                let x = CGFloat(plank) * plankWidth
                // Each plank gets its own grain offset so the boards don't line up.
                var y = CGFloat((plank * 5) % 9)
                var line = plank
                while y < size.height {
                    let opacity = line % 3 == 0 ? 0.10 : 0.05
                    context.fill(Path(CGRect(x: x, y: y, width: plankWidth, height: 2)),
                                 with: .color(.black.opacity(opacity)))
                    y += 6 + CGFloat(line % 2)
                    line += 1
                }
            }

            for seam in 1..<plankCount {
                let x = CGFloat(seam) * plankWidth - 2
                context.fill(Path(CGRect(x: x, y: 0, width: 4, height: size.height)),
                             with: .color(Theme.plankSeam))
            }
        }
        .ignoresSafeArea()
    }
}
