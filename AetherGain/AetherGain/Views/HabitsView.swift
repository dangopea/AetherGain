//
//  HabitsView.swift
//  AetherGain
//
//  Created by Dhriti on 3/13/2569 BE.
//

import SwiftUI

struct HabitsView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var habitsVM = HabitsViewModel()
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Daily Water") {
                    Slider(value: $habitsVM.profile.dailyWaterML, in: 0...4000, step: 250) {
                        Text("Water: \(Int(habitsVM.profile.dailyWaterML)) ml")
                    }
                    Text("Target: 2000–3000 ml")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section("Sleep Last Night") {
                    Stepper("Hours: \(habitsVM.profile.sleepHours, specifier: "%.1f")", value: $habitsVM.profile.sleepHours, in: 0...12, step: 0.5)
                }
                
                Section("Custom Habit") {
                    TextField("Habit name", text: $habitsVM.profile.customHabitName)
                    Toggle("Completed today", isOn: $habitsVM.profile.customHabitCompletedToday)
                }
                
                Section("Streak") {
                    HStack {
                        Text("Current Streak")
                        Spacer()
                        Text("\(habitsVM.profile.streakDays) days 🔥")
                            .font(.title3.bold())
                            .foregroundColor(.orange)
                    }
                }
                
                Section("Reminders") {
                    Toggle("Daily reminders at 8 PM", isOn: $habitsVM.profile.remindersEnabled)
                        .onChange(of: habitsVM.profile.remindersEnabled) { newValue in
                            habitsVM.toggleReminders(enabled: newValue)
                        }
                }
                
                if habitsVM.isLoading {
                    ProgressView("Saving...")
                }
                
                Button("Save Habits") {
                    habitsVM.saveHabits()
                    authVM.userDidInteract()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.indigo)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .navigationTitle("Daily Habits")
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
    HabitsView()
        .environmentObject(AuthViewModel())
}
