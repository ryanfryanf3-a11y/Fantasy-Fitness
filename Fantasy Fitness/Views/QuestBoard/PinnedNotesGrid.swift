//
//  PinnedNotesGrid.swift
//  Fantasy Fitness
//

import SwiftUI

/// Side notes pinned below the featured quest: nutrition, sleep, steps and guild notices.
struct PinnedNotesGrid: View {
    var kind: QuestKind = .daily

    @Environment(GameStore.self) private var store

    private var rations: DailyRations { store.rations }
    private var isWeekly: Bool { kind == .weekly }

    private var weeklyStepDaysHit: Int {
        store.healthKit.weeklySteps.filter(\.isComplete).count
    }

    private var weeklySleepNightsHit: Int {
        store.healthKit.weeklySleep.filter(\.isComplete).count
    }

    var body: some View {
        VStack(spacing: 26) {
            HStack(alignment: .top, spacing: 14) {
                PinnedNote(rotation: -1.5) {
                    NoteHeading(title: "Ration duty", subtitle: "Protein today")
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(rations.eaten.protein)")
                            .font(.alegreyaSans(22, weight: .bold))
                            .foregroundStyle(Theme.ink)
                        Text("/ \(rations.target.protein) g")
                            .font(.alegreyaSans(16))
                            .foregroundStyle(Theme.inkSecondary)
                    }
                    .padding(.top, 6)
                    ParchmentProgressBar(progress: rations.progress(\.protein))
                        .padding(.top, 8)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Ration duty. Protein today, \(rations.eaten.protein) of \(rations.target.protein) grams")

                if isWeekly {
                    PinnedNote(rotation: 1.2) {
                        NoteHeading(title: "Rest at the inn", subtitle: "4 nights this week")
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(weeklySleepNightsHit)")
                                .font(.alegreyaSans(22, weight: .bold))
                                .foregroundStyle(Theme.ink)
                            Text("/ 4 nights")
                                .font(.alegreyaSans(16))
                                .foregroundStyle(Theme.inkSecondary)
                        }
                        .padding(.top, 6)
                        WeekDayStrip(days: store.healthKit.weeklySleep, compact: true)
                            .padding(.top, 8)
                    }
                } else {
                    PinnedNote(rotation: 1.2) {
                        NoteHeading(title: "Rest at the inn", subtitle: "Sleep goal each night")
                        Text("\(Recovery.wellRestedHours.formatted())+ hours")
                            .font(.alegreyaSans(22, weight: .bold))
                            .foregroundStyle(Theme.ink)
                            .padding(.top, 6)
                        Text(store.sleep.isWellRested ? "Well-Rested today" : "Earns Well-Rested buff")
                            .font(.alegreyaSans(15, weight: .bold))
                            .foregroundStyle(Theme.positiveText)
                            .padding(.top, 4)
                        SleepCheckButton(label: "Slept 7+ h last night")
                            .padding(.top, 6)
                    }
                }
            }
            .fixedSize(horizontal: false, vertical: true)

            if isWeekly {
                weeklyMarchCard
            } else {
                dailyMarchCard
            }

            if let exam = store.unlockedExam {
                ExamNoticeCard(exam: exam) {
                    // TODO: launch Workout session in exam mode
                }
            }
        }
    }

    private var dailyMarchCard: some View {
        PinnedNote(rotation: -0.6) {
            HStack(alignment: .center, spacing: 14) {
                VStack(alignment: .leading, spacing: 0) {
                    NoteHeading(title: "Daily march", subtitle: "Steps today · Apple Health")
                    if store.healthKit.isAuthorized {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(store.healthKit.todaySteps.formatted())
                                .font(.alegreyaSans(22, weight: .bold))
                                .foregroundStyle(Theme.ink)
                            Text("/ \(DailySteps.goal.formatted()) steps")
                                .font(.alegreyaSans(16))
                                .foregroundStyle(Theme.inkSecondary)
                        }
                        .padding(.top, 6)
                        if store.healthKit.todaySteps >= DailySteps.goal {
                            Text("Goal reached today")
                                .font(.alegreyaSans(15, weight: .bold))
                                .foregroundStyle(Theme.positiveText)
                                .padding(.top, 4)
                        }
                    } else {
                        Text("Connect Apple Health to track your \(DailySteps.goal.formatted())-step goal.")
                            .font(.alegreyaSans(15))
                            .foregroundStyle(Theme.inkSecondary)
                            .padding(.top, 6)
                    }
                }

                Spacer(minLength: 0)

                if !store.healthKit.isAuthorized && store.healthKit.isAvailable {
                    Button("Connect") {
                        Task { await store.connectHealthKit() }
                    }
                    .buttonStyle(.chunky(.amethyst, minHeight: 44, fullWidth: false, fontSize: 16))
                }
            }

            if store.healthKit.isAuthorized {
                ParchmentProgressBar(progress: DailySteps.progress(steps: store.healthKit.todaySteps))
                    .padding(.top, 10)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var weeklyMarchCard: some View {
        PinnedNote(rotation: -0.6) {
            HStack(alignment: .center, spacing: 14) {
                VStack(alignment: .leading, spacing: 0) {
                    NoteHeading(title: "Weekly march", subtitle: "Hit \(DailySteps.goal.formatted()) steps · 5 days this week")
                    if store.healthKit.isAuthorized {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(weeklyStepDaysHit)")
                                .font(.alegreyaSans(22, weight: .bold))
                                .foregroundStyle(Theme.ink)
                            Text("/ 5 days")
                                .font(.alegreyaSans(16))
                                .foregroundStyle(Theme.inkSecondary)
                        }
                        .padding(.top, 6)
                    } else {
                        Text("Connect Apple Health to track your weekly step days.")
                            .font(.alegreyaSans(15))
                            .foregroundStyle(Theme.inkSecondary)
                            .padding(.top, 6)
                    }
                }

                Spacer(minLength: 0)

                if !store.healthKit.isAuthorized && store.healthKit.isAvailable {
                    Button("Connect") {
                        Task { await store.connectHealthKit() }
                    }
                    .buttonStyle(.chunky(.amethyst, minHeight: 44, fullWidth: false, fontSize: 16))
                }
            }

            if store.healthKit.isAuthorized {
                WeekDayStrip(days: store.healthKit.weeklySteps, compact: false)
                    .padding(.top, 10)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

/// Seven-day Mon–Sun checkmark strip matching the parchment checkbox style.
private struct WeekDayStrip: View {
    let days: [DayCheck]
    let compact: Bool

    private var displayDays: [DayCheck] {
        if !days.isEmpty { return days }
        return ["M", "T", "W", "T", "F", "S", "S"].enumerated().map {
            DayCheck(id: "placeholder-\($0.offset)", label: $0.element, isComplete: false, isToday: false)
        }
    }

    var body: some View {
        HStack(spacing: compact ? 4 : 8) {
            ForEach(displayDays) { day in
                VStack(spacing: 3) {
                    Text(day.label)
                        .font(.alegreyaSans(compact ? 11 : 13, weight: day.isToday ? .heavy : .bold))
                        .foregroundStyle(day.isToday ? Theme.ink : Theme.inkSecondary)
                    ZStack {
                        RoundedRectangle(cornerRadius: compact ? 5 : 7)
                            .fill(day.isComplete ? Theme.progressGreen : Theme.checkboxFill)
                        RoundedRectangle(cornerRadius: compact ? 5 : 7)
                            .strokeBorder(Theme.outline, lineWidth: day.isToday ? 2.5 : 1.5)
                        if day.isComplete {
                            Image(systemName: "checkmark")
                                .font(.system(size: compact ? 9 : 13, weight: .heavy))
                                .foregroundStyle(Theme.cream)
                        }
                    }
                    .frame(width: compact ? 18 : 30, height: compact ? 18 : 30)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

#Preview {
    PinnedNotesGrid(kind: .weekly)
        .padding()
        .background(WoodBackground())
        .environment(GameStore.preview)
}
