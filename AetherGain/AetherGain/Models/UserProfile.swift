//
//  UserProfile.swift
//  AetherGain
//
// A data structure for any possible profile information collection
//
//  Created by Dhriti on 1/4/2569 BE.
//

import Foundation
import FirebaseFirestore
// This helps w/ saving or loading; Firestore is responsible for automatic encryption at rest (Google servers) and in transit (HTTPS), and also offline support & real-time sync c


//User profile data specifications, stored in Firestore
struct UserProfile: Identifiable, Codable {
    @DocumentID var id: String? = UUID().uuidString  // Firestore document ID
    
    //Criterion 2
    var name: String = ""
    var age: Int = 18
    var goals: String = ""  //You can add anything like "Lose weight", "Build muscle"
    var preferences: String = ""  // Options could be "Vegetarian", favorite workouts
    var experienceLevel: String = "Beginner"  //Levels: Beginner, Intermediate, Advanced
    var heightCM: Double = 170.0
    var weightKG: Double = 70.0
    
    //Criterion 4
    var xp: Int = 0
    
    init() {} // Default initializer (needed for previews and testing)
    
    // Initializer for creating with values
    init(name: String = "",
         age: Int = 18,
         goals: String = "",
         preferences: String = "",
         experienceLevel: String = "Beginner",
         heightCM: Double = 170.0,
         weightKG: Double = 70.0,
         xp: Int = 0) {
        
        self.name = name
        self.age = age
        self.goals = goals
        self.preferences = preferences
        self.experienceLevel = experienceLevel
        self.heightCM = heightCM
        self.weightKG = weightKG
        self.xp = xp
    }
}
    
    
