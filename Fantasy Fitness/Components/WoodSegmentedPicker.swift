//
//  WoodSegmentedPicker.swift
//  Fantasy Fitness
//

import SwiftUI

/// Row of chunky wooden tabs; the selected one turns gold.
struct WoodSegmentedPicker<Option: Hashable>: View {
    let options: [Option]
    @Binding var selection: Option
    let title: (Option) -> String

    var body: some View {
        HStack(spacing: 10) {
            ForEach(options, id: \.self) { option in
                let isSelected = option == selection
                Button {
                    withAnimation(.snappy(duration: 0.2)) { selection = option }
                } label: {
                    Text(title(option))
                        .font(.alegreya(18, weight: .heavy))
                        .foregroundStyle(isSelected ? Theme.ink : Theme.cream)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .padding(.horizontal, 6)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .cartoonBackground(RoundedRectangle(cornerRadius: 10),
                                           fill: isSelected ? Theme.gold : Theme.darkWood,
                                           outline: Theme.darkestWood, shadowOffset: 4)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
    }
}
