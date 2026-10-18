//
//  OnboardingView.swift
//  Fantasy Fitness
//

import SwiftUI

/// First-login setup. Class choice is live; goals and program selection are still to come.
struct OnboardingView: View {
    let onFinish: () -> Void
    let onBack: () -> Void

    @State private var selectedClass: GuildClass = .warrior

    var body: some View {
        BoardScreen {
            HStack {
                WoodIconButton(systemImage: "chevron.left", accessibilityLabel: "Back to title", action: onBack)
                Spacer()
            }

            BoardSign(title: "Join the Guild", fontSize: 40)

            ParchmentCard {
                KickerText("Step 1 of 3 · Choose your class")
                Text("Your class sets your default routine and bonus XP.")
                    .font(.alegreyaSans(17))
                    .foregroundStyle(Theme.inkSecondary)
                    .padding(.top, 6)

                VStack(spacing: 12) {
                    ForEach(GuildClass.allCases) { guildClass in
                        ClassOption(guildClass: guildClass, isSelected: guildClass == selectedClass) {
                            withAnimation(.snappy(duration: 0.2)) { selectedClass = guildClass }
                        }
                    }
                }
                .padding(.top, 16)

                Text("Goals and program selection are coming soon.")
                    .font(.alegreyaSans(14))
                    .foregroundStyle(Theme.inkSecondary)
                    .padding(.top, 16)

                Button("Enter the Guild Hall", action: onFinish)
                    .buttonStyle(.chunky(.emerald))
                    .padding(.top, 16)
            }
        }
    }
}

private struct ClassOption: View {
    let guildClass: GuildClass
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ClassEmblem(guildClass: guildClass, size: 46)
                VStack(alignment: .leading, spacing: 0) {
                    Text(guildClass.name)
                        .font(.alegreya(19, weight: .heavy))
                        .foregroundStyle(Theme.ink)
                    Text(guildClass.focus)
                        .font(.alegreyaSans(15))
                        .foregroundStyle(Theme.inkSecondary)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(isSelected ? guildClass.palette.fill : Theme.outline.opacity(0.5))
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? guildClass.palette.fill.opacity(0.15) : Theme.checkboxFill))
            .overlay(RoundedRectangle(cornerRadius: 12)
                .strokeBorder(isSelected ? guildClass.palette.border : Theme.outline.opacity(0.4),
                              lineWidth: isSelected ? 3 : 2))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    NavigationStack {
        OnboardingView(onFinish: {}, onBack: {})
    }
}
