//
//  BattleView.swift
//  Fantasy Fitness
//

import SwiftUI

/// Turn-based stand-in for the SpriteKit battle. Damage numbers are hard-coded;
/// the real outcome and loot will come from the server.
struct BattleView: View {
    let dungeon: Dungeon
    let profile: PlayerProfile
    let onFinish: () -> Void

    private enum Phase { case fighting, victory, defeat }

    @State private var bossHealth: Int
    @State private var playerHealth = 100
    @State private var phase: Phase = .fighting
    @State private var log = "The boss stirs. Make your move."

    private var attack: Int { (profile.stats[.strength] ?? 0) / 2 + 5 }

    init(dungeon: Dungeon, profile: PlayerProfile, onFinish: @escaping () -> Void) {
        self.dungeon = dungeon
        self.profile = profile
        self.onFinish = onFinish
        _bossHealth = State(initialValue: dungeon.bossHealth)
    }

    var body: some View {
        switch phase {
        case .victory:
            LootRevealView(loot: .sampleDungeon, onCollect: onFinish)
        case .fighting, .defeat:
            arena
        }
    }

    private var arena: some View {
        VStack(spacing: 20) {
            HStack {
                WoodIconButton(systemImage: "xmark", accessibilityLabel: "Flee", action: onFinish)
                Spacer()
                Text(dungeon.name)
                    .font(.pirata(30))
                    .foregroundStyle(Theme.gold)
                Spacer()
                Color.clear.frame(width: 44, height: 44)
            }

            Spacer(minLength: 0)

            combatant(name: dungeon.boss, health: bossHealth, maxHealth: dungeon.bossHealth, tint: Theme.waxRed) {
                EmblemBadge(palette: .wax, size: 110, shadowOffset: 6) {
                    Image(systemName: dungeon.systemImage)
                }
            }

            Text("VS")
                .font(.pirata(36))
                .foregroundStyle(Theme.cream)

            combatant(name: profile.displayName, health: playerHealth, maxHealth: 100, tint: Theme.progressGreen) {
                ClassEmblem(guildClass: profile.guildClass, size: 72)
            }

            Text(log)
                .font(.alegreyaSans(17, weight: .medium))
                .foregroundStyle(Theme.cream)
                .multilineTextAlignment(.center)
                .frame(minHeight: 48)

            Spacer(minLength: 0)

            if phase == .defeat {
                Button("Return to the inn", action: onFinish)
                    .buttonStyle(.chunky(.wood))
            } else {
                HStack(spacing: 12) {
                    Button { takeTurn(guarding: false) } label: {
                        Label("Strike", systemImage: "bolt.fill")
                    }
                    .buttonStyle(.chunky(.wax))
                    Button { takeTurn(guarding: true) } label: {
                        Label("Guard", systemImage: "shield.fill")
                    }
                    .buttonStyle(.chunky(.wood))
                }
            }
        }
        .padding(16)
        .background(WoodBackground())
    }

    private func combatant<Portrait: View>(name: String, health: Int, maxHealth: Int, tint: Color,
                                           @ViewBuilder portrait: () -> Portrait) -> some View {
        ParchmentCard(padding: 16) {
            HStack(spacing: 16) {
                portrait()
                VStack(alignment: .leading, spacing: 6) {
                    Text(name)
                        .font(.alegreya(20, weight: .heavy))
                        .foregroundStyle(Theme.ink)
                    ParchmentProgressBar(progress: Double(health) / Double(maxHealth), height: 14, tint: tint)
                    Text("\(health) / \(maxHealth) HP")
                        .font(.alegreyaSans(14, weight: .bold))
                        .foregroundStyle(Theme.inkSecondary)
                        .monospacedDigit()
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(name), \(health) of \(maxHealth) health")
    }

    private func takeTurn(guarding: Bool) {
        withAnimation(.snappy) {
            if !guarding {
                bossHealth = max(bossHealth - attack, 0)
            }
            if bossHealth == 0 {
                phase = .victory
                return
            }
            let hit = guarding ? 4 : 12
            playerHealth = max(playerHealth - hit, 0)
            log = guarding
                ? "You brace yourself. \(dungeon.boss) hits for \(hit)."
                : "You strike for \(attack)! \(dungeon.boss) hits back for \(hit)."
            if playerHealth == 0 {
                phase = .defeat
                log = "You fall back to rest. No stats lost, so train up and try again."
            }
        }
    }
}

#Preview {
    BattleView(dungeon: Dungeon.sampleMap[1], profile: .sample, onFinish: {})
}
