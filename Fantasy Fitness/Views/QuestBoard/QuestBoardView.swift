//
//  QuestBoardView.swift
//  Fantasy Fitness
//

import SwiftUI

struct QuestBoardView: View {
    @State private var selectedKind: QuestKind = .daily

    // Hard-coded until profile / quest data is wired up.
    private let rank = "E"
    private let level = 14
    private let energy = 3
    private let maxEnergy = 5

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header
                BoardSign(title: "Quest Board")
                QuestKindPicker(selection: $selectedKind)
                QuestScroll(quest: .sample(for: selectedKind)) {
                    // TODO: present Workout session via .fullScreenCover
                }
                .padding(.top, 4)
                PinnedNotesGrid()
                    .padding(.top, 8)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .background(WoodBackground())
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        HStack {
            HStack(spacing: 10) {
                Text(rank)
                    .font(.alegreya(16, weight: .heavy))
                    .foregroundStyle(Theme.ink)
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(Theme.gold))
                    .overlay(Circle().strokeBorder(Theme.darkestWood, lineWidth: 2))
                Text("Level \(level)")
                    .font(.alegreyaSans(17, weight: .bold))
                    .foregroundStyle(Theme.cream)
            }
            .padding(.leading, 8)
            .padding(.trailing, 18)
            .frame(minHeight: 46)
            .cartoonBackground(Capsule(), fill: Theme.darkerWood, outline: Theme.darkestWood, shadowOffset: 3)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Rank \(rank), level \(level)")

            Spacer()

            HStack(spacing: 8) {
                Image(systemName: "bolt")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Theme.gold)
                Text("Energy \(energy) / \(maxEnergy)")
                    .font(.alegreyaSans(17, weight: .bold))
                    .foregroundStyle(Theme.cream)
            }
            .padding(.horizontal, 18)
            .frame(minHeight: 46)
            .cartoonBackground(Capsule(), fill: Theme.darkerWood, outline: Theme.darkestWood, shadowOffset: 3)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Energy \(energy) of \(maxEnergy)")
        }
    }
}

// MARK: - Sign

private struct BoardSign: View {
    let title: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            brassDot
            Text(title)
                .font(.pirata(44))
                .foregroundStyle(Theme.gold)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            brassDot
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .cartoonBackground(RoundedRectangle(cornerRadius: 12), fill: Theme.darkWood,
                           outline: Theme.darkestWood, lineWidth: 4, shadowOffset: 6)
        .accessibilityAddTraits(.isHeader)
    }

    private var brassDot: some View {
        Circle()
            .fill(Theme.gold)
            .overlay(Circle().strokeBorder(Theme.darkestWood, lineWidth: 2))
            .frame(width: 12, height: 12)
            .padding(.top, 10)
            .accessibilityHidden(true)
    }
}

// MARK: - Tabs

private struct QuestKindPicker: View {
    @Binding var selection: QuestKind

    var body: some View {
        HStack(spacing: 10) {
            ForEach(QuestKind.allCases) { kind in
                let isSelected = kind == selection
                Button {
                    withAnimation(.snappy(duration: 0.2)) { selection = kind }
                } label: {
                    Text(kind.title)
                        .font(.alegreya(18, weight: .heavy))
                        .foregroundStyle(isSelected ? Theme.ink : Theme.cream)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .cartoonBackground(RoundedRectangle(cornerRadius: 10),
                                           fill: isSelected ? Theme.gold : Theme.darkWood,
                                           outline: Theme.darkestWood, shadowOffset: 4)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
    }
}

// MARK: - Featured quest scroll

private struct QuestScroll: View {
    let quest: Quest
    let action: () -> Void

    var body: some View {
        VStack(spacing: -8) {
            ScrollRoll().zIndex(1)
            content
                .padding(.horizontal, 22)
                .padding(.top, 30)
                .padding(.bottom, 32)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Rectangle().fill(Theme.parchment))
                .overlay(Rectangle().strokeBorder(Theme.outline, lineWidth: 3))
                .padding(.horizontal, 20)
            ScrollRoll().zIndex(1)
        }
        .compositingGroup()
        .shadow(color: Theme.darkestWood.opacity(0.45), radius: 0, x: 0, y: 6)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(quest.kicker.uppercased())
                        .font(.alegreyaSans(12, weight: .bold))
                        .tracking(0.4)
                        .foregroundStyle(Theme.kicker)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(quest.title)
                        .font(.alegreya(30, weight: .heavy))
                        .foregroundStyle(Theme.ink)
                }
                Spacer(minLength: 8)
                WaxSeal(kind: quest.kind)
            }

            HStack(spacing: 10) {
                ParchmentProgressBar(progress: quest.progress, height: 14)
                Text("\(quest.completedCount) of \(quest.objectives.count)")
                    .font(.alegreyaSans(15, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .monospacedDigit()
            }
            .padding(.top, 10)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(quest.completedCount) of \(quest.objectives.count) objectives complete")

            VStack(spacing: 0) {
                ForEach(quest.objectives) { objective in
                    ObjectiveRow(objective: objective)
                    DashedDivider()
                }
            }
            .padding(.top, 14)

            Text("Rewards")
                .font(.alegreya(17))
                .foregroundStyle(Theme.ink)
                .padding(.top, 14)

            FlowLayout(spacing: 10) {
                ForEach(quest.rewards, id: \.self) { reward in
                    RewardChip(label: reward)
                }
            }
            .padding(.top, 10)

            Button(action: action) {
                Text(quest.kind.actionLabel)
                    .font(.alegreya(21, weight: .heavy))
                    .foregroundStyle(Theme.cream)
                    .frame(maxWidth: .infinity, minHeight: 54)
                    .cartoonBackground(RoundedRectangle(cornerRadius: 14), fill: Theme.waxRed,
                                       outline: Theme.waxBorder, lineWidth: 3, shadowOffset: 5)
            }
            .buttonStyle(PressableButtonStyle())
            .padding(.top, 22)
        }
    }
}

private struct ScrollRoll: View {
    var body: some View {
        ZStack {
            Capsule()
                .fill(Theme.scrollRoll)
                .overlay(Capsule().strokeBorder(Theme.outline, lineWidth: 3))
                .padding(.horizontal, 12)
            HStack {
                knob
                Spacer()
                knob
            }
        }
        .frame(height: 24)
        .accessibilityHidden(true)
    }

    private var knob: some View {
        RoundedRectangle(cornerRadius: 9)
            .fill(Theme.scrollKnob)
            .overlay(RoundedRectangle(cornerRadius: 9).strokeBorder(Theme.outline, lineWidth: 3))
            .frame(width: 22, height: 30)
    }
}

private struct WaxSeal: View {
    let kind: QuestKind

    var body: some View {
        ZStack {
            Circle()
                .fill(Theme.waxRed)
                .overlay(Circle().strokeBorder(Theme.waxBorder, lineWidth: 3))
            Group {
                switch kind {
                case .daily:
                    SwordShape()
                        .stroke(Theme.cream, style: StrokeStyle(lineWidth: 2, lineJoin: .round))
                        .frame(width: 18, height: 30)
                        .rotationEffect(.degrees(-45))
                case .weekly:
                    Image(systemName: "calendar")
                        .font(.system(size: 20, weight: .semibold))
                case .story:
                    Image(systemName: "book.closed")
                        .font(.system(size: 20, weight: .semibold))
                }
            }
            .foregroundStyle(Theme.cream)
        }
        .frame(width: 50, height: 50)
        .compositingGroup()
        .shadow(color: Theme.waxBorder.opacity(0.5), radius: 0, x: 0, y: 3)
        .accessibilityHidden(true)
    }
}

/// Simple outlined sword pointing up; rotate it to taste.
struct SwordShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height, cx = rect.midX
        var path = Path()
        // Blade
        path.move(to: CGPoint(x: cx, y: rect.minY))
        path.addLine(to: CGPoint(x: cx + w * 0.16, y: rect.minY + h * 0.14))
        path.addLine(to: CGPoint(x: cx + w * 0.16, y: rect.minY + h * 0.62))
        path.addLine(to: CGPoint(x: cx - w * 0.16, y: rect.minY + h * 0.62))
        path.addLine(to: CGPoint(x: cx - w * 0.16, y: rect.minY + h * 0.14))
        path.closeSubpath()
        // Crossguard
        path.addRoundedRect(in: CGRect(x: rect.minX, y: rect.minY + h * 0.62, width: w, height: h * 0.09),
                            cornerSize: CGSize(width: 2, height: 2))
        // Grip
        path.addRect(CGRect(x: cx - w * 0.09, y: rect.minY + h * 0.71, width: w * 0.18, height: h * 0.18))
        // Pommel
        path.addEllipse(in: CGRect(x: cx - w * 0.14, y: rect.minY + h * 0.89, width: w * 0.28, height: w * 0.28))
        return path
    }
}

/// Read-only: objectives complete from logged data, never by tapping.
private struct ObjectiveRow: View {
    let objective: QuestObjective

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 7)
                    .fill(objective.isComplete ? Theme.progressGreen : Theme.checkboxFill)
                RoundedRectangle(cornerRadius: 7)
                    .strokeBorder(Theme.outline, lineWidth: 3)
                if objective.isComplete {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundStyle(Theme.cream)
                }
            }
            .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(objective.name)
                    .font(.alegreyaSans(19, weight: .bold))
                    .foregroundStyle(objective.isComplete ? Theme.inkSecondary.opacity(0.7) : Theme.ink)
                    .strikethrough(objective.isComplete, color: Theme.inkSecondary)
                Text(objective.detail)
                    .font(.alegreyaSans(15))
                    .foregroundStyle(Theme.inkSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
        .accessibilityValue(objective.isComplete ? "Complete" : "Not complete")
    }
}

private struct DashedDivider: View {
    var body: some View {
        Line()
            .stroke(Theme.inkSecondary.opacity(0.45), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
            .frame(height: 1.5)
            .accessibilityHidden(true)
    }

    private struct Line: Shape {
        func path(in rect: CGRect) -> Path {
            Path { p in
                p.move(to: CGPoint(x: rect.minX, y: rect.midY))
                p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            }
        }
    }
}

private struct RewardChip: View {
    let label: String

    var body: some View {
        Text(label)
            .font(.alegreyaSans(16, weight: .bold))
            .foregroundStyle(Theme.ink)
            .padding(.horizontal, 14)
            .frame(minHeight: 36)
            .background(Capsule().fill(Theme.scrollRoll.opacity(0.35)))
            .overlay(Capsule().strokeBorder(Theme.outline, lineWidth: 2.5))
    }
}

// MARK: - Shared pieces

struct ParchmentProgressBar: View {
    let progress: Double
    var height: CGFloat = 14

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.progressTrack)
                Capsule()
                    .fill(Theme.progressGreen)
                    .frame(width: proxy.size.width * min(max(progress, 0), 1))
                Capsule().strokeBorder(Theme.outline, lineWidth: 2.5)
            }
        }
        .frame(height: height)
        .clipShape(Capsule())
    }
}

struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .offset(y: configuration.isPressed ? 3 : 0)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }
}

/// Wraps children onto new lines when they run out of horizontal room.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(maxWidth: proposal.width ?? .infinity, subviews: subviews)
        let width = rows.map(\.width).max() ?? 0
        let height = rows.map(\.height).reduce(0, +) + spacing * CGFloat(max(rows.count - 1, 0))
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in arrange(maxWidth: bounds.width, subviews: subviews) {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func arrange(maxWidth: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = [Row()]
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let extra = rows[rows.count - 1].indices.isEmpty ? size.width : spacing + size.width
            if rows[rows.count - 1].width + extra > maxWidth, !rows[rows.count - 1].indices.isEmpty {
                rows.append(Row())
            }
            let isFirst = rows[rows.count - 1].indices.isEmpty
            rows[rows.count - 1].indices.append(index)
            rows[rows.count - 1].width += isFirst ? size.width : spacing + size.width
            rows[rows.count - 1].height = max(rows[rows.count - 1].height, size.height)
        }
        return rows
    }
}

#Preview {
    NavigationStack {
        QuestBoardView()
    }
}
