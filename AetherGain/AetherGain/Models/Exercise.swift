//
//  Exercise.swift
//  AetherGain
//
//  Created by Dhriti on 1/4/2569 BE.
//

import Foundation
import FirebaseFirestore

struct Exercise: Identifiable, Codable {
    @DocumentID var id: String? = UUID().uuidString
    
    var type: String = "" //You can add stuff in like "Bench Press", "Running"
    var sets: Int = 3
    var reps: Int = 10
    var weightKG: Double = 0.0 // 0 if bodyweight/cardio
    var notes: String = ""
    
    init() {}
    
    init(type: String = "", sets: Int = 3, reps: Int = 10, weightKG: Double = 0.0, notes: String = "") {
        self.type = type
        self.sets = sets
        self.reps = reps
        self.weightKG = weightKG
        self.notes = notes
    }
}
