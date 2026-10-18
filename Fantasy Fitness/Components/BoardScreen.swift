//
//  BoardScreen.swift
//  Fantasy Fitness
//

import SwiftUI

/// Scrolling wood-board page used by every tab. Root screens hide the navigation
/// bar; pushed screens keep it (transparent) for the system back button and swipe-back.
struct BoardScreen<Content: View>: View {
    var isRoot = true
    var spacing: CGFloat = 20
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView {
            VStack(spacing: spacing) {
                content
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .background(WoodBackground())
        .toolbar(isRoot ? .hidden : .visible, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Wooden sign with the screen title in blackletter.
struct BoardSign: View {
    let title: String
    var fontSize: CGFloat = 44

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            brassDot
            Text(title)
                .font(.pirata(fontSize))
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
            .padding(.top, fontSize * 0.23)
            .accessibilityHidden(true)
    }
}

/// Section title painted straight on the wood, with an optional trailing accessory.
struct BoardSectionHeader<Trailing: View>: View {
    let title: String
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.alegreya(22, weight: .heavy))
                .foregroundStyle(Theme.cream)
                .shadow(color: Theme.darkestWood, radius: 0, x: 0, y: 2)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 8)
            trailing
        }
        .padding(.top, 6)
    }
}

extension BoardSectionHeader where Trailing == EmptyView {
    init(title: String) {
        self.init(title: title) { EmptyView() }
    }
}

/// Gold "Title ›" label for links and actions beside a section header on wood.
struct HeaderLinkLabel: View {
    let title: String
    var systemImage = "chevron.right"

    var body: some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.alegreyaSans(16, weight: .bold))
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .heavy))
        }
        .foregroundStyle(Theme.gold)
        .frame(minHeight: 44)
        .contentShape(Rectangle())
    }
}
