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
        currentSession.exercises.append(ExerciseTemplate.configuredExercise(named: "Bench Press"))
    }
    
    func addCustomExercise(named name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            errorMessage = "Enter an exercise name"
            return
        }
        
        currentSession.exercises.append(ExerciseTemplate.configuredExercise(named: trimmedName))
        errorMessage = nil
    }
    
    func applyTemplate(_ template: ExerciseTemplate, at index: Int) {
        guard currentSession.exercises.indices.contains(index) else { return }
        currentSession.exercises[index] = ExerciseTemplate.configuredExercise(named: template.name)
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
        stopSavingIndicatorIfServerIsSlow()
        
        let earnedXP = GameEngine.workoutXP(for: currentSession)
        currentSession.totalXP = earnedXP
        // Preserve the date the user picked (or default to now if unset for
        // some reason — WorkoutSession()'s default is Date()).
        if currentSession.date > Date() {
            // Sanity-clamp: never allow future-dated workouts.
            currentSession.date = Date()
        }
        
        
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
            DispatchQueue.main.async {
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
    }
    
    /// Update an existing session (edit flow). Adjusts the profile XP by the
    /// delta between the new computed XP and the previously-stored XP.
    /// `completion` fires on the main queue with an error or nil.
    func updateSession(_ edited: WorkoutSession, completion: @escaping (Error?) -> Void) {
        guard let uid = userID, let sessionID = edited.id else {
            completion(NSError(domain: "AGWorkout", code: 400,
                               userInfo: [NSLocalizedDescriptionKey: "Missing session id."]))
            return
        }
        guard edited.isValidForXP else {
            completion(NSError(domain: "AGWorkout", code: 422,
                               userInfo: [NSLocalizedDescriptionKey: "Need at least one valid exercise."]))
            return
        }

        var updated = edited
        let previousXP = edited.totalXP
        let newXP = GameEngine.workoutXP(for: updated)
        updated.totalXP = newXP
        let xpDelta = newXP - previousXP

        isLoading = true
        let batch = db.batch()
        let sessionRef = db.collection("users").document(uid).collection("workouts").document(sessionID)
        do {
            try batch.setData(from: updated, forDocument: sessionRef, merge: false)
        } catch {
            isLoading = false
            completion(error); return
        }
        if xpDelta != 0 {
            let profileRef = db.collection("users").document(uid)
            batch.updateData(["xp": FieldValue.increment(Int64(xpDelta))], forDocument: profileRef)
        }
        batch.commit { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false
                completion(error)
            }
        }
    }

    /// Delete a session and refund its XP from the profile.
    func deleteSession(_ session: WorkoutSession) {
        guard let uid = userID, let sessionID = session.id else { return }
        let batch = db.batch()
        let sessionRef = db.collection("users").document(uid).collection("workouts").document(sessionID)
        batch.deleteDocument(sessionRef)

        // Refund XP so leaderboard/level don't stay inflated.
        let profileRef = db.collection("users").document(uid)
        batch.updateData([
            "xp": FieldValue.increment(Int64(-session.totalXP))
        ], forDocument: profileRef)

        batch.commit { [weak self] error in
            DispatchQueue.main.async {
                if let error {
                    self?.errorMessage = "Delete failed: \(error.localizedDescription)"
                }
            }
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
    
    private func stopSavingIndicatorIfServerIsSlow() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self, self.isLoading else { return }
            self.isLoading = false
        }
    }
    
    deinit {
        removeListener()
    }
}
