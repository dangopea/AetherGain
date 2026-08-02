//
//  TargetsCalculator.swift
//  AetherGain
//
//  Computes BMR, activity multiplier, TDEE and daily macro targets
//  from a UserProfile. Uses Mifflin-St Jeor by default and falls back
//  to Katch-McArdle when body-fat percent is provided.
//
//  Assumptions & sources embedded in comments so this is auditable
//  for the IB IA write-up.
//

import Foundation

struct DailyTargets: Equatable {
    var bmr: Int
    var activityMultiplier: Double
    var tdee: Int
    var calories: Int
    var proteinG: Int
    var carbsG: Int
    var fatG: Int

    /// One-line human summary used in the UI.
    var summary: String {
        "BMR \(bmr) kcal · TDEE \(tdee) kcal · target \(calories) kcal"
    }
}

enum TargetsCalculator {

    // MARK: - Public

    static func compute(for profile: UserProfile) -> DailyTargets {
        let bmr = basalMetabolicRate(profile)
        let multiplier = activityMultiplier(profile)
        let tdee = bmr * multiplier

        let goalDeltaKcal = goalDailyKcalDelta(profile)
        let calories = max(1200, tdee + goalDeltaKcal)  // clamp for safety

        // Protein first (fixed g/kg), fat next (25% of calories), carbs = rest.
        let protein = profile.weightKG * profile.proteinPreference.gramsPerKg
        let fat     = (calories * 0.25) / 9.0        // 9 kcal / g
        var carbs   = (calories - protein * 4 - fat * 9) / 4.0
        if carbs < 0 { carbs = 0 }

        return DailyTargets(
            bmr: Int(bmr.rounded()),
            activityMultiplier: multiplier,
            tdee: Int(tdee.rounded()),
            calories: Int(calories.rounded()),
            proteinG: Int(protein.rounded()),
            carbsG: Int(carbs.rounded()),
            fatG: Int(fat.rounded())
        )
    }

    /// Apply computed targets back onto the profile so we can save them.
    static func apply(_ targets: DailyTargets, to profile: inout UserProfile) {
        profile.bmr = targets.bmr
        profile.tdee = targets.tdee
        profile.calorieTarget = targets.calories
        profile.proteinTargetG = targets.proteinG
        profile.carbsTargetG = targets.carbsG
        profile.fatTargetG = targets.fatG
        profile.hasOnboardedTargets = true
    }

    // MARK: - Formulae

    /// Kilocalories/day at complete rest.
    static func basalMetabolicRate(_ p: UserProfile) -> Double {
        // If body fat is known, use Katch-McArdle (most accurate for lean users).
        if let bfPercent = p.bodyFatPercent, bfPercent > 0, bfPercent < 60 {
            let lbmKg = p.weightKG * (1 - bfPercent / 100.0)
            return 370 + 21.6 * lbmKg
        }

        // Otherwise Mifflin-St Jeor (1990).
        let base = 10 * p.weightKG + 6.25 * p.heightCM - 5 * Double(p.age)
        switch p.sex {
        case .male:   return base + 5
        case .female: return base - 161
        case .other:  return base - 78  // gender-neutral average of ±5 / -161
        }
    }

    /// Activity multiplier scaled by BOTH self-reported workouts/week AND
    /// average steps/day, so users who walk a lot but train little still get
    /// realistic numbers.
    static func activityMultiplier(_ p: UserProfile) -> Double {
        // Workout-based baseline (Harris-Benedict style buckets).
        let workoutBase: Double = {
            switch p.workoutsPerWeek {
            case ..<1: return 1.20      // sedentary
            case 1...2: return 1.375    // light
            case 3...4: return 1.55     // moderate
            case 5...6: return 1.725    // active
            default:    return 1.90     // very active
            }
        }()

        // Step bonus: NEAT contribution above sedentary baseline.
        let steps = Double(p.avgStepsPerDay)
        let stepBonus: Double = {
            switch steps {
            case ..<3000:   return 0.0
            case 3000..<6000:  return 0.05
            case 6000..<9000:  return 0.10
            case 9000..<12000: return 0.15
            default:            return 0.20
            }
        }()

        return min(2.05, workoutBase + stepBonus)
    }

    /// Kcal to add or subtract vs TDEE for the chosen goal + rate.
    /// 1 kg body-fat ≈ 7700 kcal, so weekly delta / 7 gives daily.
    static func goalDailyKcalDelta(_ p: UserProfile) -> Double {
        let daily = (p.goalRateKgPerWeek * 7700.0) / 7.0
        switch p.fitnessGoal {
        case .maintain: return 0
        case .cut:      return -daily
        case .bulk:     return +daily
        }
    }
}
