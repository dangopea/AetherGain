//
//  ProfileView.swift
//  AetherGain
//
//  Created by Dhriti on 1/4/2569 BE.
//

import Foundation
import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authVM: AuthViewModel // Make sure that the 30 minute inactivity timer is working
    @StateObject private var profileVM = ProfileViewModel() // updates when data loads/saves
    
    var body: some View {
        NavigationStack {
            Form {
                
                //Section 1: Personal Information
                Section("Personal Information") {
                    TextField("Name", text: $profileVM.profile.name)
                    
                    Stepper("Age: \(profileVM.profile.age)", value: $profileVM.profile.age, in: 10...100)
                    
                    TextField("Fitness Goals", text: $profileVM.profile.goals)
                        .textInputAutocapitalization(.sentences)
                    
                    TextField("Preferences (e.g., diet, favorite workouts)", text: $profileVM.profile.preferences)
                        .textInputAutocapitalization(.sentences)
                }
                
                //Section 2: Experience & Physique
                Section("Experience & Physique") {
                    Picker("Experience Level", selection: $profileVM.profile.experienceLevel) {
                        Text("Beginner").tag("Beginner")
                        Text("Intermediate").tag("Intermediate")
                        Text("Advanced").tag("Advanced")
                    }
                    .pickerStyle(.segmented)
                    
                    HStack {
                        Text("Height")
                        Spacer()
                        TextField("Height (cm)", value: $profileVM.profile.heightCM, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        Text("cm")
                    }
                    
                    HStack {
                        Text("Weight")
                        Spacer()
                        TextField("Weight (kg)", value: $profileVM.profile.weightKG, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        Text("kg")
                    }
                }
                
                if profileVM.isLoading {
                    Section {
                        HStack {
                            Spacer()
                            ProgressView("Saving...")
                            Spacer()
                        }
                    }
                }
                
                if let error = profileVM.errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
                
                //Section 3: Save Profile
                Section {
                    Button("Save Profile") {
                        profileVM.saveProfile()
                        authVM.userDidInteract()  // Reset inactivity timer
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.indigo)
                    .cornerRadius(10)
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("My Profile")
            .onAppear {
                authVM.userDidInteract()
            }
            .onTapGesture {
                authVM.userDidInteract()
            }
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthViewModel())
}
