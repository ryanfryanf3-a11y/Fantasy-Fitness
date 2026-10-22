//
//  RankExam.swift
//  Fantasy Fitness
//

import Foundation

/// A rank exam the player has unlocked. Standards are bodyweight-relative.
struct RankExam: Identifiable {
    let id: String
    let rank: String
    let lift: String
    let bodyweightMultiple: Double
    /// The player's bodyweight in lb, if they've entered it.
    let bodyweight: Double?

    var targetWeight: Int? { bodyweight.map { Int(($0 * bodyweightMultiple).rounded()) } }
    var standard: String { "\(rank)-rank \(lift.lowercased()) · \(bodyweightMultiple.formatted(.number.precision(.fractionLength(1))))× bodyweight" }
}

// MARK: - Sample data (previews and offline demo mode)

extension RankExam {
    static let sample = RankExam(id: "d-bench", rank: "D", lift: "Bench", bodyweightMultiple: 1.0, bodyweight: 185)
}
