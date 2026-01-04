//
//  LogWorkoutView.swift
//  AetherGain
//
//  Created by Dhriti on 1/4/2569 BE.
//

import Foundation
import SwiftUI

struct LogWorkoutView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var workoutVM = WorkoutViewModel()
    
    var body: some View {
        NavigationStack {
            List {
                
                //binding to array elements, add/edit multiple exercises
                ForEach(workoutVM.currentSession.exercises.indices, id: \.self) { index in
                    
                    Section("Exercise \(index + 1)") {
                        TextField("Exercise type (e.g., Bench Press)", text: $workoutVM.currentSession.exercises[index].type)
                        
                        HStack {
                            Stepper("Sets: \(workoutVM.currentSession.exercises[index].sets)", value: $workoutVM.currentSession.exercises[index].sets, in: 1...20)
                        }
                        
                        HStack {
                            Stepper("Reps: \(workoutVM.currentSession.exercises[index].reps)", value: $workoutVM.currentSession.exercises[index].reps, in: 1...50)
                        }
                        
                        HStack {
                            Text("Weight")
                            Spacer()
                            TextField("kg", value: $workoutVM.currentSession.exercises[index].weightKG, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                            Text("kg")
                        }
                        
                        TextField("Notes (optional)", text: $workoutVM.currentSession.exercises[index].notes)
                            .textInputAutocapitalization(.sentences)
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet.sorted(by: >) {  // Delete from highest to lowest to avoid index shifting
                        workoutVM.removeExercise(at: index)
                    }
                } // Bonus professionalism :)
                
                Section {
                    Button("Add Exercise") {
                        workoutVM.addExercise()
                        authVM.userDidInteract()
                    }
                    .frame(maxWidth: .infinity)
                }
                
                Section("Session Summary") {
                    HStack {
                        Text("Estimated XP")
                        Spacer()
                        Text("\(estimatedXP())")
                            .font(.title2.bold())
                            .foregroundColor(.indigo)
                    }
                    
                    if let error = workoutVM.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                    }
                    
                    if workoutVM.isLoading {
                        ProgressView("Saving session...")
                    }
                }
                
                Section {
                    Button("Complete Workout") {
                        workoutVM.completeSession()
                        authVM.userDidInteract()
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                    .padding()
                    .background(workoutVM.currentSession.isValidForXP ? Color.green : Color.gray)
                    .cornerRadius(10)
                    .disabled(!workoutVM.currentSession.isValidForXP || workoutVM.isLoading)
                }
            }
            .navigationTitle("Log Workout")
            .onAppear {
                workoutVM.addExercise()  // Start with one empty exercise
                authVM.userDidInteract()
            }
            .onTapGesture {
                authVM.userDidInteract()
            }
        }
    }
    
    // Live XP preview
    private func estimatedXP() -> Int {
        var xp = 50
        for exercise in workoutVM.currentSession.exercises {
            let volumeBonus = exercise.sets * exercise.reps * Int(exercise.weightKG / 10)
            xp += max(volumeBonus, 5)
        }
        return workoutVM.currentSession.isValidForXP ? xp : 0
    }
}

#Preview {
    LogWorkoutView()
        .environmentObject(AuthViewModel())
}
