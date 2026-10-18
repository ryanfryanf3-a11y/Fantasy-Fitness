//
//  StarRating.swift
//  Fantasy Fitness
//

import SwiftUI

/// Read-only star display, e.g. "★★★★½".
struct StarRating: View {
    let value: Double
    var size: CGFloat = 14

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: symbol(for: star))
                    .font(.system(size: size, weight: .bold))
                    .foregroundStyle(Theme.rarityLegendary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(value.formatted(.number.precision(.fractionLength(1)))) out of 5")
    }

    private func symbol(for star: Int) -> String {
        if value >= Double(star) { return "star.fill" }
        if value >= Double(star) - 0.5 { return "star.leadinghalf.filled" }
        return "star"
    }
}

/// Tappable 1–5 star input.
struct StarRatingPicker: View {
    @Binding var value: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(1...5, id: \.self) { star in
                Button {
                    value = star
                } label: {
                    Image(systemName: star <= value ? "star.fill" : "star")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(star <= value ? Theme.rarityLegendary : Theme.outline.opacity(0.45))
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(value) out of 5 stars")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: value = min(value + 1, 5)
            case .decrement: value = max(value - 1, 1)
            @unknown default: break
            }
        }
    }
}
