//
//  UserProfile.swift
//  AetherGain
//
//  Firestore user document. Encrypted at rest by Google Cloud and in
//  transit via HTTPS. Also stores computed daily targets (BMR/TDEE)
//  and customisable habit/reminder settings.
//

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
    /// Grams of protein per kg of body weight.
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

    // --- Identity (Criterion 2)
    var name: String = ""
    var age: Int = 18
    var sex: Sex = .other
    var goals: String = ""
    var preferences: String = ""
    var experienceLevel: String = "Beginner"

    // --- Anthropometrics
    var heightCM: Double = 170.0
    var weightKG: Double = 70.0
    var bodyFatPercent: Double? = nil

    // --- Lifestyle (fuels BMR / TDEE)
    var avgStepsPerDay: Int = 6000
    var workoutsPerWeek: Int = 3

    // --- Goal & targets
    var fitnessGoal: FitnessGoal = .maintain
    var goalRateKgPerWeek: Double = 0.5
    var proteinPreference: ProteinPreference = .medium

    // Computed by TargetsCalculator — cached for offline display.
    var bmr: Int = 0
    var tdee: Int = 0
    var calorieTarget: Int = 0
    var proteinTargetG: Int = 0
    var carbsTargetG: Int = 0
    var fatTargetG: Int = 0
    var hasOnboardedTargets: Bool = false

    // --- Habit customisation (Criterion 6)
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

    // --- Gamification & privacy
    var xp: Int = 0
    var sharesToLeaderboard: Bool? = false

    // --- Avatar (Firebase Storage URL)
    var profileImageURL: String? = nil

    init() {}
}
