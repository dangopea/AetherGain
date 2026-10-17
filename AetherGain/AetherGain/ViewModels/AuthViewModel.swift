








import Foundation

import FirebaseAuth
import Combine
import SwiftUI



class AuthViewModel: ObservableObject {
    @Published var isSignedIn = false
    @Published var showTimeoutAlert = false

    private var inactivityTimer: Timer?
    private let inactivityTimeout: TimeInterval = 30*60


    init() {
        isSignedIn = Auth.auth().currentUser != nil

        Auth.auth().addStateDidChangeListener { [weak self] auth, user in
            guard let self = self else { return }

            let wasSignedIn = self.isSignedIn
            self.isSignedIn = user != nil

            if self.isSignedIn {
                self.startInactivityTimer()
            }

            else if wasSignedIn {
                self.stopInactivityTimer()
            }
        }
    }



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


    func sendPasswordReset(email: String, completion: @escaping (Error?) -> Void) {
        let trimmed = email.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            let err = NSError(domain: "AGAuth", code: 400,
                              userInfo: [NSLocalizedDescriptionKey: "Enter your email first."])
            completion(err); return
        }
        Auth.auth().sendPasswordReset(withEmail: trimmed) { error in
            completion(error)
        }
    }


    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("Sign out error: \(error.localizedDescription)")
        }
        isSignedIn = false
        stopInactivityTimer()
    }




    private func startInactivityTimer() {
        stopInactivityTimer()

        inactivityTimer = Timer.scheduledTimer(withTimeInterval: inactivityTimeout, repeats: false) { [weak self] _ in
            guard let self else { return }


            self.signOut()
            DispatchQueue.main.async { self.showTimeoutAlert = true }
        }
    }


    private func stopInactivityTimer() {
        inactivityTimer?.invalidate()
        inactivityTimer = nil
    }


    func userDidInteract() {
        if isSignedIn {
            startInactivityTimer()
        }
    }
}
