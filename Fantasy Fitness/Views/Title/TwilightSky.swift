//
//  TwilightSky.swift
//  Fantasy Fitness
//

import SwiftUI

/// Dusk sky behind the title sign: twinkling stars, moon, mountains and a castle
/// sitting on the horizon. Everything below `horizonY` is expected to be covered.
struct TwilightSky: View {
    let horizonY: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 15, paused: reduceMotion)) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                drawSky(in: &context, size: size)
                drawStars(in: &context, size: size, time: reduceMotion ? 0 : time)
                drawMoon(in: &context, size: size)
                drawMountains(in: &context, size: size)
                drawCastle(in: &context, size: size)
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    // MARK: Layers

    private func drawSky(in context: inout GraphicsContext, size: CGSize) {
        let rect = CGRect(origin: .zero, size: size)
        let horizon = horizonY / max(size.height, 1)
        context.fill(Path(rect), with: .linearGradient(
            Gradient(stops: [
                .init(color: Theme.skyTop, location: 0),
                .init(color: Theme.skyMid, location: horizon * 0.55),
                .init(color: Theme.skyGlow, location: horizon * 0.88),
                .init(color: Theme.horizonGlow, location: horizon),
            ]),
            startPoint: .zero,
            endPoint: CGPoint(x: 0, y: size.height)
        ))
    }

    private func drawStars(in context: inout GraphicsContext, size: CGSize, time: TimeInterval) {
        var rng = SeededGenerator(seed: 7)
        let starLimit = horizonY * 0.6
        for index in 0..<46 {
            let x = CGFloat.random(in: 0...size.width, using: &rng)
            let y = CGFloat.random(in: 0...starLimit, using: &rng)
            let radius = CGFloat.random(in: 0.8...2.0, using: &rng)
            let phase = Double.random(in: 0...(2 * .pi), using: &rng)
            let twinkle = 0.55 + 0.45 * sin(time * 1.6 + phase)
            // Fade stars out as the sky warms toward the horizon.
            let fade = 1 - (y / starLimit) * 0.6
            let color = index % 5 == 0 ? Theme.flameInner : Theme.moon
            context.fill(Path(ellipseIn: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)),
                         with: .color(color.opacity(twinkle * fade)))
        }
    }

    private func drawMoon(in context: inout GraphicsContext, size: CGSize) {
        let center = CGPoint(x: size.width * 0.9, y: horizonY * 0.24)
        let radius: CGFloat = 26
        for (scale, opacity) in [(2.4, 0.08), (1.7, 0.14)] {
            let r = radius * scale
            context.fill(Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)),
                         with: .color(Theme.moon.opacity(opacity)))
        }
        context.fill(Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)),
                     with: .color(Theme.moon))
        for crater in [CGRect(x: -10, y: -8, width: 9, height: 9), CGRect(x: 6, y: 4, width: 7, height: 7), CGRect(x: -4, y: 10, width: 5, height: 5)] {
            context.fill(Path(ellipseIn: crater.offsetBy(dx: center.x, dy: center.y)),
                         with: .color(Theme.scrollRoll.opacity(0.45)))
        }
    }

    private func drawMountains(in context: inout GraphicsContext, size: CGSize) {
        let far: [(CGFloat, CGFloat)] = [(0, 0.78), (0.12, 0.66), (0.24, 0.74), (0.38, 0.6), (0.52, 0.72),
                                          (0.66, 0.63), (0.8, 0.73), (0.92, 0.64), (1, 0.7)]
        let near: [(CGFloat, CGFloat)] = [(0, 0.86), (0.1, 0.8), (0.22, 0.88), (0.36, 0.79), (0.5, 0.87),
                                           (0.62, 0.82), (0.78, 0.84), (0.9, 0.8), (1, 0.85)]
        context.fill(ridge(far, size: size), with: .color(Theme.mountainFar))
        context.fill(ridge(near, size: size), with: .color(Theme.mountainNear))
    }

    private func ridge(_ points: [(CGFloat, CGFloat)], size: CGSize) -> Path {
        Path { path in
            path.move(to: CGPoint(x: 0, y: horizonY + 20))
            for (x, y) in points {
                path.addLine(to: CGPoint(x: x * size.width, y: y * horizonY))
            }
            path.addLine(to: CGPoint(x: size.width, y: horizonY + 20))
            path.closeSubpath()
        }
    }

    private func drawCastle(in context: inout GraphicsContext, size: CGSize) {
        let width: CGFloat = 120
        let height: CGFloat = 78
        let origin = CGPoint(x: size.width * 0.66 - width / 2, y: horizonY * 0.83 - height)
        func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect {
            CGRect(x: origin.x + x * width, y: origin.y + y * height, width: w * width, height: h * height)
        }
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: origin.x + x * width, y: origin.y + y * height)
        }

        var body = Path()
        body.addRect(rect(0.22, 0.55, 0.56, 0.6))           // curtain wall
        for i in stride(from: 0.22, to: 0.76, by: 0.08) {   // wall merlons
            body.addRect(rect(i, 0.48, 0.045, 0.08))
        }
        body.addRect(rect(0.38, 0.24, 0.24, 0.9))           // keep
        for i in stride(from: 0.38, to: 0.6, by: 0.065) {   // keep merlons
            body.addRect(rect(i, 0.17, 0.04, 0.08))
        }
        for x in [0.08, 0.78] {                              // side towers + roofs
            body.addRect(rect(x, 0.36, 0.14, 0.8))
            body.move(to: point(x - 0.02, 0.37))
            body.addLine(to: point(x + 0.07, 0.08))
            body.addLine(to: point(x + 0.16, 0.37))
            body.closeSubpath()
        }
        context.fill(body, with: .color(Theme.castle))

        // Flags on the tower tips and the keep.
        for (x, y, color) in [(0.15, 0.08, Theme.waxRed), (0.85, 0.08, Theme.sapphire), (0.5, 0.17, Theme.gold)] {
            var pole = Path()
            pole.move(to: point(x, y))
            pole.addLine(to: point(x, y - 0.2))
            context.stroke(pole, with: .color(Theme.castle), lineWidth: 1.5)
            var flag = Path()
            flag.move(to: point(x, y - 0.2))
            flag.addLine(to: point(x + 0.12, y - 0.15))
            flag.addLine(to: point(x, y - 0.1))
            flag.closeSubpath()
            context.fill(flag, with: .color(color))
        }

        // Lit windows.
        for window in [rect(0.47, 0.36, 0.06, 0.1), rect(0.13, 0.5, 0.04, 0.08), rect(0.83, 0.5, 0.04, 0.08),
                       rect(0.3, 0.7, 0.04, 0.07), rect(0.66, 0.7, 0.04, 0.07)] {
            context.fill(Path(roundedRect: window, cornerRadius: 1.5), with: .color(Theme.flameInner))
        }
    }
}

/// Deterministic RNG so the star field is identical on every frame and launch.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) { state = seed &+ 0x9E3779B97F4A7C15 }

    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

#Preview {
    TwilightSky(horizonY: 420)
}
