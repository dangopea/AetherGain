












import Foundation
import UIKit

extension MealViewModel {



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
                case .failure(_):
                    self.errorMessage = "That photo couldn't be analysed. Take another one in better light, or enter the food by hand."
                case .success(let regions):
                    let recognised = regions.filter { $0.matchedFood != nil }
                    self.regionCandidates = regions
                    if recognised.isEmpty {
                        self.errorMessage = "No food on this plate matched the local database. "
                            + "Enter the items by name, or use bowl mode for a mixed dish."
                    } else if recognised.count == 1 {

                        if let name = recognised[0].matchedFood,
                           let food = FoodDatabase.byName(name) {
                            self.applyFood(food)
                        }
                    }

                }
            }
        }
    }


    func selectRegionCandidate(_ candidate: RegionCandidate) {
        if let name = candidate.matchedFood, let food = FoodDatabase.byName(name) {
            applyFood(food)
        } else {
            currentMeal.foodName = candidate.label.capitalized
            calculateNutritionForCurrentMeal()
        }
    }
}
