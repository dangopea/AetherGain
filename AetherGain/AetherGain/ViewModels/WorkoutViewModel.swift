//
//  WorkoutViewModel.swift
//  AetherGain
//
//  Created by Dhriti on 1/4/2569 BE.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

class WorkoutViewModel: ObservableObject {
    
    @Published var currentSession: WorkoutSession = WorkoutSession()
    @Published var history: [WorkoutSession] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    private var userID: String? {
        Auth.auth().currentUser?.uid
    }
    
    init() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            if let uid = user?.uid {
                self?.loadHistory(for: uid)
            } else {
                self?.history = []
                self?.removeListener()
            }
        }
    }
    
    //Function: Add a new empty exercise to current session
    func addExercise() {
        currentSession.exercises.append(Exercise())
    }
    
    //Function: Remove exercise at a specific index
    func removeExercise(at index: Int) {
        currentSession.exercises.remove(at: index)
    }
    
    //Function: Complete session [calculate XP, save session, add XP to profile]
    func completeSession() {
        guard let uid = userID else {
            errorMessage = "Not logged in"
            return
        }
        
        guard currentSession.isValidForXP else {
            errorMessage = "Add at least one valid exercise (sets & reps > 0)"
            return
        }
        
        isLoading = true
        
        // Calculate XP: base 50 + bonus for volume
        var earnedXP = 50  // Minimum for any valid session
        
        for exercise in currentSession.exercises {
            let volumeBonus = exercise.sets * exercise.reps * Int(exercise.weightKG / 10)
            earnedXP += max(volumeBonus, 5)  // At least 5 per exercise
        }
        
        currentSession.totalXP = earnedXP
        currentSession.date = Date()
        
        
        //Saves session + updates profile XP in one operation
        let batch = db.batch()
        
        //Segment 1. Save the workout session
        let sessionRef = db.collection("users").document(uid).collection("workouts").document()
        do {
            try batch.setData(from: currentSession, forDocument: sessionRef)
        } catch {
            errorMessage = "Encoding error: \(error.localizedDescription)"
            isLoading = false
            return
        }
        
        //Segment 2. Add XP to user's profile (atomic increment)
        let profileRef = db.collection("users").document(uid)
        batch.updateData([
            "xp": FieldValue.increment(Int64(earnedXP))
        ], forDocument: profileRef)
        
        // Commit both operations together
        batch.commit { [weak self] error in
            if let error = error {
                self?.errorMessage = "Save failed: \(error.localizedDescription)"
            } else {
                self?.errorMessage = nil
                // Reset for next session
                self?.currentSession = WorkoutSession()
            }
            self?.isLoading = false
        }
    }
    
    //Function: Load workout history with real-time listener
    private func loadHistory(for uid: String) {
        let collectionRef = db.collection("users").document(uid).collection("workouts")
        
        listener = collectionRef
            .order(by: "date", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    self?.errorMessage = "Load error: \(error.localizedDescription)"
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self?.history = []
                    return
                }
                
                self?.history = documents.compactMap { try? $0.data(as: WorkoutSession.self) }
            }
    }
    
    //Function: Remove the listener to avoid memory leaks
    private func removeListener() {
        listener?.remove()
        listener = nil
    }
    
    deinit {
        removeListener()
    }
}
