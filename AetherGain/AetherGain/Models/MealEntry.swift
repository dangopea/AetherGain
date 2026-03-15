//
//  MealEntry.swift
//  AetherGain
//
//  Created by Dhriti on 3/8/2569 BE.
//

import Foundation
import FirebaseFirestore

struct MealEntry: Identifiable, Codable {
    
    @DocumentID var id: String? = UUID().uuidString
    
    var date: Date = Date()
    var foodName: String = ""
    var calories: Double = 0.0
    var protein: Double = 0.0
    var carbs: Double = 0.0
    var fat: Double = 0.0
    var notes: String = ""
    var photoURL: String? = nil //So that you can save to storage
    
    init() {}
    
}
