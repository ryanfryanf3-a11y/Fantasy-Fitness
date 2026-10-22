//
//  Dungeon.swift
//  Fantasy Fitness
//

import Foundation

struct Dungeon: Identifiable, Hashable {
    enum Status: Hashable {
        case cleared
        case available
        /// Locked behind a guild rank, e.g. "Requires D-rank".
        case locked(requirement: String)
    }

    let id: String
    let name: String
    let tier: String
    let boss: String
    let bossHealth: Int
    let energyCost: Int
    let status: Status
    let systemImage: String
    /// Position on the map, 0…1 in both axes.
    let mapPosition: CGPoint
}

// MARK: - Sample data (previews and offline demo mode)

extension Dungeon {
    static let sampleMap: [Dungeon] = [
        Dungeon(id: "goblin-cellar", name: "Goblin Cellar", tier: "F-tier", boss: "Goblin Brute",
                bossHealth: 60, energyCost: 1, status: .cleared, systemImage: "flame.fill",
                mapPosition: CGPoint(x: 0.22, y: 0.86)),
        Dungeon(id: "mossy-crypt", name: "Mossy Crypt", tier: "E-tier", boss: "Moss Golem",
                bossHealth: 100, energyCost: 1, status: .available, systemImage: "leaf.fill",
                mapPosition: CGPoint(x: 0.7, y: 0.62)),
        Dungeon(id: "sunken-mine", name: "Sunken Mine", tier: "E-tier", boss: "Ore Wyrm",
                bossHealth: 140, energyCost: 2, status: .available, systemImage: "mountain.2.fill",
                mapPosition: CGPoint(x: 0.28, y: 0.4)),
        Dungeon(id: "iron-keep", name: "Iron Keep", tier: "D-tier", boss: "Iron Warden",
                bossHealth: 220, energyCost: 2, status: .locked(requirement: "Requires D-rank"),
                systemImage: "building.columns.fill", mapPosition: CGPoint(x: 0.72, y: 0.14)),
    ]
}
