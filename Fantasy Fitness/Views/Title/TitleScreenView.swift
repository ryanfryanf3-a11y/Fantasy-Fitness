//
//  TitleScreenView.swift
//  Fantasy Fitness
//

import SwiftUI

struct TitleScreenView: View {
    let hasSave: Bool
    let onContinue: () -> Void
    let onNewGame: () -> Void
    /// Pins the look for previews; otherwise it follows the device clock.
    var forcedTimeOfDay: TimeOfDay? = nil

    @State private var showingSettings = false
    @State private var confirmingNewGame = false

    // Hard-coded until the profile is loaded from SwiftData / Supabase.
    private let saveSummary = "Level 14 Warrior · E-rank"

    var body: some View {
        // Re-evaluated every minute (and on return from background) so the scene
        // changes over at 6:00 am and 6:00 pm while the screen is open.
        TimelineView(.everyMinute) { timeline in
            let timeOfDay = forcedTimeOfDay ?? TimeOfDay.debugOverride ?? TimeOfDay.at(timeline.date)
            screen(timeOfDay)
                .animation(.easeInOut(duration: 1.2), value: timeOfDay)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsSheet()
        }
        .confirmationDialog("Start a new adventure?", isPresented: $confirmingNewGame, titleVisibility: .visible) {
            Button("New game", role: .destructive, action: onNewGame)
        } message: {
            Text("You'll pick a new class, goals and program. Your logged workouts stay on your account.")
        }
    }

    private func screen(_ timeOfDay: TimeOfDay) -> some View {
        GeometryReader { proxy in
            let groundY = proxy.size.height * 0.585
            ZStack(alignment: .top) {
                CastleGateScene(timeOfDay: timeOfDay, groundY: groundY + proxy.safeAreaInsets.top)
                    .id(timeOfDay)
                    .transition(.opacity)

                VStack(spacing: 0) {
                    TitleLogo(timeOfDay: timeOfDay, width: proxy.size.width)
                        .frame(maxWidth: .infinity, alignment: .top)
                        .frame(height: groundY, alignment: .top)

                    menu(timeOfDay)
                }
            }
        }
    }

    private func menu(_ timeOfDay: TimeOfDay) -> some View {
        VStack(spacing: 0) {
            // Drop the class crests on short screens rather than squeezing the buttons.
            ViewThatFits(in: .vertical) {
                controls(timeOfDay, showsCrests: true)
                controls(timeOfDay, showsCrests: false)
            }

            Spacer(minLength: 8)

            Text("Train · Grow · Fight · Loot")
                .font(.alegreyaSans(13, weight: .medium))
                .foregroundStyle(Theme.cream.opacity(0.9))
                .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func controls(_ timeOfDay: TimeOfDay, showsCrests: Bool) -> some View {
        VStack(spacing: 14) {
            if showsCrests {
                ClassCrestRow(onPlank: timeOfDay == .day)
            }

            if hasSave {
                TitlePrimaryButton(title: "Continue", subtitle: saveSummary,
                                   systemImage: "play.fill", action: onContinue)
            } else {
                TitlePrimaryButton(title: "New game", subtitle: "Enter the guild gate",
                                   systemImage: "plus", action: onNewGame)
            }

            HStack(spacing: 12) {
                if hasSave {
                    TitleSecondaryButton(title: "New game", systemImage: "plus", timeOfDay: timeOfDay) {
                        confirmingNewGame = true
                    }
                } else {
                    EmptySaveSlot(timeOfDay: timeOfDay)
                }
                TitleSecondaryButton(title: "Settings", systemImage: "gearshape.fill", timeOfDay: timeOfDay) {
                    showingSettings = true
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 28)
    }
}

// MARK: - Title

/// "Fantasy Fitness" set straight on the sky, with the guild tagline beneath.
private struct TitleLogo: View {
    let timeOfDay: TimeOfDay
    let width: CGFloat

    private var fontSize: CGFloat { min(78, width * 0.2) }

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                // Dark outline keeps the gold legible against the bright daytime sky.
                if timeOfDay == .day {
                    ForEach(0..<8, id: \.self) { step in
                        let angle = Double(step) * .pi / 4
                        wordmark
                            .foregroundStyle(Theme.darkestWood)
                            .offset(x: cos(angle) * 2.5, y: sin(angle) * 2.5)
                    }
                }
                wordmark
                    .foregroundStyle(Theme.gold)
                    .shadow(color: timeOfDay == .night ? Theme.gold.opacity(0.35) : .clear, radius: 14)
            }
            .background {
                wordmark
                    .foregroundStyle(Theme.darkestWood)
                    .offset(y: timeOfDay == .day ? 6 : 4)
            }

            tagline
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Fantasy Fitness. A Guild of Real Strength")
        .accessibilityAddTraits(.isHeader)
    }

    private var wordmark: some View {
        VStack(spacing: -fontSize * 0.36) {
            Text("Fantasy")
            Text("Fitness")
        }
        .font(.pirata(fontSize))
        // Pirata One carries a tall ascent; pull the wordmark up into it.
        .padding(.top, -fontSize * 0.14)
    }

    @ViewBuilder
    private var tagline: some View {
        switch timeOfDay {
        case .night:
            HStack(spacing: 12) {
                Rectangle().fill(Theme.brass).frame(width: 34, height: 2)
                Text("A GUILD OF REAL STRENGTH")
                    .font(.alegreyaSans(13, weight: .bold))
                    .tracking(2.3)
                    .foregroundStyle(Theme.cream)
                Rectangle().fill(Theme.brass).frame(width: 34, height: 2)
            }
        case .day:
            Text("A Guild of Real Strength")
                .font(.alegreya(16, weight: .heavy))
                .foregroundStyle(Theme.cream)
                .padding(.horizontal, 34)
                .frame(height: 38)
                .background(CartoonShape(shape: RibbonShape(), fill: Theme.waxRed,
                                         outline: Theme.waxBorder, shadowOffset: 4))
        }
    }
}

/// Banner with notched tails on both ends.
private struct RibbonShape: Shape {
    func path(in rect: CGRect) -> Path {
        let notch: CGFloat = 14
        return Path { p in
            p.move(to: CGPoint(x: rect.minX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX - notch, y: rect.midY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX + notch, y: rect.midY))
            p.closeSubpath()
        }
    }
}

// MARK: - Class crests

private struct ClassCrestRow: View {
    /// By day the crests sit on a wooden plank so the labels stay legible over the grass.
    let onPlank: Bool

    var body: some View {
        HStack(spacing: 0) {
            ClassCrest(name: "Warrior", fill: Theme.waxRed, border: Theme.waxBorder) {
                SwordShape()
                    .stroke(Theme.cream, style: StrokeStyle(lineWidth: 2, lineJoin: .round))
                    .frame(width: 15, height: 28)
                    .rotationEffect(.degrees(-45))
            }
            ClassCrest(name: "Ranger", fill: Theme.emerald, border: Theme.emeraldBorder) {
                Image(systemName: "leaf.fill")
            }
            ClassCrest(name: "Monk", fill: Theme.sapphire, border: Theme.sapphireBorder) {
                Image(systemName: "figure.mind.and.body")
            }
            ClassCrest(name: "Paladin", fill: Theme.amethyst, border: Theme.amethystBorder) {
                Image(systemName: "shield.fill")
            }
        }
        .padding(.horizontal, onPlank ? 8 : 0)
        .padding(.top, onPlank ? 10 : 0)
        .padding(.bottom, onPlank ? 8 : 0)
        .background {
            if onPlank {
                CartoonSurface(shape: RoundedRectangle(cornerRadius: 14), fill: Theme.darkWood,
                               outline: Theme.darkestWood, lineWidth: 3, shadowOffset: 5)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Classes: Warrior, Ranger, Monk, Paladin")
    }
}

private struct ClassCrest<Emblem: View>: View {
    let name: String
    let fill: Color
    let border: Color
    @ViewBuilder let emblem: Emblem

    var body: some View {
        VStack(spacing: 4) {
            emblem
                .font(.system(size: 21, weight: .bold))
                .foregroundStyle(Theme.cream)
                .frame(width: 52, height: 52)
                .background(CartoonSurface(shape: Circle(), fill: fill, outline: border,
                                           lineWidth: 3, shadowOffset: 3))
            Text(name)
                .font(.alegreyaSans(13, weight: .bold))
                .foregroundStyle(Theme.cream)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Menu buttons

/// The one gold button: "New game" for a new player, "Continue" once there is a save.
private struct TitlePrimaryButton: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(Theme.cream)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Theme.waxRed))
                    .overlay(Circle().strokeBorder(Theme.waxBorder, lineWidth: 2.5))

                VStack(alignment: .leading, spacing: 0) {
                    Text(title)
                        .font(.alegreya(24, weight: .heavy))
                    Text(subtitle)
                        .font(.alegreyaSans(14, weight: .medium))
                }
                .foregroundStyle(Theme.ink)

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundStyle(Theme.ink)
            }
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, minHeight: 68)
            .cartoonBackground(RoundedRectangle(cornerRadius: 14), fill: Theme.gold,
                               outline: Theme.outline, lineWidth: 3, shadowOffset: 5)
        }
        .buttonStyle(PressableButtonStyle())
    }
}

private struct TitleSecondaryButton: View {
    let title: String
    let systemImage: String
    let timeOfDay: TimeOfDay
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Theme.gold)
                Text(title)
                    .font(.alegreya(18, weight: .heavy))
                    .foregroundStyle(Theme.cream)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, minHeight: 58)
            .cartoonBackground(RoundedRectangle(cornerRadius: 14),
                               fill: timeOfDay == .day ? Theme.darkWood : Theme.mountainFar,
                               outline: timeOfDay == .day ? Theme.darkestWood : Theme.mountainNear,
                               lineWidth: 3, shadowOffset: 5)
        }
        .buttonStyle(PressableButtonStyle())
    }
}

/// Where "Continue" will appear; shown as an empty slot until there is a save.
private struct EmptySaveSlot: View {
    let timeOfDay: TimeOfDay

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Continue")
                .font(.alegreya(18, weight: .heavy))
            Text("No adventure yet")
                .font(.alegreyaSans(13, weight: .medium))
        }
        .foregroundStyle(Theme.cream)
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14)
            .fill(timeOfDay == .day ? Theme.grassDeep.opacity(0.6) : Theme.cream.opacity(0.08)))
        .overlay(RoundedRectangle(cornerRadius: 14)
            .strokeBorder(Theme.cream.opacity(0.55), style: StrokeStyle(lineWidth: 2, dash: [6, 4])))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Continue. No adventure yet")
    }
}

#Preview("Night, new player") {
    TitleScreenView(hasSave: false, onContinue: {}, onNewGame: {}, forcedTimeOfDay: .night)
}

#Preview("Night, with save") {
    TitleScreenView(hasSave: true, onContinue: {}, onNewGame: {}, forcedTimeOfDay: .night)
}

#Preview("Day, new player") {
    TitleScreenView(hasSave: false, onContinue: {}, onNewGame: {}, forcedTimeOfDay: .day)
}

#Preview("Day, with save") {
    TitleScreenView(hasSave: true, onContinue: {}, onNewGame: {}, forcedTimeOfDay: .day)
}
