//
//  MealEntry.swift
//  AetherGain
//

import Foundation
import FirebaseFirestore

enum MealType: String, Codable, CaseIterable, Identifiable {
    case breakfast = "Breakfast"
    case lunch     = "Lunch"
    case dinner    = "Dinner"
    case snack     = "Snack"

    var id: String { rawValue }
    var icon: String {
        switch self {
        case .breakfast: return "sun.max.fill"
        case .lunch:     return "fork.knife"
        case .dinner:    return "moon.stars.fill"
        case .snack:     return "sparkles"
        }
    }
    static func defaultFor(hour: Int) -> MealType {
        switch hour {
        case 4..<11:  return .breakfast
        case 11..<15: return .lunch
        case 15..<18: return .snack
        default:      return .dinner
        }
    }
}

struct MealEntry: Identifiable, Codable {
    @DocumentID var id: String? = UUID().uuidString

    var date: Date = Date()
    var mealType: MealType = .snack

    var foodName: String = ""

    /// User-visible amount + unit (e.g. 100 "g", 1 "cup", 2 "pieces").
    var amount: Double = 100
    var unit: String = "g"

    // Reference macros per 100 g (what we display as "per 100g gives you...").
    var per100gCalories: Double = 0
    var per100gProtein: Double = 0
    var per100gCarbs: Double = 0
    var per100gFat: Double = 0

    /// Estimated grams for this entry (drives the final macro numbers).
    var grams: Double = 100

    // Final macro totals for this entry = grams * per100g / 100.
    var calories: Double = 0
    var protein: Double = 0
    var carbs: Double = 0
    var fat: Double = 0

    var notes: String = ""
    var photoURL: String? = nil

    /// Where the macros came from — shown in the diary card so it's clear
    /// whether the numbers are curated, third-party, or user-entered.
    /// Values: "Local DB", "OpenFoodFacts", "Manual".
    var macroSource: String = "Manual"

    init() {}
}
