//
//  CastleGateScene.swift
//  Fantasy Fitness
//

import SwiftUI

/// Full-screen backdrop for the title screen: sky, mountains, the guild castle and the
/// path leading to its gate. Drawn on a 390-pt-wide design grid whose ground line sits
/// at y = 480, then scaled to the screen width and anchored to `groundY`.
struct CastleGateScene: View {
    let timeOfDay: TimeOfDay
    /// Y of the ground line under the castle, in full-screen coordinates.
    let groundY: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 15, paused: reduceMotion)) { timeline in
            Canvas { context, size in
                let time = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate
                let frame = SceneFrame(size: size, groundY: groundY)
                switch timeOfDay {
                case .night: drawNight(in: &context, frame: frame, time: time)
                case .day: drawDay(in: &context, frame: frame, time: time)
                }
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    // MARK: Night

    private func drawNight(in context: inout GraphicsContext, frame: SceneFrame, time: TimeInterval) {
        drawSky(in: &context, frame: frame, stops: [
            .init(color: Theme.skyTop, location: 0),
            .init(color: Theme.skyMid, location: 0.5),
            .init(color: Theme.skyGlow, location: 0.88),
            .init(color: Theme.horizonGlow, location: 1),
        ])
        drawStars(in: &context, frame: frame, time: time)

        let moon = frame.point(292, 318)
        context.fill(circle(moon, 92 * frame.scale), with: .color(Theme.moon.opacity(0.1)))
        context.fill(circle(moon, 58 * frame.scale), with: .color(Theme.moon))
        for (x, y, r) in [(274.0, 300.0, 7.0), (310, 328, 5.5), (284, 342, 3.5)] {
            context.fill(circle(frame.point(x, y), r * frame.scale), with: .color(Theme.scrollRoll.opacity(0.5)))
        }

        context.fill(frame.polygon(SceneFrame.farRidge), with: .color(Theme.mountainFar))
        context.fill(frame.polygon(SceneFrame.nearRidge), with: .color(Theme.mountainNear))
        context.fill(frame.ground, with: .color(Theme.castle))
        context.fill(frame.path, with: .linearGradient(
            Gradient(stops: [
                .init(color: Theme.flameInner.opacity(0.5), location: 0),
                .init(color: Theme.mountainFar.opacity(0.6), location: 0.5),
                .init(color: Theme.mountainNear.opacity(0), location: 1),
            ]),
            startPoint: frame.point(195, 480), endPoint: CGPoint(x: frame.size.width / 2, y: frame.size.height)))

        // Castle silhouette.
        var silhouette = Path()
        for tower in frame.towers { silhouette.addRect(tower) }
        for roof in frame.roofs { silhouette.addPath(roof) }
        silhouette.addPath(frame.wall)
        silhouette.addPath(frame.keep)
        context.fill(silhouette, with: .color(Theme.castle))
        drawFlags(in: &context, frame: frame, pole: Theme.castle, outlined: false)

        for window in frame.windows {
            context.fill(Path(roundedRect: window, cornerRadius: 2 * frame.scale), with: .color(Theme.flameInner))
        }
        context.fill(frame.gate, with: .color(Theme.flameInner))
        context.stroke(frame.portcullis, with: .color(Theme.castle), lineWidth: 2 * frame.scale)

        for (index, x) in [150.0, 240.0].enumerated() {
            drawTorch(in: &context, frame: frame, centerX: x, time: time, phase: Double(index) * 1.7)
        }
    }

    private func drawStars(in context: inout GraphicsContext, frame: SceneFrame, time: TimeInterval) {
        var rng = SeededGenerator(seed: 7)
        let starLimit = frame.point(0, 300).y
        for index in 0..<46 {
            let x = CGFloat.random(in: 0...frame.size.width, using: &rng)
            let y = CGFloat.random(in: 0...starLimit, using: &rng)
            let radius = CGFloat.random(in: 0.8...2.0, using: &rng)
            let phase = Double.random(in: 0...(2 * .pi), using: &rng)
            let twinkle = 0.55 + 0.45 * sin(time * 1.6 + phase)
            // Fade stars out as the sky warms toward the horizon.
            let fade = 1 - (y / starLimit) * 0.6
            let color = index % 5 == 0 ? Theme.flameInner : Theme.moon
            context.fill(circle(CGPoint(x: x, y: y), radius), with: .color(color.opacity(twinkle * fade)))
        }
    }

    private func drawTorch(in context: inout GraphicsContext, frame: SceneFrame, centerX: CGFloat,
                           time: TimeInterval, phase: Double) {
        let s = frame.scale
        let glowCenter = frame.point(centerX, 446)
        context.fill(circle(glowCenter, 40 * s), with: .radialGradient(
            Gradient(colors: [Theme.flameInner.opacity(0.6), Theme.flameOuter.opacity(0)]),
            center: glowCenter, startRadius: 0, endRadius: 40 * s))

        let handle = frame.rect(centerX - 3, 454, 6, 22)
        context.fill(Path(handle), with: .color(Theme.darkWood))
        context.stroke(Path(handle), with: .color(Theme.darkestWood), lineWidth: 1.5 * s)

        // Flames grow from the top of the handle and flicker in height.
        let flicker = 1 + 0.08 * sin(time * 9 + phase)
        let base = frame.point(centerX, 459)
        func flame(width: CGFloat, height: CGFloat) -> Path {
            let w = width * s, h = height * s * flicker
            return Path { p in
                p.move(to: CGPoint(x: base.x, y: base.y - h))
                p.addQuadCurve(to: CGPoint(x: base.x + w / 2, y: base.y - h * 0.45),
                               control: CGPoint(x: base.x + w / 2, y: base.y - h * 0.7))
                p.addQuadCurve(to: CGPoint(x: base.x - w / 2, y: base.y - h * 0.45),
                               control: CGPoint(x: base.x, y: base.y + h * 0.1))
                p.addQuadCurve(to: CGPoint(x: base.x, y: base.y - h),
                               control: CGPoint(x: base.x - w / 2, y: base.y - h * 0.7))
            }
        }
        context.fill(flame(width: 16, height: 31), with: .color(Theme.flameOuter))
        context.fill(flame(width: 8, height: 18), with: .color(Theme.flameInner))
    }

    // MARK: Day

    private func drawDay(in context: inout GraphicsContext, frame: SceneFrame, time: TimeInterval) {
        let s = frame.scale
        drawSky(in: &context, frame: frame, stops: [
            .init(color: Theme.daySkyTop, location: 0),
            .init(color: Theme.daySkyMid, location: 0.6),
            .init(color: Theme.dayHorizon, location: 1),
        ])

        let sun = frame.point(300, 296)
        context.fill(circle(sun, 96 * s), with: .radialGradient(
            Gradient(colors: [Theme.cream.opacity(0.9), Theme.flameInner.opacity(0)]),
            center: sun, startRadius: 0, endRadius: 96 * s))
        context.fill(circle(sun, 44 * s), with: .color(Theme.moon))
        context.stroke(circle(sun, 44 * s), with: .color(Theme.gold), lineWidth: 4 * s)

        drawClouds(in: &context, frame: frame, time: time)

        var birds = Path()
        for (x, y, span) in [(22.0, 204.0, 7.0), (330, 190, 6), (52, 232, 5)] {
            birds.move(to: frame.point(x, y))
            birds.addQuadCurve(to: frame.point(x + span * 2, y), control: frame.point(x + span, y - span * 1.4))
            birds.addQuadCurve(to: frame.point(x + span * 4, y), control: frame.point(x + span * 3, y - span * 1.4))
        }
        context.stroke(birds, with: .color(Theme.ink), style: StrokeStyle(lineWidth: 2 * s, lineCap: .round))

        context.fill(frame.polygon(SceneFrame.farRidge), with: .color(Theme.dayMountain))
        for cap in SceneFrame.snowCaps {
            context.fill(frame.polygon(cap), with: .color(.white))
        }
        context.fill(frame.polygon(SceneFrame.nearRidge), with: .color(Theme.dayHill))
        context.fill(frame.ground, with: .linearGradient(
            Gradient(stops: [
                .init(color: Theme.grassTop, location: 0),
                .init(color: Theme.grass, location: 0.35),
                .init(color: Theme.grassDeep, location: 1),
            ]),
            startPoint: frame.point(195, 466), endPoint: CGPoint(x: frame.size.width / 2, y: frame.size.height)))
        context.fill(frame.path, with: .linearGradient(
            Gradient(stops: [
                .init(color: Theme.dirtPath, location: 0),
                .init(color: Theme.dirtPath.opacity(0.7), location: 0.3),
                .init(color: Theme.dirtPath.opacity(0), location: 0.6),
            ]),
            startPoint: frame.point(195, 480), endPoint: CGPoint(x: frame.size.width / 2, y: frame.size.height)))

        // Stone castle, back to front.
        let outline = StrokeStyle(lineWidth: 2.5 * s, lineJoin: .round)
        for tower in frame.towers {
            context.fill(Path(tower), with: .color(Theme.stone))
            context.stroke(Path(tower), with: .color(Theme.outline), style: outline)
        }
        for roof in frame.roofs {
            context.fill(roof, with: .color(Theme.waxRed))
            context.stroke(roof, with: .color(Theme.waxBorder), style: outline)
        }
        drawFlags(in: &context, frame: frame, pole: Theme.outline, outlined: true)
        context.fill(frame.wall, with: .color(Theme.stoneLight))
        context.stroke(frame.wall, with: .color(Theme.outline), style: outline)
        context.fill(frame.keep, with: .color(Theme.stone))
        context.stroke(frame.keep, with: .color(Theme.outline), style: outline)
        context.fill(frame.gate, with: .color(Theme.darkWood))
        context.stroke(frame.gate, with: .color(Theme.darkestWood), style: outline)
        context.stroke(frame.portcullis, with: .color(Theme.darkestWood), lineWidth: 2 * s)
        for window in frame.windows {
            context.fill(Path(roundedRect: window, cornerRadius: window.width / 2), with: .color(Theme.ink))
        }
        var mortar = Path()
        for (x, y, length) in [(-84.0, 402.0, 14.0), (-60, 444, 16), (48, 398, 14), (70, 448, 14), (-26, 384, 12),
                               (12, 410, 12), (-124, 404, 10), (112, 402, 10), (-22, 426, 10)] {
            mortar.move(to: frame.point(195 + x, y))
            mortar.addLine(to: frame.point(195 + x + length, y))
        }
        context.stroke(mortar, with: .color(Theme.stoneLine), style: StrokeStyle(lineWidth: 2 * s, lineCap: .round))

        for (x, y, r) in [(30.0, 470.0, 16.0), (52, 478, 12), (356, 468, 17), (334, 478, 11)] {
            let bush = circle(frame.point(x, y), r * s)
            context.fill(bush, with: .color(Theme.emerald))
            context.stroke(bush, with: .color(Theme.emeraldBorder), lineWidth: 2 * s)
        }
    }

    private func drawClouds(in context: inout GraphicsContext, frame: SceneFrame, time: TimeInterval) {
        // (x, y, puffs as (dx, dy, rx, ry), drift speed in design pt/s)
        let clouds: [(CGFloat, CGFloat, [(CGFloat, CGFloat, CGFloat, CGFloat)], Double)] = [
            (52, 62, [(0, 0, 34, 13), (24, -10, 22, 14), (-18, -8, 16, 10)], 2.0),
            (338, 84, [(0, 0, 30, 11), (-18, -8, 18, 11), (18, -8, 14, 9)], 1.4),
            (60, 286, [(0, 0, 38, 12), (22, -10, 20, 12)], 0.9),
        ]
        let span = 390.0 + 120
        for (x, y, puffs, speed) in clouds {
            let drifted = (Double(x) + 60 + time * speed).truncatingRemainder(dividingBy: span) - 60
            var cloud = Path()
            for (dx, dy, rx, ry) in puffs {
                cloud.addEllipse(in: frame.rect(CGFloat(drifted) + dx - rx, y + dy - ry, rx * 2, ry * 2))
            }
            context.fill(cloud, with: .color(.white.opacity(0.92)))
        }
    }

    // MARK: Shared

    private func drawSky(in context: inout GraphicsContext, frame: SceneFrame, stops: [Gradient.Stop]) {
        // Runs a little past the ridge bases so no gap shows above the ground curve.
        let horizon = frame.point(0, 500).y
        context.fill(Path(CGRect(x: 0, y: 0, width: frame.size.width, height: horizon)),
                     with: .linearGradient(Gradient(stops: stops), startPoint: .zero,
                                           endPoint: CGPoint(x: 0, y: horizon)))
    }

    private func drawFlags(in context: inout GraphicsContext, frame: SceneFrame, pole: Color, outlined: Bool) {
        let s = frame.scale
        let flags: [(CGFloat, CGFloat, CGFloat, Color, Color)] = [
            (-112, 292, 264, Theme.waxRed, Theme.waxBorder),
            (112, 292, 264, Theme.sapphire, Theme.sapphireBorder),
            (0, 304, 274, Theme.gold, Theme.outline),
        ]
        for (x, base, top, fill, border) in flags {
            var staff = Path()
            staff.move(to: frame.point(195 + x, base))
            staff.addLine(to: frame.point(195 + x, top))
            context.stroke(staff, with: .color(pole), lineWidth: 2.5 * s)
            let flag = frame.polygon([(195 + x, top), (195 + x + 22, top + 7), (195 + x, top + 14)])
            context.fill(flag, with: .color(fill))
            if outlined {
                context.stroke(flag, with: .color(border), style: StrokeStyle(lineWidth: 1.5 * s, lineJoin: .round))
            }
        }
    }

    private func circle(_ center: CGPoint, _ radius: CGFloat) -> Path {
        Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
    }
}

/// Maps the 390-pt design grid (ground line at y = 480) onto the screen.
private struct SceneFrame {
    let size: CGSize
    let groundY: CGFloat

    static let farRidge: [(CGFloat, CGFloat)] = [(0, 400), (46, 356), (96, 392), (150, 340), (205, 388), (262, 350),
                                                 (318, 392), (360, 358), (390, 380), (390, 490), (0, 490)]
    static let nearRidge: [(CGFloat, CGFloat)] = [(0, 446), (40, 418), (92, 452), (140, 420), (200, 456), (252, 430),
                                                  (310, 446), (356, 422), (390, 442), (390, 490), (0, 490)]
    static let snowCaps: [[(CGFloat, CGFloat)]] = [
        [(150, 340), (138, 352), (150, 349), (160, 356), (163, 351)],
        [(46, 356), (36, 366), (47, 363), (55, 366)],
        [(262, 350), (251, 358), (262, 356), (271, 358)],
        [(360, 358), (350, 366), (361, 364), (368, 365)],
    ]

    var scale: CGFloat { size.width / 390 }

    func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        CGPoint(x: x * scale, y: groundY + (y - 480) * scale)
    }

    func rect(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) -> CGRect {
        CGRect(origin: point(x, y), size: CGSize(width: width * scale, height: height * scale))
    }

    func polygon(_ points: [(CGFloat, CGFloat)]) -> Path {
        Path { path in
            path.addLines(points.map { point($0.0, $0.1) })
            path.closeSubpath()
        }
    }

    /// Hill the castle stands on, running to the bottom of the screen.
    var ground: Path {
        Path { path in
            path.move(to: point(0, 492))
            path.addQuadCurve(to: point(390, 492), control: point(195, 440))
            path.addLine(to: CGPoint(x: size.width, y: size.height))
            path.addLine(to: CGPoint(x: 0, y: size.height))
            path.closeSubpath()
        }
    }

    /// Road widening from the gate toward the viewer.
    var path: Path {
        Path { path in
            path.move(to: point(177, 480))
            path.addLine(to: point(213, 480))
            path.addLine(to: CGPoint(x: point(300, 0).x, y: size.height))
            path.addLine(to: CGPoint(x: point(90, 0).x, y: size.height))
            path.closeSubpath()
        }
    }

    // Castle, centered on x = 195.

    var towers: [CGRect] { [rect(63, 346, 40, 138), rect(287, 346, 40, 138)] }

    var roofs: [Path] {
        [polygon([(57, 347), (83, 290), (109, 347)]), polygon([(281, 347), (307, 290), (333, 347)])]
    }

    var wall: Path { crenellated(from: 99, top: 370, widths: [12, 8, 12, 8, 12, 88, 12, 8, 12, 8, 12]) }

    var keep: Path { crenellated(from: 159, top: 302, widths: [11, 9, 11, 10, 11, 9, 11]) }

    var gate: Path {
        Path { path in
            path.move(to: point(177, 484))
            path.addLine(to: point(177, 452))
            path.addArc(center: point(195, 452), radius: 18 * scale, startAngle: .degrees(180),
                        endAngle: .degrees(0), clockwise: false)
            path.addLine(to: point(213, 484))
            path.closeSubpath()
        }
    }

    var portcullis: Path {
        Path { path in
            path.move(to: point(177, 462)); path.addLine(to: point(213, 462))
            for (x, top) in [(186.0, 438.0), (195, 434), (204, 438)] {
                path.move(to: point(x, top)); path.addLine(to: point(x, 484))
            }
        }
    }

    var windows: [CGRect] {
        [rect(189, 334, 12, 18), rect(78, 374, 9, 14), rect(303, 374, 9, 14), rect(125, 410, 8, 13),
         rect(257, 410, 8, 13), rect(78, 424, 9, 14), rect(303, 424, 9, 14)]
    }

    /// Wall outline whose top alternates between merlons (at `top`) and gaps 10 pt lower.
    private func crenellated(from x: CGFloat, top: CGFloat, widths: [CGFloat]) -> Path {
        Path { path in
            var cursor = x
            var raised = true
            path.move(to: point(cursor, 484))
            path.addLine(to: point(cursor, top))
            for (index, width) in widths.enumerated() {
                cursor += width
                path.addLine(to: point(cursor, raised ? top : top + 10))
                if index < widths.count - 1 {
                    raised.toggle()
                    path.addLine(to: point(cursor, raised ? top : top + 10))
                }
            }
            path.addLine(to: point(cursor, 484))
            path.closeSubpath()
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

#Preview("Night") {
    CastleGateScene(timeOfDay: .night, groundY: 500)
}

#Preview("Day") {
    CastleGateScene(timeOfDay: .day, groundY: 500)
}
