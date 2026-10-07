//
//  OnboardingView.swift
//  Fantasy Fitness
//

import SwiftUI

/// Placeholder until class / goals / program selection is built.
struct OnboardingView: View {
    let onFinish: () -> Void
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .heavy))
                        .foregroundStyle(Theme.cream)
                        .frame(width: 44, height: 44)
                        .cartoonBackground(Circle(), fill: Theme.darkerWood,
                                           outline: Theme.darkestWood, shadowOffset: 3)
                }
                .accessibilityLabel("Back to title")
                Spacer()
            }

            Spacer()

            VStack(alignment: .leading, spacing: 10) {
                Text("NEW ADVENTURE")
                    .font(.alegreyaSans(12, weight: .bold))
                    .tracking(0.6)
                    .foregroundStyle(Theme.kicker)
                Text("Join the Guild")
                    .font(.alegreya(30, weight: .heavy))
                    .foregroundStyle(Theme.ink)
                Text("Choosing your class, goals and program is coming soon.")
                    .font(.alegreyaSans(17))
                    .foregroundStyle(Theme.inkSecondary)

                Button(action: onFinish) {
                    Text("Enter the Guild Hall")
                        .font(.alegreya(20, weight: .heavy))
                        .foregroundStyle(Theme.cream)
                        .frame(maxWidth: .infinity, minHeight: 54)
                        .cartoonBackground(RoundedRectangle(cornerRadius: 14), fill: Theme.emerald,
                                           outline: Theme.emeraldBorder, shadowOffset: 5)
                }
                .buttonStyle(PressableButtonStyle())
                .padding(.top, 14)
            }
            .padding(24)
            .cartoonBackground(RoundedRectangle(cornerRadius: 8), fill: Theme.parchment, shadowOffset: 6)

            Spacer()
        }
        .padding(16)
        .background(WoodBackground())
    }
}

#Preview {
    OnboardingView(onFinish: {}, onBack: {})
}
