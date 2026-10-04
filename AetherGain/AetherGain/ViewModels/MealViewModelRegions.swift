//
//  MealViewModelRegions.swift
//  AetherGain
//
//  Multi-region photo analysis, for plates that hold more than one dish.
//
//  `analyzeMealPhoto` answers "which dish is this?" and fills in one meal.
//  This answers "which dishes are on this plate?" and fills `regionCandidates`,
//  which the view lists so the user can log each one. See
//  FoodClassifierRegions.swift for why this uses saliency regions rather than
//  an object-detection model.
//

import Foundation
import UIKit

extension MealViewModel {

    /// Scans the photo for separate foods. Results land in `regionCandidates`;
    /// the single-dish `candidates` list is left untouched.
    func analyzeMealPhotoByRegion(_ image: UIImage) {
        DispatchQueue.main.async {
            self.isAnalyzingPhoto = true
            self.errorMessage = nil
            self.regionCandidates = []
        }

        FoodClassifier.classifyRegions(image: image) { [weak self] result in
            guard let self else { return }
            DispatchQueue.main.async {
                self.isAnalyzingPhoto = false
                switch result {
                case .failure(let error):
                    self.errorMessage = "Photo analysis failed: \(error.localizedDescription)"
                case .success(let regions):
                    let recognised = regions.filter { $0.matchedFood != nil }
                    self.regionCandidates = regions
                    if recognised.isEmpty {
                        self.errorMessage = "No food on this plate matched the local database. "
                            + "Enter the items by name, or use bowl mode for a mixed dish."
                    } else if recognised.count == 1 {
                        // A single find behaves exactly like the old flow.
                        if let name = recognised[0].matchedFood,
                           let food = FoodDatabase.byName(name) {
                            self.applyFood(food)
                        }
                    }
                    // Two or more: the view lists them and the user logs each.
                }
            }
        }
    }

    /// Logs one of the foods found on the plate.
    func selectRegionCandidate(_ candidate: RegionCandidate) {
        if let name = candidate.matchedFood, let food = FoodDatabase.byName(name) {
            applyFood(food)
        } else {
            currentMeal.foodName = candidate.label.capitalized
            calculateNutritionForCurrentMeal()
        }
    }
}
