//
//  TimeOfDay.swift
//  Fantasy Fitness
//

import Foundation

/// Which title-screen look to show, decided by the device clock.
enum TimeOfDay: String {
    case day, night

    /// Local hours that count as daytime (6:00 am up to, not including, 6:00 pm).
    static let dayHours = 6..<18

    static func at(_ date: Date, calendar: Calendar = .current) -> TimeOfDay {
        dayHours.contains(calendar.component(.hour, from: date)) ? .day : .night
    }

    /// Forces a look when launched with `-titleTimeOfDay day` or `-titleTimeOfDay night`.
    static var debugOverride: TimeOfDay? {
        UserDefaults.standard.string(forKey: "titleTimeOfDay").flatMap(TimeOfDay.init(rawValue:))
    }
}
