//
//  Quest.swift
//  Fantasy Fitness
//

import Foundation

enum QuestKind: String, CaseIterable, Identifiable {
    case daily, weekly, story

    var id: Self { self }

    var title: String {
        switch self {
        case .daily: "Daily"
        case .weekly: "Weekly"
        case .story: "Story"
        }
    }

    var actionLabel: String {
        switch self {
        case .daily: "Begin quest"
        case .weekly: "View progress"
        case .story: "Continue story"
        }
    }
}

/// Objectives complete automatically from logged data; the UI never toggles them.
struct QuestObjective: Identifiable {
    let id = UUID()
    let name: String
    let detail: String
    let isComplete: Bool
}

struct Quest {
    let kind: QuestKind
    let arc: String
    let title: String
    let objectives: [QuestObjective]
    let rewards: [String]

    var completedCount: Int { objectives.filter(\.isComplete).count }

    var progress: Double {
        objectives.isEmpty ? 0 : Double(completedCount) / Double(objectives.count)
    }

    var kicker: String { "\(kind.title) quest · \(arc)" }
}

// MARK: - Hard-coded sample data (replace with SwiftData / Supabase)

extension Quest {
    static let sampleDaily = Quest(
        kind: .daily,
        arc: "Iron Trial, week 3",
        title: "Push Day",
        objectives: [
            QuestObjective(name: "Bench press", detail: "4 × 6 @ 155 lb", isComplete: true),
            QuestObjective(name: "Overhead press", detail: "3 × 8 @ 95 lb", isComplete: false),
            QuestObjective(name: "Incline dumbbell press", detail: "3 × 10 @ 50 lb", isComplete: false),
            QuestObjective(name: "Triceps dips", detail: "3 × 12", isComplete: false),
        ],
        rewards: ["+120 XP", "+ Strength", "Common chest"]
    )

    static let sampleWeekly = Quest(
        kind: .weekly,
        arc: "Iron Trial, week 3",
        title: "Forge Week",
        objectives: [
            QuestObjective(name: "Complete 4 workouts", detail: "2 of 4 logged", isComplete: false),
            QuestObjective(name: "Hit protein goal", detail: "5 days · 3 of 5", isComplete: false),
            QuestObjective(name: "Sleep 7+ hours", detail: "4 nights · 4 of 4", isComplete: true),
            QuestObjective(name: "Walk or jog 10 km", detail: "6.2 of 10 km", isComplete: false),
        ],
        rewards: ["+400 XP", "+ Vitality", "Uncommon chest"]
    )

    static let sampleStory = Quest(
        kind: .story,
        arc: "Iron Trial, chapter 1",
        title: "The Iron Trial",
        objectives: [
            QuestObjective(name: "Week 1: Foundations", detail: "Learn the main lifts", isComplete: true),
            QuestObjective(name: "Week 2: Building heat", detail: "Add volume", isComplete: true),
            QuestObjective(name: "Week 3: The forge", detail: "Heavier top sets", isComplete: false),
            QuestObjective(name: "Week 4: Deload", detail: "Lighter week to recover", isComplete: false),
        ],
        rewards: ["+800 XP", "Rare chest", "Title: Ironbound"]
    )

    static func sample(for kind: QuestKind) -> Quest {
        switch kind {
        case .daily: sampleDaily
        case .weekly: sampleWeekly
        case .story: sampleStory
        }
    }
}
