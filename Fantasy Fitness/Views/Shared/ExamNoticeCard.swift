//
//  ExamNoticeCard.swift
//  Fantasy Fitness
//

import SwiftUI

/// Pinned guild notice for an unlocked rank exam. Shown on the Guild Hall and Quest board.
struct ExamNoticeCard: View {
    let exam: RankExam
    var rotation: Double = -0.6
    let onViewExam: () -> Void

    var body: some View {
        PinnedNote(rotation: rotation) {
            HStack(alignment: .center, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    NoteHeading(title: "Guild notice", subtitle: "Rank exam unlocked")
                    Text(exam.standard)
                        .font(.alegreyaSans(16, weight: .bold))
                        .foregroundStyle(Theme.ink)
                    Text("Target \(exam.targetWeight) lb")
                        .font(.alegreyaSans(14, weight: .medium))
                        .foregroundStyle(Theme.inkSecondary)
                }
                Spacer(minLength: 0)
                Button("View exam", action: onViewExam)
                    .buttonStyle(.chunky(.wax, minHeight: 44, fullWidth: false, fontSize: 16))
            }
        }
    }
}
