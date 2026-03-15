//
//  MealViewModel.swift
//  AetherGain
//
//  Created by Dhriti on 3/8/2569 BE.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine
import FirebaseStorage

import Vision
import UIKit

class MealViewModel: ObservableObject {
    @Published var meals: [MealEntry] = []
    @Published var currentMeal: MealEntry = MealEntry()
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    private var userID: String? { Auth.auth().currentUser?.uid }
    
    init() {
        loadMeals()
    }
    
    func loadMeals() {
        guard let uid = userID else { return }
        let ref = db.collection("users").document(uid).collection("meals")
            .order(by: "date", descending: true)
        
        listener = ref.addSnapshotListener { [weak self] snapshot, error in
            guard let self else { return }
            if let error {
                self.errorMessage = error.localizedDescription
                return
            }
            self.meals = snapshot?.documents.compactMap { try? $0.data(as: MealEntry.self) } ?? []
        }
    }
    
    func saveMeal() {
        guard let uid = userID else {
            errorMessage = "Not logged in"
            return
        }
        
        guard !currentMeal.foodName.isEmpty else {
            errorMessage = "Enter food name or detect from photo"
            return
        }
        
        isLoading = true
        
        let ref = db.collection("users").document(uid).collection("meals").document()
        
        do {
            try ref.setData(from: currentMeal) { error in
                if let error {
                    self.errorMessage = error.localizedDescription
                } else {
                    self.errorMessage = nil
                    self.currentMeal = MealEntry()  // Reset
                }
                self.isLoading = false
            }
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    // MARK: - Photo → Food Detection (Vision + simple classifier)
    func analyzeMealPhoto(_ image: UIImage, completion: @escaping (Bool) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(false)
            return
        }
        
        let request = VNClassifyImageRequest()
        
        let handler = VNImageRequestHandler(cgImage: cgImage)
        
        do {
            try handler.perform([request])
            
            if let observations = request.results as? [VNClassificationObservation],
               let topResult = observations.first {
                // Simple mapping – in real app use a trained model
                let detectedFood = topResult.identifier.lowercased()
                currentMeal.foodName = detectedFood.capitalized
                
                // Dummy macro estimation – replace with real model later
                currentMeal.calories = 350
                currentMeal.protein = 25
                currentMeal.carbs = 40
                currentMeal.fat = 12
                
                completion(true)
            } else {
                completion(false)
            }
        } catch {
            errorMessage = "Analysis failed: \(error.localizedDescription)"
            completion(false)
        }
    }
}
