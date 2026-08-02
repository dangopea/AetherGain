//
//  ProgressAnalytics.swift
//  AetherGain
//
//  Criterion 8: dynamic weekly aggregates for XP, workouts, macros, habits.
//  Also provides CSV export used both from the app and by the Python analysis script.
//

import Foundation

struct DailyStat: Identifiable {
    let id = UUID()
    let day: Date          // startOfDay
    let dayLabel: String   // "Mon"
    let xp: Int
    let workouts: Int
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let waterML: Double
    let sleepHours: Double
    let habitDone: Bool
}

enum ProgressAnalytics {

    static func weeklyStats(workouts: [WorkoutSession],
                            meals: [MealEntry],
                            profile: UserProfile,
                            reference: Date = Date()) -> [DailyStat] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: reference)
        let days: [Date] = (0..<7).reversed().map { offset in
            cal.date(byAdding: .day, value: -offset, to: today) ?? today
        }

        let df = DateFormatter()
        df.dateFormat = "EEE"

        return days.map { day in
            let dayEnd = cal.date(byAdding: .day, value: 1, to: day) ?? day

            let dayWorkouts = workouts.filter { $0.date >= day && $0.date < dayEnd }
            let dayXP = dayWorkouts.reduce(0) { $0 + $1.totalXP }

            let dayMeals = meals.filter { $0.date >= day && $0.date < dayEnd }
            let cals = dayMeals.reduce(0) { $0 + $1.calories }
            let pro  = dayMeals.reduce(0) { $0 + $1.protein }
            let carb = dayMeals.reduce(0) { $0 + $1.carbs }
            let fat  = dayMeals.reduce(0) { $0 + $1.fat }

            let isToday = cal.isDate(day, inSameDayAs: today)
            let waterML = isToday ? profile.dailyWaterML : 0
            let sleep   = isToday ? profile.sleepHours   : 0
            let habit   = isToday ? profile.customHabitCompletedToday : false

            return DailyStat(day: day,
                             dayLabel: df.string(from: day),
                             xp: dayXP,
                             workouts: dayWorkouts.count,
                             calories: cals,
                             protein: pro,
                             carbs: carb,
                             fat: fat,
                             waterML: waterML,
                             sleepHours: sleep,
                             habitDone: habit)
        }
    }

    // MARK: - 12-week activity heatmap

    struct HeatmapCell: Identifiable {
        var id: Date { day }
        let day: Date
        let intensity: Double   // 0...1 (workout XP normalised)
    }

    static func heatmap(workouts: [WorkoutSession],
                        weeks: Int = 12,
                        reference: Date = Date()) -> [HeatmapCell] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: reference)
        let totalDays = weeks * 7
        let start = cal.date(byAdding: .day, value: -(totalDays - 1), to: today) ?? today

        // Bucket workouts by day.
        var xpByDay: [Date: Int] = [:]
        for w in workouts {
            let d = cal.startOfDay(for: w.date)
            xpByDay[d, default: 0] += w.totalXP
        }

        let maxXP = max(1, xpByDay.values.max() ?? 1)

        var cells: [HeatmapCell] = []
        for offset in 0..<totalDays {
            let day = cal.date(byAdding: .day, value: offset, to: start) ?? start
            let xp = xpByDay[cal.startOfDay(for: day)] ?? 0
            let intensity = min(1, Double(xp) / Double(maxXP))
            cells.append(HeatmapCell(day: day, intensity: intensity))
        }
        return cells
    }

    // MARK: - CSV export

    static func csv(from stats: [DailyStat]) -> String {
        var lines = ["date,day,xp,workouts,calories,protein_g,carbs_g,fat_g,water_ml,sleep_hours,habit_done"]
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        for s in stats {
            let row = [
                df.string(from: s.day),
                s.dayLabel,
                String(s.xp),
                String(s.workouts),
                String(format: "%.1f", s.calories),
                String(format: "%.1f", s.protein),
                String(format: "%.1f", s.carbs),
                String(format: "%.1f", s.fat),
                String(format: "%.0f", s.waterML),
                String(format: "%.1f", s.sleepHours),
                s.habitDone ? "1" : "0"
            ].joined(separator: ",")
            lines.append(row)
        }
        return lines.joined(separator: "\n")
    }

    /// Writes the CSV into the app's Documents directory (survives past the
    /// ShareSheet dismiss + can be re-shared or picked up by Files.app).
    /// Falls back to tmp if Documents is unavailable.
    static func writeCSVToTemp(_ csv: String, name: String = "aethergain_weekly.csv") -> URL? {
        let fm = FileManager.default
        let base: URL
        if let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first {
            base = docs
        } else {
            base = fm.temporaryDirectory
        }
        // Filename with a timestamp so each export shows up separately.
        let timestamp = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
        let final = "aethergain_weekly_\(timestamp).csv"
        let url = base.appendingPathComponent(final)
        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            print("CSV write failed: \(error)")
            return nil
        }
    }
}
