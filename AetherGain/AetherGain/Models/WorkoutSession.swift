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
        !exercises.isEmpty && exercises.allSatisfy { exercise in
            guard !exercise.type.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return false
            }
            
            switch exercise.category ?? .strength {
            case .strength:
                return exercise.sets > 0 && exercise.reps > 0
            case .cardio:
                return (exercise.durationMinutes ?? 0) > 0 || (exercise.distanceKM ?? 0) > 0
            case .mobility:
                return (exercise.durationMinutes ?? 0) > 0
            }
        }
    }
    
    init() {}
}
