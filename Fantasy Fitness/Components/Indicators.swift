//
//  Indicators.swift
//  Fantasy Fitness
//
//  Small read-only building blocks: progress bars, chips, labels and dividers.
//

import SwiftUI

/// Capsule progress bar on parchment. `tint` defaults to the "progress" green.
struct ParchmentProgressBar: View {
    let progress: Double
    var height: CGFloat = 14
    var tint: Color = Theme.progressGreen

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.progressTrack)
                Capsule()
                    .fill(tint)
                    .frame(width: proxy.size.width * min(max(progress, 0), 1))
                Capsule().strokeBorder(Theme.outline, lineWidth: 2.5)
            }
        }
        .frame(height: height)
        .clipShape(Capsule())
    }
}

/// Outlined capsule label on parchment (rewards, macros, tags).
struct TagChip: View {
    let label: String
    var systemImage: String? = nil
    var fill: Color = Theme.scrollRoll.opacity(0.35)
    var foreground: Color = Theme.ink
    var fontSize: CGFloat = 16

    var body: some View {
        HStack(spacing: 5) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: fontSize - 3, weight: .bold))
            }
            Text(label)
                .font(.alegreyaSans(fontSize, weight: .bold))
        }
        .foregroundStyle(foreground)
        .padding(.horizontal, fontSize - 2)
        .frame(minHeight: fontSize * 2.2)
        .background(Capsule().fill(fill))
        .overlay(Capsule().strokeBorder(Theme.outline, lineWidth: 2.5))
    }
}

/// Dark capsule on wood holding a short status (level, energy, cost).
struct WoodPill<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        HStack(spacing: 8) {
            content
        }
        .font(.alegreyaSans(17, weight: .bold))
        .foregroundStyle(Theme.cream)
        .padding(.horizontal, 16)
        .frame(minHeight: 46)
        .cartoonBackground(Capsule(), fill: Theme.darkerWood, outline: Theme.darkestWood, shadowOffset: 3)
    }
}

/// Small uppercase label above a title on parchment.
struct KickerText: View {
    let text: String

    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text.uppercased())
            .font(.alegreyaSans(12, weight: .bold))
            .tracking(0.5)
            .foregroundStyle(Theme.kicker)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }
}

struct DashedDivider: View {
    var body: some View {
        Line()
            .stroke(Theme.inkSecondary.opacity(0.45), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
            .frame(height: 1.5)
            .accessibilityHidden(true)
    }

    private struct Line: Shape {
        func path(in rect: CGRect) -> Path {
            Path { p in
                p.move(to: CGPoint(x: rect.minX, y: rect.midY))
                p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            }
        }
    }
}
