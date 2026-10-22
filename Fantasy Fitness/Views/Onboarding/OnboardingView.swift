//
//  OnboardingView.swift
//  Fantasy Fitness
//

import SwiftUI

/// First-login setup, saved to the player's Supabase profile. Goals and program
/// selection are still to come.
struct OnboardingView: View {
    let onFinish: () -> Void
    let onBack: () -> Void

    @Environment(GameStore.self) private var store
    @State private var selectedClass: GuildClass = .warrior
    @State private var displayName = ""
    @State private var bodyweight = ""
    @State private var isSaving = false

    var body: some View {
        BoardScreen {
            HStack {
                WoodIconButton(systemImage: "chevron.left", accessibilityLabel: "Back to title", action: onBack)
                Spacer()
            }

            BoardSign(title: "Join the Guild", fontSize: 40)

            ParchmentCard {
                KickerText("Your adventurer")
                VStack(spacing: 14) {
                    ParchmentField(title: "Name", text: $displayName, prompt: store.player.displayName,
                                   contentType: .nickname)
                    ParchmentField(title: "Bodyweight (lb, optional)", text: $bodyweight, prompt: "180",
                                   keyboard: .decimalPad)
                }
                .padding(.top, 10)
                Text("Rank exams are set relative to bodyweight. It stays private.")
                    .font(.alegreyaSans(14))
                    .foregroundStyle(Theme.inkSecondary)
                    .padding(.top, 6)

                KickerText("Choose your class")
                    .padding(.top, 20)
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

                Button {
                    Task { await save() }
                } label: {
                    if isSaving {
                        ProgressView().tint(Theme.cream)
                    } else {
                        Text("Enter the Guild Hall")
                    }
                }
                .buttonStyle(.chunky(.emerald))
                .disabled(isSaving)
                .padding(.top, 16)
            }
        }
    }
}

extension OnboardingView {
    private func save() async {
        isSaving = true
        defer { isSaving = false }
        let weight = Double(bodyweight.replacingOccurrences(of: ",", with: "."))
        if await store.completeOnboarding(guildClass: selectedClass, displayName: displayName,
                                          bodyweightLb: weight.flatMap { (60...700).contains($0) ? $0 : nil }) {
            onFinish()
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
    .environment(GameStore.preview)
}
