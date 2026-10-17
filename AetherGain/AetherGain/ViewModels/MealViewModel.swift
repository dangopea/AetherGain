






















import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine
import Vision
import UIKit

struct FoodCandidate: Identifiable, Hashable {
    let id = UUID()
    let rawLabel: String
    let confidence: Float
    let matched: String?
}

class MealViewModel: ObservableObject {
    @Published var meals: [MealEntry] = []
    @Published var currentMeal: MealEntry = MealEntry()
    @Published var isLoading = false
    @Published var isAnalyzingPhoto = false
    @Published var errorMessage: String?
    @Published var candidates: [FoodCandidate] = []


    @Published var regionCandidates: [RegionCandidate] = []
    @Published var referenceHint: String? = nil



    @Published var editingMealID: String? = nil

    private var db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    private var userID: String? { Auth.auth().currentUser?.uid }

    init() {
        resetCurrentMeal()



        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            if user?.uid != nil {
                self.loadMeals()
            } else {
                self.meals = []
                self.listener?.remove()
                self.listener = nil
            }
        }

        loadMeals()
    }

    deinit {
        listener?.remove()
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }


    func editMeal(_ meal: MealEntry) {
        currentMeal = meal
        editingMealID = meal.id
        candidates = []
        referenceHint = nil
        errorMessage = nil
    }



    func loadMeals() {
        guard let uid = userID else { return }
        listener?.remove()
        listener = db.collection("users").document(uid).collection("meals")
            .order(by: "date", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                if error != nil {
                    DispatchQueue.main.async { self.errorMessage = "Couldn't load your meals. Check your connection and reopen this screen." }
                    return
                }
                let meals = snapshot?.documents.compactMap { try? $0.data(as: MealEntry.self) } ?? []
                DispatchQueue.main.async { self.meals = meals }
            }
    }

    func saveMeal() {
        guard let uid = userID else {
            DispatchQueue.main.async { self.errorMessage = "You're signed out. Sign in again to continue." }
            return
        }
        guard !currentMeal.foodName.trimmingCharacters(in: .whitespaces).isEmpty else {
            DispatchQueue.main.async { self.errorMessage = "Enter a food name or use a photo." }
            return
        }
        if currentMeal.calories == 0 { recalculateFromCurrent() }
        guard currentMeal.calories > 0 else {
            DispatchQueue.main.async {
                self.errorMessage = "No macros calculated yet. Tap Calculate."
            }
            return
        }

        DispatchQueue.main.async { self.isLoading = true }

        let collection = db.collection("users").document(uid).collection("meals")
        let ref: DocumentReference
        if let existingID = editingMealID {
            ref = collection.document(existingID)
        } else {
            ref = collection.document()
        }
        do {
            try ref.setData(from: currentMeal, merge: true) { [weak self] error in
                guard let self else { return }
                DispatchQueue.main.async {
                    if error != nil {
                        self.errorMessage = "Couldn't save this meal. Check your connection and tap Log again."
                    } else {
                        self.errorMessage = nil
                        self.resetCurrentMeal()
                    }
                    self.isLoading = false
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "This meal couldn't be prepared for saving. Check the food name and amount."
                self.isLoading = false
            }
        }
    }

    func deleteMeal(_ meal: MealEntry) {
        guard let uid = userID, let mealID = meal.id else { return }
        db.collection("users").document(uid).collection("meals").document(mealID).delete()
    }

    func resetCurrentMeal() {
        var fresh = MealEntry()
        fresh.mealType = MealType.defaultFor(hour: Calendar.current.component(.hour, from: Date()))
        fresh.unit = "g"
        fresh.amount = 100
        currentMeal = fresh
        candidates = []
        referenceHint = nil
        editingMealID = nil
    }










    func analyzeMealPhoto(_ image: UIImage) {
        guard image.cgImage != nil else {
            errorMessage = "Couldn't read this image (format not supported)."
            return
        }
        DispatchQueue.main.async {
            self.isAnalyzingPhoto = true
            self.errorMessage = nil
            self.candidates = []
        }



        FoodClassifier.classify(image: image) { [weak self] result in
            guard let self else { return }
            switch result {
            case .failure(_):
                DispatchQueue.main.async {
                    self.isAnalyzingPhoto = false
                    self.errorMessage = "That photo couldn't be analysed. Take another one in better light, or enter the food by hand."
                }
            case .success(let classified):
                let labelsAndConfs = classified.map { ($0.label, $0.confidence) }
                let candidates: [FoodCandidate] = classified.map { c in
                    let matched = FoodDatabase.bestMatch(fromLabels: [(c.label, c.confidence)])?.name
                    return FoodCandidate(rawLabel: c.label,
                                         confidence: c.confidence,
                                         matched: matched)
                }
                let bestFood = FoodDatabase.bestMatch(fromLabels: labelsAndConfs)

                DispatchQueue.main.async {
                    self.candidates = candidates
                    self.isAnalyzingPhoto = false
                    let usingBundled = FoodClassifier.isBundledModelAvailable
                    if let food = bestFood {
                        self.applyFood(food)
                    } else if let top = classified.first {

                        self.currentMeal.foodName = top.label.capitalized
                        let src = usingBundled ? "FoodClassifier" : "Vision default"
                        self.errorMessage = "\(src) returned \(classified.count) labels — none matched the local DB. Tap a chip, or edit the name and Calculate (OpenFoodFacts will try to resolve it)."
                    } else {
                        self.errorMessage = "The classifier returned no labels. Enter a food name manually."
                    }
                }
            }
        }
    }


    func clearPhotoAnalysis() {
        candidates = []
        referenceHint = nil
        errorMessage = nil
    }

    func selectCandidate(_ candidate: FoodCandidate) {
        if let name = candidate.matched, let food = FoodDatabase.byName(name) {
            applyFood(food)
        } else {
            currentMeal.foodName = candidate.rawLabel.capitalized
            calculateNutritionForCurrentMeal()
        }
    }



    func calculateNutritionForCurrentMeal() {
        let name = currentMeal.foodName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else {
            errorMessage = "Enter a food name first."
            return
        }



        if name.contains(",") {
            calculateBowlMacros(from: name)
            return
        }
        if let match = FoodDatabase.byName(name) {
            applyFood(match)
            return
        }
        fetchFromOpenFoodFacts(query: name)
    }




    private struct BowlIngredient {
        var amount: Double
        var unit: String
        var name: String
    }




    private func calculateBowlMacros(from input: String) {
        let tokens = input
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        var totalCal = 0.0, totalPro = 0.0, totalCarb = 0.0, totalFat = 0.0
        var totalGrams = 0.0
        var summaries: [String] = []
        var unknown: [String] = []

        for token in tokens {
            let ing = parseIngredient(token)
            guard let food = FoodDatabase.byName(ing.name) else {
                unknown.append(ing.name)
                continue
            }
            let grams = gramsFor(amount: ing.amount, unit: ing.unit, food: food)
            let factor = grams / 100.0
            let cal = food.calories * factor
            let pro = food.protein * factor
            let carb = food.carbs * factor
            let fat = food.fat * factor
            totalCal += cal
            totalPro += pro
            totalCarb += carb
            totalFat += fat
            totalGrams += grams
            summaries.append(String(format: "%@ (%.0f g → %.0f kcal)", food.name, grams, cal))
        }

        guard !summaries.isEmpty else {
            errorMessage = "Couldn't recognise any items in \"\(input)\". Try simpler names (e.g. \"100g oats, 250ml milk\")."
            return
        }




        let per100Factor = max(1, totalGrams) / 100.0
        currentMeal.per100gCalories = totalCal / per100Factor
        currentMeal.per100gProtein  = totalPro / per100Factor
        currentMeal.per100gCarbs    = totalCarb / per100Factor
        currentMeal.per100gFat      = totalFat / per100Factor
        currentMeal.grams = totalGrams
        currentMeal.calories = totalCal.rounded()
        currentMeal.protein  = (totalPro * 10).rounded() / 10
        currentMeal.carbs    = (totalCarb * 10).rounded() / 10
        currentMeal.fat      = (totalFat * 10).rounded() / 10
        currentMeal.amount = totalGrams
        currentMeal.unit = "g"
        currentMeal.macroSource = "Local DB"

        var hint = "SRC: BOWL · " + summaries.joined(separator: " + ")
        if !unknown.isEmpty {
            hint += " · SKIPPED: " + unknown.joined(separator: ", ")
        }
        referenceHint = hint
        errorMessage = unknown.isEmpty ? nil :
            "Ingredients not recognised: \(unknown.joined(separator: ", ")). Rename or omit them."
    }


    private func parseIngredient(_ raw: String) -> BowlIngredient {


        let text = raw.lowercased().trimmingCharacters(in: .whitespaces)


        if let match = text.range(of: #"^(\d+(?:\.\d+)?)([a-z]+)\s+(.+)$"#,
                                  options: .regularExpression) {
            let full = String(text[match])


            var num = ""
            var unit = ""
            var idx = full.startIndex
            while idx < full.endIndex, full[idx].isNumber || full[idx] == "." {
                num.append(full[idx]); idx = full.index(after: idx)
            }
            while idx < full.endIndex, full[idx].isLetter {
                unit.append(full[idx]); idx = full.index(after: idx)
            }
            let rest = full[idx...].trimmingCharacters(in: .whitespaces)
            let amount = Double(num) ?? 1
            return BowlIngredient(amount: amount, unit: unit, name: rest)
        }


        if let match = text.range(of: #"^(\d+(?:\.\d+)?)\s+(\S+)\s+(.+)$"#,
                                  options: .regularExpression) {
            let parts = text[match].split(separator: " ", maxSplits: 2,
                                          omittingEmptySubsequences: true)
            if parts.count == 3 {
                return BowlIngredient(
                    amount: Double(parts[0]) ?? 1,
                    unit: String(parts[1]),
                    name: String(parts[2])
                )
            }
        }


        if let match = text.range(of: #"^(\d+(?:\.\d+)?)\s+(.+)$"#,
                                  options: .regularExpression) {
            let parts = text[match].split(separator: " ", maxSplits: 1,
                                          omittingEmptySubsequences: true)
            if parts.count == 2 {
                return BowlIngredient(
                    amount: Double(parts[0]) ?? 1,
                    unit: "piece",
                    name: String(parts[1])
                )
            }
        }


        return BowlIngredient(amount: 1, unit: "serving", name: text)
    }




    private func gramsFor(amount: Double, unit: String, food: FoodMacros) -> Double {
        let u = unit.lowercased()
        if ["g", "gm", "gram", "grams"].contains(u) { return amount }
        if u == "kg" { return amount * 1000 }
        if ["ml", "milliliter", "milliliters"].contains(u) { return amount }
        if u == "l" { return amount * 1000 }
        if u == "cup" || u == "cups" { return amount * 240 }
        if u == "tbsp" || u == "tablespoon" { return amount * 15 }
        if u == "tsp" || u == "teaspoon" { return amount * 5 }
        if u == "oz" || u == "ounce" { return amount * 28.35 }
        if u == "small"  { return amount * food.defaultServingG * 0.75 }
        if u == "large"  { return amount * food.defaultServingG * 1.25 }
        if u == "medium" { return amount * food.defaultServingG }

        return amount * food.defaultServingG
    }



    func applyFood(_ food: FoodMacros) {
        currentMeal.foodName = food.name
        currentMeal.per100gCalories = food.calories
        currentMeal.per100gProtein  = food.protein
        currentMeal.per100gCarbs    = food.carbs
        currentMeal.per100gFat      = food.fat
        currentMeal.macroSource = "Local DB"
        if currentMeal.unit == "g" && currentMeal.amount == 100 {
            currentMeal.amount = food.defaultServingG
        }
        recalculateFromCurrent()
        referenceHint = String(
            format: "SRC: LOCAL DB · 100 g of %@ ≈ %.0f kcal · P %.1fg · C %.1fg · F %.1fg",
            food.name, food.calories, food.protein, food.carbs, food.fat
        )
        errorMessage = nil
    }


    func recalculateFromCurrent() {
        let grams = gramsForCurrentAmount()
        currentMeal.grams = grams
        let factor = grams / 100.0
        currentMeal.calories = (currentMeal.per100gCalories * factor).rounded()
        currentMeal.protein  = (currentMeal.per100gProtein  * factor * 10).rounded() / 10
        currentMeal.carbs    = (currentMeal.per100gCarbs    * factor * 10).rounded() / 10
        currentMeal.fat      = (currentMeal.per100gFat      * factor * 10).rounded() / 10
    }

    private func gramsForCurrentAmount() -> Double {
        let unit = currentMeal.unit.lowercased()
        let amount = currentMeal.amount

        if ["g", "gm", "gram", "grams"].contains(unit) { return amount }
        if unit == "kg" { return amount * 1000 }
        if ["ml", "milliliter", "milliliters"].contains(unit) { return amount }
        if unit == "l" { return amount * 1000 }
        if unit == "cup" || unit == "cups" { return amount * 240 }
        if unit == "tbsp" || unit == "tablespoon" { return amount * 15 }
        if unit == "tsp" || unit == "teaspoon" { return amount * 5 }
        if unit == "oz" || unit == "ounce" { return amount * 28.35 }

        let food = FoodDatabase.byName(currentMeal.foodName)
        let baseServing = food?.defaultServingG ?? 100
        if unit == "small"  { return amount * baseServing * 0.75 }
        if unit == "large"  { return amount * baseServing * 1.25 }
        if unit == "medium" { return amount * baseServing }
        if unit == "piece" || unit == "pieces" || unit == "serving" || unit == "servings" || unit == "item" {
            return amount * baseServing
        }
        return amount * baseServing
    }



    private func fetchFromOpenFoodFacts(query: String) {
        DispatchQueue.main.async { self.isLoading = true }
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let url = URL(string:
            "https://world.openfoodfacts.org/cgi/search.pl?search_terms=\(encoded)&search_simple=1&action=process&json=1")
        else { return }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self else { return }
            DispatchQueue.main.async { self.isLoading = false }
            if error != nil {
                DispatchQueue.main.async {
                    self.errorMessage = "Couldn't reach the food database. Check your connection, or enter the macros by hand."
                }
                return
            }
            guard let data,
                  let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
                  let products = json["products"] as? [[String: Any]] else {
                DispatchQueue.main.async {
                    self.errorMessage = "No nutrition match found for \"\(query)\"."
                }
                return
            }




            var cals = 0.0, pro = 0.0, carbs = 0.0, fat = 0.0
            var matchedProduct: String? = nil
            for p in products.prefix(15) {
                guard let n = p["nutriments"] as? [String: Any] else { continue }
                let c = Self.doubleValue(from: n["energy-kcal_100g"])
                if c > 0 {
                    cals = c
                    pro = Self.doubleValue(from: n["proteins_100g"])
                    carbs = Self.doubleValue(from: n["carbohydrates_100g"])
                    fat = Self.doubleValue(from: n["fat_100g"])
                    matchedProduct = (p["product_name"] as? String)
                    break
                }
            }

            guard cals > 0 else {
                DispatchQueue.main.async {
                    self.errorMessage = "No reliable macros found for \"\(query)\". Try a simpler name or enter manually."
                }
                return
            }

            DispatchQueue.main.async {
                self.currentMeal.per100gCalories = cals
                self.currentMeal.per100gProtein  = pro
                self.currentMeal.per100gCarbs    = carbs
                self.currentMeal.per100gFat      = fat
                self.currentMeal.macroSource = "OpenFoodFacts"
                self.recalculateFromCurrent()
                let displayName = matchedProduct ?? self.currentMeal.foodName
                self.referenceHint = String(
                    format: "SRC: OPENFOODFACTS · %@ · 100 g ≈ %.0f kcal · P %.1fg · C %.1fg · F %.1fg",
                    displayName, cals, pro, carbs, fat
                )
                self.errorMessage = nil
            }
        }.resume()
    }

    private static func doubleValue(from any: Any?) -> Double {
        if let d = any as? Double { return d }
        if let i = any as? Int { return Double(i) }
        if let s = any as? String { return Double(s) ?? 0 }
        return 0
    }
}
