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
    let bodyweight: Int

    var targetWeight: Int { Int((Double(bodyweight) * bodyweightMultiple).rounded()) }
    var standard: String { "\(rank)-rank \(lift.lowercased()) · \(bodyweightMultiple.formatted(.number.precision(.fractionLength(1))))× bodyweight" }
}

// MARK: - Hard-coded sample data

extension RankExam {
    static let sample = RankExam(id: "d-bench", rank: "D", lift: "Bench", bodyweightMultiple: 1.0, bodyweight: 185)
}
