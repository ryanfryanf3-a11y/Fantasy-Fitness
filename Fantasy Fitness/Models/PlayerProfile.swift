//
//  PlayerProfile.swift
//  Fantasy Fitness
//

import Foundation

enum GuildClass: String, CaseIterable, Identifiable {
    case warrior, ranger, monk, paladin

    var id: Self { self }

    var name: String { rawValue.capitalized }

    var focus: String {
        switch self {
        case .warrior: "Strength"
        case .ranger: "Endurance"
        case .monk: "Calisthenics"
        case .paladin: "Hybrid"
        }
    }
}

enum StatKind: String, CaseIterable, Identifiable {
    case strength, endurance, speed, agility, vitality

    var id: Self { self }

    var name: String { rawValue.capitalized }

    /// Where the stat comes from in real life.
    var source: String {
        switch self {
        case .strength: "Compound lifts, PRs, volume"
        case .endurance: "Cardio duration and volume"
        case .speed: "Pace and sprint times"
        case .agility: "Plyometrics and drills"
        case .vitality: "Sleep, protein and calorie targets"
        }
    }
}

/// Read-only view of the player. XP, stats and inventory are computed server-side.
struct PlayerProfile {
    let displayName: String
    let guildClass: GuildClass
    let rank: String
    let level: Int
    let xp: Int
    let xpForNextLevel: Int
    let energy: Int
    let maxEnergy: Int
    let stats: [StatKind: Int]
    let equipped: [Item]

    var levelProgress: Double { Double(xp) / Double(xpForNextLevel) }
}

// MARK: - Hard-coded sample data (replace with SwiftData / Supabase)

extension PlayerProfile {
    static let sample = PlayerProfile(
        displayName: "Rowan",
        guildClass: .warrior,
        rank: "E",
        level: 14,
        xp: 2_340,
        xpForNextLevel: 3_000,
        energy: 3,
        maxEnergy: 5,
        stats: [.strength: 42, .endurance: 28, .speed: 19, .agility: 23, .vitality: 35],
        equipped: [.ironHelm, .leatherJerkin, .oakLongsword, .emberCharm]
    )
}
