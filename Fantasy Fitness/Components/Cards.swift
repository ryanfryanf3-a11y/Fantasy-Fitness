//
//  Cards.swift
//  Fantasy Fitness
//
//  Parchment containers that sit on the wood board. Content is free-form; these
//  only provide the material, padding and shadow.
//

import SwiftUI

/// Flat parchment panel with an outline and hard shadow.
struct ParchmentCard<Content: View>: View {
    var fill: Color = Theme.parchment
    var padding: CGFloat = 20
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .padding(padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cartoonBackground(RoundedRectangle(cornerRadius: 8), fill: fill, shadowOffset: 6)
    }
}

/// A note pinned to the board: slight tilt and a brass pin at the top.
struct PinnedNote<Content: View>: View {
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
            BrassPin(size: 24)
                .offset(y: -12)
        }
        .rotationEffect(.degrees(rotation))
    }
}

/// Parchment between two wooden rolls; used for featured content (quests, maps).
struct ParchmentScroll<Content: View>: View {
    var contentPadding = EdgeInsets(top: 30, leading: 22, bottom: 32, trailing: 22)
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: -8) {
            ScrollRoll().zIndex(1)
            VStack(alignment: .leading, spacing: 0) {
                content
            }
            .padding(contentPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Rectangle().fill(Theme.parchment))
            .overlay(Rectangle().strokeBorder(Theme.outline, lineWidth: 3))
            .padding(.horizontal, 20)
            ScrollRoll().zIndex(1)
        }
        .compositingGroup()
        .shadow(color: Theme.darkestWood.opacity(0.45), radius: 0, x: 0, y: 6)
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

struct BrassPin: View {
    var size: CGFloat = 24

    var body: some View {
        Circle()
            .fill(Theme.brass)
            .overlay(Circle().strokeBorder(Theme.outline, lineWidth: size > 16 ? 2.5 : 1.5))
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

/// Title + subtitle at the top of a note or card on parchment.
struct NoteHeading: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.alegreya(20, weight: .heavy))
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            if let subtitle {
                Text(subtitle)
                    .font(.alegreyaSans(16))
                    .foregroundStyle(Theme.inkSecondary)
            }
        }
    }
}
