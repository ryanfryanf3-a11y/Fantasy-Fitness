//
//  PinnedNotesGrid.swift
//  Fantasy Fitness
//

import SwiftUI

/// Side notes pinned below the featured quest: nutrition, sleep and guild notices.
struct PinnedNotesGrid: View {
    // Hard-coded until meal logs / HealthKit / exams are wired up.
    private let rations = DailyRations.sample
    private let sleepGoalHours = 8

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
                    ParchmentProgressBar(progress: Double(rations.eaten.protein) / Double(rations.target.protein))
                        .padding(.top, 8)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Ration duty. Protein today, \(rations.eaten.protein) of \(rations.target.protein) grams")

                PinnedNote(rotation: 1.2) {
                    NoteHeading(title: "Rest at the inn", subtitle: "Sleep goal tonight")
                    Text("\(sleepGoalHours) hours")
                        .font(.alegreyaSans(22, weight: .bold))
                        .foregroundStyle(Theme.ink)
                        .padding(.top, 6)
                    Text("Earns Well-Rested buff")
                        .font(.alegreyaSans(15, weight: .bold))
                        .foregroundStyle(Theme.positiveText)
                        .padding(.top, 4)
                }
                .accessibilityElement(children: .combine)
            }
            .fixedSize(horizontal: false, vertical: true)

            ExamNoticeCard(exam: .sample) {
                // TODO: launch Workout session in exam mode
            }
        }
    }
}

#Preview {
    PinnedNotesGrid()
        .padding()
        .background(WoodBackground())
}
