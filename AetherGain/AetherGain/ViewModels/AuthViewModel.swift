//
//  AuthViewModel.swift
//  AetherGain
//
// Purpose: Manage user authentication (signup, login, and 30-minute inactivity logout)
//
//  Created by Dhriti on 1/4/2569 BE.
//

import Foundation

import FirebaseAuth //For FireBase login/signup functions
import Combine // For publishing changes by SwiftUI internally
import SwiftUI // For @Published and ObservableObject


//Observable objects allow views to react automatically to changes
class AuthViewModel: ObservableObject {
    @Published var isSignedIn = false // True if user is signed in, false if not.
    @Published var showTimeoutAlert = false //Triggers "Session expired" notificatoin
    
    private var inactivityTimer: Timer? //Timer to count down 30 minutes of inactivity
    private let inactivityTimeout: TimeInterval = 30 * 60 // Duration of inactivity | 1800 seconds is 30 minutes
    
    //Initialization of the view model + setup of FireBase auth state listener
    init() {
        isSignedIn = Auth.auth().currentUser != nil //Check if view model is already created/if there's a logged-in user already
        
        Auth.auth().addStateDidChangeListener { [weak self] auth, user in // Check for change in state
            guard let self = self else { return }
            
            let wasSignedIn = self.isSignedIn
            self.isSignedIn = user != nil
            
            if self.isSignedIn {
                self.startInactivityTimer() // Once user is signed in, start the timer
            }
            
            else if wasSignedIn {
                self.stopInactivityTimer() //Stop the timer once the user is signed out
            }
        }
    }
    
    //3 main functions: [SignUp, SignIn, Signout] for authentication
    //Function: Create a new account w/ email + pwd. Completion handler used to handle inconveniences
    func signUp(email: String, password: String, completion: @escaping (Error?) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { _, error in
            if let error = error {
                completion(error)
                return
            }
            self.isSignedIn = true
            self.startInactivityTimer()
            completion(nil)
        }
    }
    
    //Function: Log into your account w/ existing email + pwd.
    func signIn(email: String, password: String, completion: @escaping (Error?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { _, error in
            if let error = error {
                completion(error)
                return
            }
            self.isSignedIn = true
            self.startInactivityTimer()
            completion(nil)
        }
    }
    
    //Function: Sign the user out entirely.
    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("Sign out error: \(error.localizedDescription)")
        }
        isSignedIn = false
        stopInactivityTimer()
    }
    
    
    //3 functions handling inactivity: [startInactivityTimer, stopInactivityTimer and userDidCheck]
    //Function: Start/reset the 30-minute inactivity timer
    private func startInactivityTimer() {
        stopInactivityTimer() // Stop any timer that's already running
        
        inactivityTimer = Timer.scheduledTimer(withTimeInterval: inactivityTimeout, repeats: false) { [weak self] _ in
            self?.signOut()
            self?.showTimeoutAlert = true
        }
    }
    
    //Function: Stop any inactivity timer entirely
    private func stopInactivityTimer() {
        inactivityTimer?.invalidate()
        inactivityTimer = nil
    }
    
    //Function: Check for user interaction (any tap/appear, etc) and reset the timer
    func userDidInteract() {
        if isSignedIn {
            startInactivityTimer()
        }
    }
}
