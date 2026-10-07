//
//  TitleScreenView.swift
//  Fantasy Fitness
//

import SwiftUI

struct TitleScreenView: View {
    let hasSave: Bool
    let onContinue: () -> Void
    let onNewGame: () -> Void

    @State private var showingSettings = false
    @State private var confirmingNewGame = false

    // Hard-coded until the profile is loaded from SwiftData / Supabase.
    private let saveSummary = "Level 14 Warrior · E-rank"

    var body: some View {
        GeometryReader { proxy in
            let horizonY = proxy.size.height * 0.47
            ZStack(alignment: .top) {
                TwilightSky(horizonY: horizonY + proxy.safeAreaInsets.top)

                VStack(spacing: 0) {
                    TitleSign()
                        .padding(.top, 20)
                        .frame(maxWidth: .infinity, maxHeight: horizonY, alignment: .top)

                    board
                }
            }
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

    private var board: some View {
        VStack(spacing: 0) {
            BoardBeam()
            ClassPennantRow()
                .padding(.top, -6)

            Spacer(minLength: 16)

            VStack(spacing: 14) {
                TitleMenuButton(title: "Continue",
                                subtitle: hasSave ? saveSummary : "No adventure yet",
                                systemImage: "play.fill",
                                fill: Theme.waxRed, border: Theme.waxBorder,
                                action: onContinue)
                    .disabled(!hasSave)

                TitleMenuButton(title: "New game",
                                systemImage: "sparkles",
                                fill: Theme.emerald, border: Theme.emeraldBorder) {
                    if hasSave { confirmingNewGame = true } else { onNewGame() }
                }

                TitleMenuButton(title: "Settings",
                                systemImage: "gearshape.fill",
                                fill: Theme.darkWood, border: Theme.darkestWood,
                                compact: true) {
                    showingSettings = true
                }
            }
            .padding(.horizontal, 24)

            Spacer(minLength: 12)

            Text("v0.1 · Train · Grow · Fight · Loot")
                .font(.alegreyaSans(13, weight: .medium))
                .foregroundStyle(Theme.cream.opacity(0.6))
                .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(WoodBackground())
    }
}

// MARK: - Sign

/// The hanging "Fantasy Fitness" sign with chains and a crimson ribbon.
private struct TitleSign: View {
    var body: some View {
        VStack(spacing: -12) {
            VStack(spacing: -10) {
                Text("Fantasy")
                Text("Fitness")
            }
            .font(.pirata(54))
            .foregroundStyle(Theme.gold)
            .shadow(color: Theme.darkestWood, radius: 0, x: 0, y: 3)
            .padding(.horizontal, 34)
            .padding(.top, 14)
            .padding(.bottom, 22)
            .cartoonBackground(RoundedRectangle(cornerRadius: 14), fill: Theme.darkWood,
                               outline: Theme.darkestWood, lineWidth: 4, shadowOffset: 6)
            .overlay(alignment: .topLeading) { cornerRivet.offset(x: 12, y: 12) }
            .overlay(alignment: .topTrailing) { cornerRivet.offset(x: -12, y: 12) }
            .overlay(alignment: .bottomLeading) { cornerRivet.offset(x: 12, y: -12) }
            .overlay(alignment: .bottomTrailing) { cornerRivet.offset(x: -12, y: -12) }
            .background(alignment: .bottom) { chains }

            Text("A Guild of Real Strength")
                .font(.alegreya(16, weight: .heavy))
                .foregroundStyle(Theme.cream)
                .padding(.horizontal, 34)
                .frame(height: 38)
                .background(CartoonShape(shape: RibbonShape(), fill: Theme.waxRed,
                                         outline: Theme.waxBorder, shadowOffset: 4))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Fantasy Fitness. A Guild of Real Strength")
        .accessibilityAddTraits(.isHeader)
    }

    private var cornerRivet: some View {
        Circle()
            .fill(Theme.brass)
            .overlay(Circle().strokeBorder(Theme.darkestWood, lineWidth: 1.5))
            .frame(width: 9, height: 9)
    }

    /// Two brass chains running off the top of the screen.
    private var chains: some View {
        HStack {
            chain
            Spacer()
            chain
        }
        .padding(.horizontal, 44)
        .frame(height: 400)
        .offset(y: -40)
    }

    private var chain: some View {
        Rectangle()
            .fill(Theme.brass)
            .frame(width: 5)
            .overlay(
                Rectangle()
                    .strokeBorder(Theme.darkestWood, style: StrokeStyle(lineWidth: 1.5, dash: [6, 3]))
            )
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

// MARK: - Board top

/// Thick dark beam along the horizon that the pennants and torches hang from.
private struct BoardBeam: View {
    var body: some View {
        Rectangle()
            .fill(Theme.darkerWood)
            .frame(height: 18)
            .overlay(alignment: .top) {
                Rectangle().fill(Theme.darkestWood).frame(height: 3)
            }
            .overlay(alignment: .bottom) {
                Rectangle().fill(Theme.darkestWood).frame(height: 3)
            }
            .overlay(alignment: .bottom) {
                HStack {
                    Torch()
                    Spacer()
                    Torch()
                }
                .padding(.horizontal, 16)
                .offset(y: -12)
            }
            .zIndex(1)
    }
}

private struct Torch: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var flicker = false

    var body: some View {
        VStack(spacing: -2) {
            ZStack(alignment: .bottom) {
                FlameShape().fill(Theme.flameOuter)
                    .frame(width: 22, height: 32)
                FlameShape().fill(Theme.flameInner)
                    .frame(width: 12, height: 18)
                    .padding(.bottom, 2)
            }
            .scaleEffect(x: flicker ? 0.92 : 1.04, y: flicker ? 1.08 : 0.94, anchor: .bottom)
            .shadow(color: Theme.flameOuter.opacity(0.7), radius: 10)

            CartoonSurface(shape: RoundedRectangle(cornerRadius: 3), fill: Theme.brass,
                           outline: Theme.darkestWood, lineWidth: 2, shadowOffset: 0)
                .frame(width: 26, height: 10)
            CartoonSurface(shape: Rectangle(), fill: Theme.darkWood,
                           outline: Theme.darkestWood, lineWidth: 2, shadowOffset: 0)
                .frame(width: 10, height: 26)
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 0.35).repeatForever(autoreverses: true)) {
                flicker = true
            }
        }
        .accessibilityHidden(true)
    }
}

private struct FlameShape: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.midX, y: rect.minY))
            p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.maxY * 0.7),
                           control: CGPoint(x: rect.maxX * 0.95, y: rect.height * 0.35))
            p.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY * 0.7),
                           control: CGPoint(x: rect.midX, y: rect.maxY * 1.25))
            p.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.minY),
                           control: CGPoint(x: rect.width * 0.05, y: rect.height * 0.35))
        }
    }
}

// MARK: - Class pennants

private struct ClassPennantRow: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ClassPennant(name: "Warrior", fill: Theme.waxRed, border: Theme.waxBorder, delay: 0) {
                SwordShape()
                    .stroke(Theme.cream, style: StrokeStyle(lineWidth: 2, lineJoin: .round))
                    .frame(width: 14, height: 26)
                    .rotationEffect(.degrees(-45))
            }
            ClassPennant(name: "Ranger", fill: Theme.emerald, border: Theme.emeraldBorder, delay: 0.4) {
                Image(systemName: "leaf.fill")
            }
            ClassPennant(name: "Monk", fill: Theme.sapphire, border: Theme.sapphireBorder, delay: 0.8) {
                Image(systemName: "figure.mind.and.body")
            }
            ClassPennant(name: "Paladin", fill: Theme.amethyst, border: Theme.amethystBorder, delay: 1.2) {
                Image(systemName: "shield.fill")
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Classes: Warrior, Ranger, Monk, Paladin")
    }
}

private struct ClassPennant<Emblem: View>: View {
    let name: String
    let fill: Color
    let border: Color
    let delay: Double
    @ViewBuilder let emblem: Emblem

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var sway = false

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(border.opacity(0.45))
                    .frame(width: 34, height: 34)
                emblem
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Theme.cream)
            }
            Text(name)
                .font(.alegreyaSans(12, weight: .bold))
                .foregroundStyle(Theme.cream)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.top, 12)
        .padding(.bottom, 24)
        .frame(width: 62)
        .background(CartoonShape(shape: PennantShape(), fill: fill, outline: border, shadowOffset: 4))
        .overlay(alignment: .top) {
            Circle()
                .fill(Theme.brass)
                .overlay(Circle().strokeBorder(Theme.darkestWood, lineWidth: 1.5))
                .frame(width: 10, height: 10)
                .offset(y: 4)
        }
        .rotationEffect(.degrees(sway ? 2.5 : -2.5), anchor: .top)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true).delay(delay)) {
                sway = true
            }
        }
    }
}

/// Hanging banner with a V-notch at the bottom.
private struct PennantShape: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.minX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY - 16))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            p.closeSubpath()
        }
    }
}

// MARK: - Menu buttons

private struct TitleMenuButton: View {
    let title: String
    var subtitle: String? = nil
    let systemImage: String
    let fill: Color
    let border: Color
    var compact = false
    let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.system(size: compact ? 15 : 18, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .frame(width: compact ? 32 : 38, height: compact ? 32 : 38)
                    .background(Circle().fill(Theme.gold))
                    .overlay(Circle().strokeBorder(border, lineWidth: 2.5))

                VStack(alignment: .leading, spacing: 0) {
                    Text(title)
                        .font(.alegreya(compact ? 18 : 22, weight: .heavy))
                    if let subtitle {
                        Text(subtitle)
                            .font(.alegreyaSans(14, weight: .medium))
                            .opacity(0.85)
                    }
                }
                .foregroundStyle(Theme.cream)

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundStyle(Theme.cream.opacity(0.7))
            }
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, minHeight: compact ? 50 : 62)
            .cartoonBackground(RoundedRectangle(cornerRadius: 14), fill: fill,
                               outline: border, lineWidth: 3, shadowOffset: 5)
            .opacity(isEnabled ? 1 : 0.55)
        }
        .buttonStyle(PressableButtonStyle())
    }
}

#Preview("With save") {
    TitleScreenView(hasSave: true, onContinue: {}, onNewGame: {})
}

#Preview("New player") {
    TitleScreenView(hasSave: false, onContinue: {}, onNewGame: {})
}
