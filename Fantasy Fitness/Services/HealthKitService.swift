//
//  HealthKitService.swift
//  Fantasy Fitness
//
//  Reads sleep, daily/weekly steps, and cardio summaries from Apple Health on-device.
//  Raw HealthKit records never leave the phone; only summaries are passed to
//  SleepService / LocalStore.
//

import Foundation
import HealthKit
import Observation

struct HealthKitCardioSummary: Identifiable, Sendable {
    /// Uses the HKWorkout's UUID so re-syncing the same workout never duplicates it.
    let id: UUID
    let activity: String
    let distanceKm: Double
    let durationMin: Double
    let startedAt: Date
    let loggedOn: String
}

struct DayCheck: Identifiable, Sendable {
    let id: String
    let label: String
    let isComplete: Bool
    let isToday: Bool
    var loggedOn: String = ""
    var steps: Int = 0
}

@Observable
final class HealthKitService {
    private(set) var isAuthorized = false
    private(set) var isSyncing = false
    private(set) var lastNightSleepHours: Double?
    private(set) var todaySteps: Int = 0
    private(set) var weeklySteps: [DayCheck] = []
    private(set) var weeklySleep: [DayCheck] = []
    private(set) var recentCardio: [HealthKitCardioSummary] = []
    private(set) var lastError: String?

    @ObservationIgnored private let store = HKHealthStore()
    @ObservationIgnored private let enabledKey = "healthKitEnabled"

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: enabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: enabledKey) }
    }

    init() {
        isAuthorized = isEnabled && isAvailable
    }

    /// Prompts the user for read-only access to Sleep, Steps, and Workouts.
    func connect() async {
        guard isAvailable else {
            lastError = "Apple Health isn't available on this device."
            return
        }
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis),
              let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else { return }
        let readTypes: Set<HKObjectType> = [sleepType, stepType, HKObjectType.workoutType()]

        do {
            try await store.requestAuthorization(toShare: [], read: readTypes)
            isEnabled = true
            isAuthorized = true
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    func disconnect() {
        isEnabled = false
        isAuthorized = false
        lastNightSleepHours = nil
        todaySteps = 0
        weeklySteps = []
        weeklySleep = []
        recentCardio = []
    }

    /// Pulls last night's sleep, today's steps, weekly checkmarks, and recent cardio.
    func refresh() async {
        guard isAvailable, isEnabled else { return }
        isSyncing = true
        lastError = nil
        defer { isSyncing = false }

        do {
            async let sleep = fetchLastNightSleepHours()
            async let steps = fetchTodaySteps()
            async let weekSteps = fetchWeeklySteps()
            async let weekSleep = fetchWeeklySleep()
            async let cardio = fetchRecentCardio(days: 7)
            lastNightSleepHours = try await sleep
            todaySteps = try await steps
            weeklySteps = try await weekSteps
            weeklySleep = try await weekSleep
            recentCardio = try await cardio
        } catch {
            lastError = error.localizedDescription
        }
    }

    // MARK: - Week helper (Monday -> Sunday)

    private func currentWeekDays() -> [(date: Date, label: String, isToday: Bool)] {
        var cal = Calendar.current
        cal.firstWeekday = 2 // Monday
        let today = cal.startOfDay(for: .now)
        let components = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
        let monday = cal.date(from: components) ?? today
        let labels = ["M", "T", "W", "T", "F", "S", "S"]
        return (0..<7).compactMap { offset in
            guard let day = cal.date(byAdding: .day, value: offset, to: monday) else { return nil }
            return (day, labels[offset], cal.isDate(day, inSameDayAs: today))
        }
    }

    // MARK: - Steps (today & this week)

    private func fetchTodaySteps() async throws -> Int {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return 0 }
        let startOfToday = Calendar.current.startOfDay(for: .now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfToday, end: .now, options: .strictStartDate)

        return try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Int, Error>) in
            let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, error in
                if let error {
                    if (error as? HKError)?.code == .errorNoData {
                        cont.resume(returning: 0)
                    } else {
                        cont.resume(throwing: error)
                    }
                    return
                }
                let count = stats?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                cont.resume(returning: Int(count.rounded()))
            }
            store.execute(query)
        }
    }

    private func fetchWeeklySteps() async throws -> [DayCheck] {
            guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return [] }
            let days = currentWeekDays()
            guard let monday = days.first?.date,
                  let endOfWeek = Calendar.current.date(byAdding: .day, value: 7, to: monday) else { return [] }

            let predicate = HKQuery.predicateForSamples(withStart: monday, end: endOfWeek, options: .strictStartDate)
            let interval = DateComponents(day: 1)

            return try await withCheckedThrowingContinuation { (cont: CheckedContinuation<[DayCheck], Error>) in
                let query = HKStatisticsCollectionQuery(
                    quantityType: stepType,
                    quantitySamplePredicate: predicate,
                    options: .cumulativeSum,
                    anchorDate: monday,
                    intervalComponents: interval
                )
                query.initialResultsHandler = { _, collection, error in
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"

                    if let error {
                        if (error as? HKError)?.code == .errorNoData {
                            cont.resume(returning: days.enumerated().map {
                                DayCheck(
                                    id: "step-\($0.offset)",
                                    label: $0.element.label,
                                    isComplete: false,
                                    isToday: $0.element.isToday,
                                    loggedOn: formatter.string(from: $0.element.date),
                                    steps: 0
                                )
                            })
                        } else {
                            cont.resume(throwing: error)
                        }
                        return
                    }

                    let checks = days.enumerated().map { offset, day in
                        let steps = Int((collection?.statistics(for: day.date)?.sumQuantity()?.doubleValue(for: .count()) ?? 0).rounded())
                        return DayCheck(
                            id: "step-\(offset)",
                            label: day.label,
                            isComplete: steps >= DailySteps.goal,
                            isToday: day.isToday,
                            loggedOn: formatter.string(from: day.date),
                            steps: steps
                        )
                    }
                    cont.resume(returning: checks)
                }
                store.execute(query)
            }
        }

    // MARK: - Sleep (last night & this week)

    private func fetchLastNightSleepHours() async throws -> Double? {
        let cal = Calendar.current
        let startOfToday = cal.startOfDay(for: .now)
        guard let windowStart = cal.date(byAdding: .hour, value: -6, to: startOfToday),
              let windowEnd = cal.date(byAdding: .hour, value: 12, to: startOfToday) else { return nil }
        let samples = try await fetchAsleepSamples(from: windowStart, to: windowEnd)
        return Self.mergedHours(from: samples, within: DateInterval(start: windowStart, end: windowEnd))
    }

    private func fetchWeeklySleep() async throws -> [DayCheck] {
        let cal = Calendar.current
        let days = currentWeekDays()
        guard let monday = days.first?.date,
              let queryStart = cal.date(byAdding: .hour, value: -6, to: monday),
              let queryEnd = cal.date(byAdding: .day, value: 7, to: monday) else { return [] }

        let samples = try await fetchAsleepSamples(from: queryStart, to: queryEnd)
        return days.enumerated().map { offset, day in
            let windowStart = cal.date(byAdding: .hour, value: -6, to: day.date) ?? day.date
            let windowEnd = cal.date(byAdding: .hour, value: 12, to: day.date) ?? day.date
            let hours = Self.mergedHours(from: samples, within: DateInterval(start: windowStart, end: windowEnd)) ?? 0
            return DayCheck(
                id: "sleep-\(offset)",
                label: day.label,
                isComplete: hours >= Recovery.wellRestedHours,
                isToday: day.isToday
            )
        }
    }

    private func fetchAsleepSamples(from start: Date, to end: Date) async throws -> [HKCategorySample] {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return [] }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let samples = try await withCheckedThrowingContinuation { (cont: CheckedContinuation<[HKCategorySample], Error>) in
            let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, results, error in
                if let error { cont.resume(throwing: error); return }
                cont.resume(returning: (results as? [HKCategorySample]) ?? [])
            }
            store.execute(query)
        }
        let asleepValues: Set<Int> = [
            HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
            HKCategoryValueSleepAnalysis.asleepCore.rawValue,
            HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
            HKCategoryValueSleepAnalysis.asleepREM.rawValue
        ]
        return samples.filter { asleepValues.contains($0.value) }
    }

    private static func mergedHours(from samples: [HKCategorySample], within window: DateInterval) -> Double? {
        let intervals = samples
            .compactMap { DateInterval(start: $0.startDate, end: $0.endDate).intersection(with: window) }
            .filter { $0.duration > 0 }
            .sorted { $0.start < $1.start }

        guard !intervals.isEmpty else { return nil }
        var merged: [DateInterval] = [intervals[0]]
        for next in intervals.dropFirst() {
            let last = merged[merged.count - 1]
            if next.start <= last.end {
                merged[merged.count - 1] = DateInterval(start: last.start, end: max(last.end, next.end))
            } else {
                merged.append(next)
            }
        }
        let totalSeconds = merged.reduce(0.0) { $0 + $1.duration }
        return totalSeconds > 0 ? totalSeconds / 3600.0 : nil
    }

    // MARK: - Cardio Workouts

    private func fetchRecentCardio(days: Int) async throws -> [HealthKitCardioSummary] {
        let start = Calendar.current.date(byAdding: .day, value: -days, to: .now) ?? .now
        let predicate = HKQuery.predicateForSamples(withStart: start, end: .now, options: .strictStartDate)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        let workouts = try await withCheckedThrowingContinuation { (cont: CheckedContinuation<[HKWorkout], Error>) in
            let query = HKSampleQuery(sampleType: .workoutType(), predicate: predicate, limit: 50, sortDescriptors: [sort]) { _, results, error in
                if let error { cont.resume(throwing: error); return }
                cont.resume(returning: (results as? [HKWorkout]) ?? [])
            }
            store.execute(query)
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        return workouts.compactMap { workout in
            guard let label = Self.cardioLabel(for: workout.workoutActivityType) else { return nil }
            let rawMinutes = (workout.duration / 60.0 * 10).rounded() / 10
            let durationMin = min(1440, max(1, rawMinutes))
            let rawKm = workout.totalDistance.map { $0.doubleValue(for: .meterUnit(with: .kilo)) } ?? 0
            let distanceKm = min(500, max(0, (rawKm * 100).rounded() / 100))
            return HealthKitCardioSummary(
                id: workout.uuid,
                activity: label,
                distanceKm: distanceKm,
                durationMin: durationMin,
                startedAt: workout.startDate,
                loggedOn: formatter.string(from: workout.startDate)
            )
        }
    }

    private static func cardioLabel(for type: HKWorkoutActivityType) -> String? {
        switch type {
        case .running: return "run"
        case .walking: return "walk"
        case .cycling: return "bike"
        case .swimming: return "swim"
        case .rowing: return "row"
        case .elliptical: return "elliptical"
        case .stairClimbing: return "stairs"
        case .highIntensityIntervalTraining: return "hiit"
        default: return nil
        }
    }
}
