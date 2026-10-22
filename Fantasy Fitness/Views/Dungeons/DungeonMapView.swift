//
//  DungeonMapView.swift
//  Fantasy Fitness
//

import SwiftUI

/// Dungeon map → Loadout → Battle → Loot reveal.
struct DungeonMapView: View {
    @Environment(GameStore.self) private var store

    var body: some View {
        BoardScreen {
            PlayerStatusBar(profile: store.player)
            BoardSign(title: "Dungeons")

            ParchmentScroll(contentPadding: EdgeInsets(top: 24, leading: 8, bottom: 24, trailing: 8)) {
                DungeonMap(dungeons: store.dungeons)
                    .frame(height: 460)
            }

            ParchmentCard(padding: 16) {
                NoteHeading(title: "How runs work")
                Text("Each run costs Energy. Clear a dungeon to earn loot that boosts your in-game power. Higher tiers unlock as your guild rank rises.")
                    .font(.alegreyaSans(15))
                    .foregroundStyle(Theme.inkSecondary)
                    .padding(.top, 6)
            }
        }
        .navigationDestination(for: Dungeon.self) { dungeon in
            LoadoutView(dungeon: dungeon)
        }
        .gearDestinations()
    }
}

private struct DungeonMap: View {
    let dungeons: [Dungeon]

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                trail(in: size)
                scenery(in: size)
                ForEach(dungeons) { dungeon in
                    DungeonNode(dungeon: dungeon)
                        .position(x: dungeon.mapPosition.x * size.width,
                                  y: dungeon.mapPosition.y * size.height)
                }
            }
        }
    }

    /// Dashed ink trail linking the dungeons in order.
    private func trail(in size: CGSize) -> some View {
        Path { path in
            for (index, dungeon) in dungeons.enumerated() {
                let point = CGPoint(x: dungeon.mapPosition.x * size.width, y: dungeon.mapPosition.y * size.height)
                if index == 0 {
                    path.move(to: point)
                } else {
                    let previous = dungeons[index - 1].mapPosition
                    let control = CGPoint(x: (previous.x * size.width + point.x) / 2 + 40,
                                          y: (previous.y * size.height + point.y) / 2)
                    path.addQuadCurve(to: point, control: control)
                }
            }
        }
        .stroke(Theme.inkSecondary.opacity(0.6), style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [2, 9]))
        .accessibilityHidden(true)
    }

    private func scenery(in size: CGSize) -> some View {
        ZStack {
            ForEach(Array([(0.08, 0.12), (0.16, 0.2), (0.88, 0.42), (0.52, 0.86), (0.92, 0.9), (0.06, 0.6)].enumerated()),
                    id: \.offset) { _, spot in
                Image(systemName: "tree.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Theme.emerald.opacity(0.45))
                    .position(x: spot.0 * size.width, y: spot.1 * size.height)
            }
            Image(systemName: "location.north.circle")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(Theme.kicker.opacity(0.6))
                .position(x: size.width - 30, y: 24)
        }
        .accessibilityHidden(true)
    }
}

private struct DungeonNode: View {
    let dungeon: Dungeon

    var body: some View {
        switch dungeon.status {
        case .locked:
            content
        case .available, .cleared:
            NavigationLink(value: dungeon) { content }
                .buttonStyle(.plain)
        }
    }

    private var content: some View {
        VStack(spacing: 6) {
            EmblemBadge(palette: palette, size: 60) {
                Image(systemName: icon)
            }
            .overlay(alignment: .topTrailing) {
                if dungeon.status == .cleared {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundStyle(Theme.cream)
                        .frame(width: 22, height: 22)
                        .background(Circle().fill(Theme.progressGreen))
                        .overlay(Circle().strokeBorder(Theme.outline, lineWidth: 2))
                        .offset(x: 4, y: -4)
                }
            }

            VStack(spacing: 0) {
                Text(dungeon.name)
                    .font(.alegreya(15, weight: .heavy))
                    .foregroundStyle(Theme.ink)
                Text(caption)
                    .font(.alegreyaSans(13, weight: .medium))
                    .foregroundStyle(Theme.inkSecondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(RoundedRectangle(cornerRadius: 6).fill(Theme.parchment.opacity(0.9)))
        }
        .fixedSize()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(dungeon.name), \(dungeon.tier). \(caption)")
    }

    private var palette: CartoonPalette {
        switch dungeon.status {
        case .cleared: .emerald
        case .available: .wax
        case .locked: .wood
        }
    }

    private var icon: String {
        if case .locked = dungeon.status { return "lock.fill" }
        return dungeon.systemImage
    }

    private var caption: String {
        switch dungeon.status {
        case .cleared: "Cleared · \(dungeon.tier)"
        case .available: "\(dungeon.tier) · \(dungeon.energyCost) Energy"
        case .locked(let requirement): requirement
        }
    }
}

#Preview {
    NavigationStack {
        DungeonMapView()
    }
    .environment(GameStore.preview)
}
