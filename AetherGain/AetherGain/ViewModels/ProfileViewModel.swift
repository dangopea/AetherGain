//
//  ProfileViewModel.swift
//  AetherGain
//
/* (1) Load the user’s profile from Firestore after login,
   (2) Save changes when they edit,
   (3) Create a new empty profile if it’s their first time,
   (4) Be observable so the UI updates automatically */
//
//  Created by Dhriti on 1/4/2569 BE.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine


// Manages loading, saving, and observing a user's profile in Firestore
class ProfileViewModel: ObservableObject {
    
    @Published var profile: UserProfile = UserProfile() // UI will update automatically when this changes
    
    // Published states for feedback (UI)
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    
    // UID of current user from Firebase Auth
    private var userID: String? {
        Auth.auth().currentUser?.uid
    }
    
    init() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in // Start listening for auth changes + load profile when user logs in
            
            if let uid = user?.uid {
                self?.loadProfile(for: uid)
            } else {
                // User logged out – reset profile
                self?.profile = UserProfile()
                self?.removeListener()
            }
        }
    }
    
    // Function: Load the profile from Firestore, or create an empty one if it doesn't exist.
    func loadProfile(for uid: String) {
        isLoading = true
        
        let docRef = db.collection("users").document(uid)
        
        listener = docRef.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                self.errorMessage = "Load error: \(error.localizedDescription)"
                self.isLoading = false
                return
            }
            
            // Two very different situations were handled by one branch here, and
            // conflating them could destroy data. `try?` turns a decoding failure
            // into the same `nil` as a missing document, so a single unreadable
            // field — an enum whose stored text no longer matches a case, a
            // number written as a string — made the app conclude that the user
            // had no profile and overwrite the real one with blank defaults,
            // taking the XP and the leaderboard opt-in with it. Absence is now
            // asked of the snapshot itself, and a decoding failure is reported
            // rather than acted upon.
            guard let snapshot else { self.isLoading = false; return }

            if snapshot.exists {
                do {
                    self.profile = try snapshot.data(as: UserProfile.self)
                } catch {
                    self.errorMessage = "Your profile could not be read. Nothing was changed."
                    print("[Profile] decode failed, document left untouched: \(error)")
                }
            } else {
                self.profile = UserProfile()
                self.saveProfile()  // First sign-in: create the document.
            }
            
            self.isLoading = false
        }
    }
        
    //Function: Save current profile to Firestore
    func saveProfile() {
        guard let uid = userID else {
            errorMessage = "Not logged in"
            return
        }
        
        isLoading = true
        stopSavingIndicatorIfServerIsSlow()
        
        let docRef = db.collection("users").document(uid)
        
        do {
            // merge: true leaves fields this model does not know about in place.
            // Without it every save rewrites the whole document, so a field
            // another part of the app owns — the XP that completeSession raises
            // with an atomic increment — would be silently removed by someone
            // merely editing their name.
            try docRef.setData(from: profile, merge: true) { [weak self] error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.errorMessage = "Save error: \(error.localizedDescription)"
                    } else {
                        self?.errorMessage = nil
                    }
                    self?.isLoading = false
                }
            }
        } catch {
            errorMessage = "Encoding error: \(error.localizedDescription)"
            isLoading = false
        }
    }
        
    //Function: Clean up listener when no longer needed, ensure that there's no memory leaks
    private func removeListener() {
        listener?.remove()
        listener = nil
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
            authStateHandle = nil
        }
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
