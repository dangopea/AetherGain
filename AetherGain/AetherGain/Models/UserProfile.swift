








import Foundation
import FirebaseFirestore

enum Sex: String, Codable, CaseIterable, Identifiable {
    case male   = "Male"
    case female = "Female"
    case other  = "Prefer not to say"
    var id: String { rawValue }
}

enum FitnessGoal: String, Codable, CaseIterable, Identifiable {
    case cut      = "Cut"
    case maintain = "Maintain"
    case bulk     = "Bulk"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .cut:      return "arrow.down.circle.fill"
        case .maintain: return "equal.circle.fill"
        case .bulk:     return "arrow.up.circle.fill"
        }
    }
}

enum ProteinPreference: String, Codable, CaseIterable, Identifiable {
    case low    = "Low"
    case medium = "Medium"
    case high   = "High"
    var id: String { rawValue }

    var gramsPerKg: Double {
        switch self {
        case .low: return 1.6
        case .medium: return 2.0
        case .high: return 2.5
        }
    }
}

struct UserProfile: Identifiable, Codable {
    @DocumentID var id: String? = UUID().uuidString


    var name: String = ""
    var age: Int = 18
    var sex: Sex = .other
    var goals: String = ""
    var preferences: String = ""
    var experienceLevel: String = "Beginner"


    var heightCM: Double = 170.0
    var weightKG: Double = 70.0
    var bodyFatPercent: Double? = nil


    var avgStepsPerDay: Int = 6000
    var workoutsPerWeek: Int = 3


    var fitnessGoal: FitnessGoal = .maintain
    var goalRateKgPerWeek: Double = 0.5
    var proteinPreference: ProteinPreference = .medium


    var bmr: Int = 0
    var tdee: Int = 0
    var calorieTarget: Int = 0
    var proteinTargetG: Int = 0
    var carbsTargetG: Int = 0
    var fatTargetG: Int = 0
    var hasOnboardedTargets: Bool = false


    var dailyWaterML: Double = 0.0
    var waterMLTarget: Double = 2500
    var sleepHours: Double = 0.0
    var sleepHoursTarget: Double = 8
    var customHabitName: String = "Meditation"
    var customHabitCompletedToday: Bool = false
    var streakDays: Int = 0
    var lastHabitDate: Date? = nil

    var remindersEnabled: Bool = false
    var reminderHour: Int = 20
    var reminderMinute: Int = 0


    var xp: Int = 0
    var sharesToLeaderboard: Bool? = false


    var profileImageURL: String? = nil

    init() {}
}
