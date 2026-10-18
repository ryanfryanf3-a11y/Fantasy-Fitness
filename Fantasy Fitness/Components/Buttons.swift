//
//  Buttons.swift
//  Fantasy Fitness
//

import SwiftUI

/// Cartoon button: flat fill, thick outline, hard shadow, sinks when pressed.
/// The label is free-form; this only supplies the surface, default font and color.
struct ChunkyButtonStyle: ButtonStyle {
    var palette: CartoonPalette = .wax
    var minHeight: CGFloat = 54
    var cornerRadius: CGFloat = 14
    var fullWidth = true
    /// Default label size; a label that sets its own fonts overrides this.
    var fontSize: CGFloat = 20

    func makeBody(configuration: Configuration) -> some View {
        ChunkyButtonBody(configuration: configuration, style: self)
    }

    private struct ChunkyButtonBody: View {
        let configuration: Configuration
        let style: ChunkyButtonStyle
        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            configuration.label
                .font(.alegreya(style.fontSize, weight: .heavy))
                .foregroundStyle(style.palette.text)
                .padding(.horizontal, 14)
                .frame(maxWidth: style.fullWidth ? .infinity : nil, minHeight: style.minHeight)
                .cartoonBackground(RoundedRectangle(cornerRadius: style.cornerRadius),
                                   fill: style.palette.fill, outline: style.palette.border,
                                   lineWidth: 3, shadowOffset: 5)
                .opacity(isEnabled ? 1 : 0.5)
                .offset(y: configuration.isPressed ? 3 : 0)
                .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
        }
    }
}

extension ButtonStyle where Self == ChunkyButtonStyle {
    static func chunky(_ palette: CartoonPalette = .wax, minHeight: CGFloat = 54,
                       fullWidth: Bool = true, fontSize: CGFloat = 20) -> ChunkyButtonStyle {
        ChunkyButtonStyle(palette: palette, minHeight: minHeight, fullWidth: fullWidth, fontSize: fontSize)
    }
}

/// Round 44 pt icon button on wood (back, settings).
struct WoodIconButton: View {
    let systemImage: String
    let accessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .heavy))
                .foregroundStyle(Theme.cream)
                .frame(width: 44, height: 44)
                .cartoonBackground(Circle(), fill: Theme.darkerWood,
                                   outline: Theme.darkestWood, shadowOffset: 3)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}
