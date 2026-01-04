//
//  LoginView.swift
//  AetherGain
//
//  Created by Dhriti on 1/4/2569 BE.
//

import SwiftUI

struct LoginView: View {
    @StateObject private var authVM = AuthViewModel() // Creates AuthViewModel object for this screen
    
    //Text fields + UI local state
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isSignupMode: Bool = false  // false = Login, true = Sign Up
    @State private var errorMessage: String? = nil
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                
                // App Title
                Text("AetherGain")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.indigo)
                
                // Email Field
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .onTapGesture { authVM.userDidInteract() }
                
                // Password Field
                SecureField("Password", text: $password)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .onTapGesture { authVM.userDidInteract() }
                
                // Error Message (if any)
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }
                
                // Main Button (Sign Up or Log In)
                Button(isSignupMode ? "Create Account" : "Log In") {
                    errorMessage = nil
                    
                    if isSignupMode {
                        authVM.signUp(email: email, password: password) { error in
                            if let error = error as NSError? {
                                // This prints the REAL detailed error to Xcode console
                                print("🔴 Signup Error: \(error.localizedDescription)")
                                print("🔴 Error Code: \(error.code)")
                                print("🔴 Full Error: \(error)")
                                
                                errorMessage = error.localizedDescription
                            }
                        }
                    } else {
                        authVM.signIn(email: email, password: password) { error in
                            if let error = error as NSError? {
                                print("🔴 Login Error: \(error.localizedDescription)")
                                print("🔴 Error Code: \(error.code)")
                                print("🔴 Full Error: \(error)")
                                
                                errorMessage = error.localizedDescription
                            }
                        }
                    }
                    authVM.userDidInteract()
                }
                .font(.title3.bold())
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.indigo)
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Toggle between Login and Sign Up
                Button(isSignupMode ? "Already have an account? Log In" : "Don't have an account? Sign Up") {
                    isSignupMode.toggle()
                    errorMessage = nil
                }
                .foregroundColor(.indigo)
                
                Spacer()
            }
            .padding()
            .navigationTitle(isSignupMode ? "Sign Up" : "Log In")
            .navigationBarTitleDisplayMode(.large)
            
            // Alert when session times out
            .alert("Session Expired", isPresented: $authVM.showTimeoutAlert) {
                Button("OK") { }
            } message: {
                Text("You have been logged out due to 30 minutes of inactivity. Please log in again.")
            }
            
            // Reset timer whenever user interacts with the screen
            .onTapGesture {
                authVM.userDidInteract()
            }
            .onAppear {
                authVM.userDidInteract()
            }
        }
        // Share the same AuthViewModel instance with child views
        .environmentObject(authVM)
    }
}

#Preview {
    LoginView()
}
