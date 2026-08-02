//
//  MealViewModel.swift
//  AetherGain
//
//  Meal state + macro calculation.
//
//  Macro calculation methodology (transparent for the IA):
//  1.  Reference macros are stored per 100 g of the food (FoodDatabase or OpenFoodFacts).
//  2.  The user enters an amount + unit. We convert it to grams:
//        - "g", "gram", "grams"        → grams as entered
//        - "kg"                         → × 1000
//        - "ml"                         → × 1 (assume water-density for beverages)
//        - "cup"                        → × 240
//        - "tbsp"                       → × 15
//        - "tsp"                        → × 5
//        - "oz"                         → × 28.35
//        - "piece" / "serving"          → × food.defaultServingG
//        - "small"/"medium"/"large"     → 0.75× / 1.0× / 1.25× default serving
//  3.  Final macro = per100g × grams / 100.
//  4.  We surface a "For reference: 100 g of X gives you Y kcal, P g protein…"
//      hint under the input so the user can sanity-check.
//

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
    @Published var referenceHint: String? = nil

    /// If we're editing an existing meal, its Firestore id sits here so save()
    /// updates rather than appends.
    @Published var editingMealID: String? = nil

    private var db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private var userID: String? { Auth.auth().currentUser?.uid }

    init() {
        resetCurrentMeal()
        loadMeals()
    }

    /// Populate the log form with an existing meal for editing.
    func editMeal(_ meal: MealEntry) {
        currentMeal = meal
        editingMealID = meal.id
        candidates = []
        referenceHint = nil
        errorMessage = nil
    }

    // MARK: - Firestore

    func loadMeals() {
        guard let uid = userID else { return }
        listener?.remove()
        listener = db.collection("users").document(uid).collection("meals")
            .order(by: "date", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                if let error {
                    DispatchQueue.main.async { self.errorMessage = error.localizedDescription }
                    return
                }
                let meals = snapshot?.documents.compactMap { try? $0.data(as: MealEntry.self) } ?? []
                DispatchQueue.main.async { self.meals = meals }
            }
    }

    func saveMeal() {
        guard let uid = userID else {
            DispatchQueue.main.async { self.errorMessage = "Not logged in" }
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
                    if let error {
                        self.errorMessage = error.localizedDescription
                    } else {
                        self.errorMessage = nil
                        self.resetCurrentMeal()
                    }
                    self.isLoading = false
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
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

    // MARK: - Photo analysis
    //
    // Uses Apple's on-device Vision image classifier (VNClassifyImageRequest).
    // It returns hundreds of labels with confidences. We keep the top 12 above
    // a very low threshold (0.02) so we always have *something* to show, and
    // let the user tap any chip. Chips backed by our FoodDatabase are tinted
    // teal (macros auto-apply on tap). Raw ones are grey (tap will try
    // OpenFoodFacts).

    func analyzeMealPhoto(_ image: UIImage) {
        guard let cgImage = image.cgImage else {
            errorMessage = "Couldn't read this image (format not supported)."
            return
        }
        DispatchQueue.main.async {
            self.isAnalyzingPhoto = true
            self.errorMessage = nil
            self.candidates = []
        }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            let request = VNClassifyImageRequest()
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
                let observations = request.results ?? []
                // Keep top 12 at low threshold. Sort by confidence desc.
                let sorted = observations
                    .filter { $0.confidence >= 0.02 }
                    .sorted { $0.confidence > $1.confidence }
                    .prefix(12)

                let candidates: [FoodCandidate] = sorted.map { obs in
                    let matched = FoodDatabase.bestMatch(fromLabels: [(obs.identifier, obs.confidence)])?.name
                    return FoodCandidate(rawLabel: obs.identifier,
                                         confidence: obs.confidence,
                                         matched: matched)
                }
                let bestFood = FoodDatabase.bestMatch(
                    fromLabels: sorted.map { ($0.identifier, $0.confidence) }
                )

                DispatchQueue.main.async {
                    self.candidates = candidates
                    self.isAnalyzingPhoto = false
                    if let food = bestFood {
                        self.applyFood(food)
                    } else if let top = sorted.first {
                        self.currentMeal.foodName = top.identifier.capitalized
                        self.errorMessage = "Detected \"\(top.identifier)\". Tap a chip below or edit the name, then tap Calculate."
                    } else {
                        self.errorMessage = "Couldn't classify this photo. Enter a food name manually."
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.isAnalyzingPhoto = false
                    self.errorMessage = "Photo analysis failed: \(error.localizedDescription)"
                }
            }
        }
    }

    func selectCandidate(_ candidate: FoodCandidate) {
        if let name = candidate.matched, let food = FoodDatabase.byName(name) {
            applyFood(food)
        } else {
            currentMeal.foodName = candidate.rawLabel.capitalized
            calculateNutritionForCurrentMeal()
        }
    }

    // MARK: - Macro calculation

    func calculateNutritionForCurrentMeal() {
        let name = currentMeal.foodName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else {
            errorMessage = "Enter a food name first."
            return
        }
        if let match = FoodDatabase.byName(name) {
            applyFood(match)
            return
        }
        fetchFromOpenFoodFacts(query: name)
    }

    private func applyFood(_ food: FoodMacros) {
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

    /// Public: called from the view when amount/unit changes.
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

    // MARK: - OpenFoodFacts fallback

    private func fetchFromOpenFoodFacts(query: String) {
        DispatchQueue.main.async { self.isLoading = true }
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let url = URL(string:
            "https://world.openfoodfacts.org/cgi/search.pl?search_terms=\(encoded)&search_simple=1&action=process&json=1")
        else { return }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self else { return }
            DispatchQueue.main.async { self.isLoading = false }
            if let error {
                DispatchQueue.main.async {
                    self.errorMessage = "Nutrition lookup failed: \(error.localizedDescription)"
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

            // OpenFoodFacts returns products in arbitrary order; some have empty
            // nutriments blocks. Walk the list and pick the first product with
            // usable per-100g energy.
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

    deinit { listener?.remove() }
}
