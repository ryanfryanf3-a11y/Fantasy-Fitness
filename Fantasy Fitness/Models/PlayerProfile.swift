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
    var displayName: String
    var guildClass: GuildClass
    var rank: String
    var level: Int
    /// Total XP, plus the totals where the current and next level start.
    var xp: Int
    var levelStartXP: Int
    var nextLevelXP: Int
    var energy: Int
    var maxEnergy: Int
    var bodyweightLb: Double?
    var stats: [StatKind: Int]
    var equipped: [Item]
    var hasCompletedOnboarding: Bool

    var levelProgress: Double {
        let span = nextLevelXP - levelStartXP
        return span > 0 ? Double(xp - levelStartXP) / Double(span) : 0
    }
}

// MARK: - Sample data (previews and offline demo mode)

extension PlayerProfile {
    static let sample = PlayerProfile(
        displayName: "Rowan",
        guildClass: .warrior,
        rank: "E",
        level: 14,
        xp: 20_340,
        levelStartXP: 18_200,
        nextLevelXP: 21_000,
        energy: 3,
        maxEnergy: 5,
        bodyweightLb: 185,
        stats: [.strength: 42, .endurance: 28, .speed: 19, .agility: 23, .vitality: 35],
        equipped: [.ironHelm, .leatherJerkin, .oakLongsword, .emberCharm],
        hasCompletedOnboarding: true
    )

    /// Shown for a moment while a signed-in player's profile loads.
    static let empty = PlayerProfile(
        displayName: "Adventurer", guildClass: .warrior, rank: "F", level: 1,
        xp: 0, levelStartXP: 0, nextLevelXP: 200, energy: 0, maxEnergy: 5, bodyweightLb: nil,
        stats: [:], equipped: [], hasCompletedOnboarding: false
    )
}
