import Foundation

struct Badge: Identifiable, Hashable {
    let id: String
    let title: String
    let requirement: String
}

enum GameEngine {
    static func workoutXP(for session: WorkoutSession) -> Int {
        guard session.isValidForXP else { return 0 }

        return session.exercises.reduce(50) { total, exercise in
            total + exerciseXP(for: exercise)
        }
    }

    static func exerciseXP(for exercise: Exercise) -> Int {
        switch exercise.category ?? .strength {
        case .strength:
            let volume = Double(exercise.sets * exercise.reps) * max(exercise.weightKG, 1)
            return max(5, Int(volume / 20))
        case .cardio:
            let durationScore = Int((exercise.durationMinutes ?? 0) * 2)
            let distanceScore = Int((exercise.distanceKM ?? 0) * 8)
            let inclineScore = Int((exercise.inclinePercent ?? 0) * 2)
            return max(10, durationScore + distanceScore + inclineScore)
        case .mobility:
            return max(5, Int((exercise.durationMinutes ?? 0) * 1.5))
        }
    }

    static func level(for xp: Int) -> Int {
        max(1, (xp / 500) + 1)
    }

    static func xpForNextLevel(from xp: Int) -> Int {
        let nextLevelStart = level(for: xp) * 500
        return max(0, nextLevelStart - xp)
    }

    static func badges(for xp: Int, streakDays: Int) -> [Badge] {
        var earned: [Badge] = []

        if xp >= 500 {
            earned.append(Badge(id: "level-2", title: "Level 2", requirement: "Earn 500 XP"))
        }
        if xp >= 2500 {
            earned.append(Badge(id: "level-6", title: "Consistency Builder", requirement: "Earn 2500 XP"))
        }
        if streakDays >= 7 {
            earned.append(Badge(id: "streak-7", title: "7 Day Streak", requirement: "Complete habits for 7 days"))
        }
        if streakDays >= 30 {
            earned.append(Badge(id: "streak-30", title: "30 Day Streak", requirement: "Complete habits for 30 days"))
        }

        return earned
    }
}
