//
//  PinnedNotesGrid.swift
//  Fantasy Fitness
//

import SwiftUI

/// Side notes pinned below the featured quest: nutrition, sleep and guild notices.
struct PinnedNotesGrid: View {
    // Hard-coded until meal logs / HealthKit / exams are wired up.
    private let proteinToday = 92
    private let proteinGoal = 160
    private let sleepGoalHours = 8

    var body: some View {
        VStack(spacing: 26) {
            HStack(alignment: .top, spacing: 14) {
                PinnedNote(rotation: -1.5) {
                    noteTitle("Ration duty")
                    noteSubtitle("Protein today")
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(proteinToday)")
                            .font(.alegreyaSans(22, weight: .bold))
                            .foregroundStyle(Theme.ink)
                        Text("/ \(proteinGoal) g")
                            .font(.alegreyaSans(16))
                            .foregroundStyle(Theme.inkSecondary)
                    }
                    .padding(.top, 6)
                    ParchmentProgressBar(progress: Double(proteinToday) / Double(proteinGoal), height: 14)
                        .padding(.top, 8)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Ration duty. Protein today, \(proteinToday) of \(proteinGoal) grams")

                PinnedNote(rotation: 1.2) {
                    noteTitle("Rest at the inn")
                    noteSubtitle("Sleep goal tonight")
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

            PinnedNote(rotation: -0.6) {
                HStack(alignment: .center, spacing: 14) {
                    VStack(alignment: .leading, spacing: 0) {
                        noteTitle("Guild notice")
                        noteSubtitle("Rank exam unlocked")
                        Text("D-rank bench · 1.0× bodyweight")
                            .font(.alegreyaSans(16, weight: .bold))
                            .foregroundStyle(Theme.ink)
                            .padding(.top, 6)
                    }
                    Spacer(minLength: 0)
                    Button {
                        // TODO: launch Workout session in exam mode
                    } label: {
                        Text("View exam")
                            .font(.alegreya(16, weight: .heavy))
                            .foregroundStyle(Theme.cream)
                            .padding(.horizontal, 14)
                            .frame(minHeight: 44)
                            .cartoonBackground(RoundedRectangle(cornerRadius: 10), fill: Theme.waxRed,
                                               outline: Theme.waxBorder, shadowOffset: 3)
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }
        }
    }

    private func noteTitle(_ text: String) -> some View {
        Text(text)
            .font(.alegreya(20, weight: .heavy))
            .foregroundStyle(Theme.ink)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
    }

    private func noteSubtitle(_ text: String) -> some View {
        Text(text)
            .font(.alegreyaSans(16))
            .foregroundStyle(Theme.inkSecondary)
            .padding(.top, 2)
    }
}

/// A parchment note with a brass pin, slight tilt and hard shadow.
private struct PinnedNote<Content: View>: View {
    var rotation: Double = 0
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .padding(.horizontal, 16)
        .padding(.top, 26)
        .padding(.bottom, 18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .cartoonBackground(RoundedRectangle(cornerRadius: 6), fill: Theme.noteParchment,
                           lineWidth: 3, shadowOffset: 5)
        .overlay(alignment: .top) {
            Circle()
                .fill(Theme.brass)
                .overlay(Circle().strokeBorder(Theme.outline, lineWidth: 2.5))
                .frame(width: 24, height: 24)
                .offset(y: -12)
                .accessibilityHidden(true)
        }
        .rotationEffect(.degrees(rotation))
    }
}

#Preview {
    PinnedNotesGrid()
        .padding()
        .background(WoodBackground())
}
