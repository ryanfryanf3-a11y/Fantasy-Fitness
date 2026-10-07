//
//  Theme.swift
//  Fantasy Fitness
//

import SwiftUI
import UIKit

// MARK: - Colors

enum Theme {
    // Wood
    static let wood = Color(hex: 0x7A4B2A)
    static let plankSeam = Color(red: 38 / 255, green: 18 / 255, blue: 6 / 255).opacity(0.6)
    static let darkWood = Color(hex: 0x5A3418)
    static let darkerWood = Color(hex: 0x3A2008)
    static let darkestWood = Color(hex: 0x241204)

    // Parchment
    static let parchment = Color(hex: 0xF4DFAE)
    static let noteParchment = Color(hex: 0xF1D9A2)
    static let scrollRoll = Color(hex: 0xE2B565)
    static let scrollKnob = Color(hex: 0x8A4B1C)
    static let checkboxFill = Color(hex: 0xFBEBC4)
    static let progressTrack = Color(hex: 0xE6C887)

    // Ink
    static let outline = Color(hex: 0x5C3412)
    static let ink = Color(hex: 0x3B2412)
    static let inkSecondary = Color(hex: 0x6B4423)
    static let kicker = Color(hex: 0x8A4B1C)
    static let cream = Color(hex: 0xFFF3D6)

    // Accents
    static let gold = Color(hex: 0xF2C14E)
    static let waxRed = Color(hex: 0xA3341F)
    static let waxBorder = Color(hex: 0x4A1A0E)
    static let progressGreen = Color(hex: 0x6E8B3D)
    static let positiveText = Color(hex: 0x3F5A1E)
    static let brass = Color(hex: 0xC9962E)

    // Fantasy accents (title screen, class colors)
    static let skyTop = Color(hex: 0x1E1640)
    static let skyMid = Color(hex: 0x4E2668)
    static let skyGlow = Color(hex: 0xD9694A)
    static let horizonGlow = Color(hex: 0xF2A65A)
    static let mountainFar = Color(hex: 0x4A2F66)
    static let mountainNear = Color(hex: 0x2A1A45)
    static let castle = Color(hex: 0x1C1233)
    static let moon = Color(hex: 0xFCE9B8)

    static let emerald = Color(hex: 0x2F7A4F)
    static let emeraldBorder = Color(hex: 0x163A24)
    static let sapphire = Color(hex: 0x2D5A9E)
    static let sapphireBorder = Color(hex: 0x142B52)
    static let amethyst = Color(hex: 0x6B3FA0)
    static let amethystBorder = Color(hex: 0x33194F)

    static let flameOuter = Color(hex: 0xE8672A)
    static let flameInner = Color(hex: 0xF7C948)
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

// MARK: - Fonts
// Pirata One, Alegreya and Alegreya Sans (Google Fonts) are used when bundled
// and registered under UIAppFonts; otherwise these fall back to system fonts.

extension Font {
    /// Blackletter title font. Use for the board title only.
    static func pirata(_ size: CGFloat) -> Font {
        named("PirataOne-Regular", size: size, relativeTo: .largeTitle,
              fallback: .system(size: size, weight: .black, design: .serif))
    }

    /// Headings, quest names and buttons.
    static func alegreya(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        let name = weight == .heavy || weight == .black ? "Alegreya-ExtraBold" : "Alegreya-Bold"
        return named(name, size: size, relativeTo: .headline,
                     fallback: .system(size: size, weight: weight, design: .serif))
    }

    /// Body text, objectives and numbers.
    static func alegreyaSans(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let name: String
        switch weight {
        case .bold, .heavy, .black: name = "AlegreyaSans-Bold"
        case .medium, .semibold: name = "AlegreyaSans-Medium"
        default: name = "AlegreyaSans-Regular"
        }
        return named(name, size: size, relativeTo: .body,
                     fallback: .system(size: size, weight: weight, design: .default))
    }

    private static func named(_ name: String, size: CGFloat, relativeTo style: Font.TextStyle, fallback: Font) -> Font {
        UIFont(name: name, size: size) != nil ? .custom(name, size: size, relativeTo: style) : fallback
    }
}

// MARK: - Cartoon surfaces

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
