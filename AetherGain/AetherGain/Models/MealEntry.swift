




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


    var amount: Double = 100
    var unit: String = "g"


    var per100gCalories: Double = 0
    var per100gProtein: Double = 0
    var per100gCarbs: Double = 0
    var per100gFat: Double = 0


    var grams: Double = 100


    var calories: Double = 0
    var protein: Double = 0
    var carbs: Double = 0
    var fat: Double = 0

    var notes: String = ""
    var photoURL: String? = nil




    var macroSource: String = "Manual"

    init() {}
}
