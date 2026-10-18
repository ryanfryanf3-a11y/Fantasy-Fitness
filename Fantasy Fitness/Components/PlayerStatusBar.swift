//
//  PlayerStatusBar.swift
//  Fantasy Fitness
//

import SwiftUI

/// Rank / level pill and Energy pill shown at the top of board screens.
struct PlayerStatusBar: View {
    let profile: PlayerProfile

    var body: some View {
        HStack {
            WoodPill {
                Text(profile.rank)
                    .font(.alegreya(16, weight: .heavy))
                    .foregroundStyle(Theme.ink)
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(Theme.gold))
                    .overlay(Circle().strokeBorder(Theme.darkestWood, lineWidth: 2))
                    .padding(.leading, -8)
                Text("Level \(profile.level)")
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Rank \(profile.rank), level \(profile.level)")

            Spacer()

            EnergyPill(energy: profile.energy, maxEnergy: profile.maxEnergy)
        }
    }
}

struct EnergyPill: View {
    let energy: Int
    let maxEnergy: Int

    var body: some View {
        WoodPill {
            Image(systemName: "bolt")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.gold)
            Text("Energy \(energy) / \(maxEnergy)")
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Energy \(energy) of \(maxEnergy)")
    }
}
