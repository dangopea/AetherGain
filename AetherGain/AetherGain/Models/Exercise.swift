//
//  Exercise.swift
//  AetherGain
//
//  Created by Dhriti on 1/4/2569 BE.
//

import Foundation
import FirebaseFirestore

enum ExerciseCategory: String, Codable, CaseIterable, Identifiable {
    case strength
    case cardio
    case mobility
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .strength:
            return "Strength"
        case .cardio:
            return "Cardio"
        case .mobility:
            return "Mobility"
        }
    }
}

struct Exercise: Identifiable, Codable {
    // NOTE: This used to be `@DocumentID var id: String?` but @DocumentID
    // only works on top-level Firestore documents. When an Exercise sits
    // inside `WorkoutSession.exercises`, @DocumentID silently drops the id
    // during encode and decodes back to nil, which makes SwiftUI's ForEach
    // treat every exercise as the same identity and render duplicates.
    // Plain String default UUID keeps identity stable through Codable.
    var id: String = UUID().uuidString

    var type: String = "" //You can add stuff in like "Bench Press", "Running"
    var category: ExerciseCategory? = .strength
    var sets: Int = 3
    var reps: Int = 10
    var weightKG: Double = 0.0 // 0 if bodyweight/cardio
    var distanceKM: Double? = nil
    var durationMinutes: Double? = nil
    var inclinePercent: Double? = nil
    var notes: String = ""
    
    init() {}
    
    init(
        type: String = "",
        category: ExerciseCategory = .strength,
        sets: Int = 3,
        reps: Int = 10,
        weightKG: Double = 0.0,
        distanceKM: Double? = nil,
        durationMinutes: Double? = nil,
        inclinePercent: Double? = nil,
        notes: String = ""
    ) {
        self.type = type
        self.category = category
        self.sets = sets
        self.reps = reps
        self.weightKG = weightKG
        self.distanceKM = distanceKM
        self.durationMinutes = durationMinutes
        self.inclinePercent = inclinePercent
        self.notes = notes
    }
}

struct ExerciseTemplate: Identifiable, Hashable {
    let name: String
    let category: ExerciseCategory
    
    var id: String { name }
    
    static let catalog: [ExerciseTemplate] = [
        ExerciseTemplate(name: "Bench Press", category: .strength),
        ExerciseTemplate(name: "Squat", category: .strength),
        ExerciseTemplate(name: "Deadlift", category: .strength),
        ExerciseTemplate(name: "Shoulder Press", category: .strength),
        ExerciseTemplate(name: "Pull Up", category: .strength),
        ExerciseTemplate(name: "Push Up", category: .strength),
        ExerciseTemplate(name: "Lat Pulldown", category: .strength),
        ExerciseTemplate(name: "Bicep Curl", category: .strength),
        ExerciseTemplate(name: "Tricep Pushdown", category: .strength),
        ExerciseTemplate(name: "Leg Press", category: .strength),
        ExerciseTemplate(name: "Running", category: .cardio),
        ExerciseTemplate(name: "Cycling", category: .cardio),
        ExerciseTemplate(name: "Swimming", category: .cardio),
        ExerciseTemplate(name: "Rowing", category: .cardio),
        ExerciseTemplate(name: "Treadmill Walk", category: .cardio),
        ExerciseTemplate(name: "Elliptical", category: .cardio),
        ExerciseTemplate(name: "Yoga", category: .mobility),
        ExerciseTemplate(name: "Stretching", category: .mobility),
        ExerciseTemplate(name: "Pilates", category: .mobility)
    ]
    
    static func template(named name: String) -> ExerciseTemplate? {
        catalog.first { $0.name.caseInsensitiveCompare(name) == .orderedSame }
    }
    
    static func inferredCategory(for name: String) -> ExerciseCategory {
        if let template = template(named: name) {
            return template.category
        }
        
        let lowercasedName = name.lowercased()
        let cardioKeywords = ["run", "jog", "cycle", "bike", "swim", "row", "walk", "treadmill", "elliptical", "cardio"]
        let mobilityKeywords = ["yoga", "stretch", "mobility", "pilates", "warm up", "cool down"]
        
        if cardioKeywords.contains(where: lowercasedName.contains) {
            return .cardio
        }
        
        if mobilityKeywords.contains(where: lowercasedName.contains) {
            return .mobility
        }
        
        return .strength
    }
    
    static func configuredExercise(named name: String) -> Exercise {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let category = inferredCategory(for: trimmedName)
        
        switch category {
        case .strength:
            return Exercise(type: trimmedName, category: category, sets: 3, reps: 10, weightKG: 0)
        case .cardio:
            return Exercise(type: trimmedName, category: category, sets: 1, reps: 1, distanceKM: 1, durationMinutes: 10, inclinePercent: 0)
        case .mobility:
            return Exercise(type: trimmedName, category: category, sets: 1, reps: 1, durationMinutes: 10)
        }
    }
}
