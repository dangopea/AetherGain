//
//  WorkoutSession.swift
//  AetherGain
//
//  Created by Dhriti on 1/4/2569 BE.
//

import Foundation
import FirebaseFirestore

struct WorkoutSession: Identifiable, Codable {
    @DocumentID var id: String? = UUID().uuidString
    var date: Date = Date()
    var exercises: [Exercise] = []
    var totalXP: Int = 0         // XP awarded for this session
    var notes: String = ""
    
    // Computed: is this a valid completed session?
    var isValidForXP: Bool {
        !exercises.isEmpty && exercises.allSatisfy { $0.sets > 0 && $0.reps > 0 }
    }
    
    init() {}
}
