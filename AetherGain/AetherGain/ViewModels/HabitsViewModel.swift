//
//  HabitsViewModel.swift
//  AetherGain
//
//  Created by Dhriti on 3/13/2569 BE.
//

import Foundation
import FirebaseFirestore
import UserNotifications
import Combine
import FirebaseAuth


class HabitsViewModel: ObservableObject {
    @Published var profile: UserProfile = UserProfile()
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    private var userID: String? { Auth.auth().currentUser?.uid }
    
    init() {
        loadProfile()
    }
    
    func loadProfile() {
        guard let uid = userID else { return }
        let ref = db.collection("users").document(uid)
        
        listener = ref.addSnapshotListener { [weak self] snapshot, error in
            if let error {
                self?.errorMessage = error.localizedDescription
                return
            }
            if let loaded = try? snapshot?.data(as: UserProfile.self) {
                self?.profile = loaded
            }
        }
    }
    
    func saveHabits() {
        guard let uid = userID else {
            errorMessage = "Not logged in"
            return
        }
        
        isLoading = true
        
        let ref = db.collection("users").document(uid)
        do {
            try ref.setData(from: profile, merge: true) { [weak self] error in
                if let error {
                    self?.errorMessage = error.localizedDescription
                } else {
                    self?.errorMessage = nil
                    self?.updateStreakAndXP()
                }
                self?.isLoading = false
            }
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    // MARK: - Streak & XP Logic
    private func updateStreakAndXP() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Check if all habits completed today
        let waterDone = profile.dailyWaterML >= 2000
        let sleepDone = profile.sleepHours >= 7
        let habitDone = profile.customHabitCompletedToday
        
        let allDoneToday = waterDone && sleepDone && habitDone
        
        if let last = profile.lastHabitDate {
            let lastDay = calendar.startOfDay(for: last)
            let daysSince = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0
            
            if daysSince == 0 {
                // Same day — update streak only if completed
                if allDoneToday {
                    // Already counted today — do nothing extra
                } else {
                    // Incomplete today → reset streak
                    profile.streakDays = 0
                }
            } else if daysSince == 1 {
                // Consecutive day
                if allDoneToday {
                    profile.streakDays += 1
                } else {
                    profile.streakDays = 0
                }
            } else {
                // Missed day(s) → reset
                profile.streakDays = 0
            }
        } else {
            // First ever completion
            if allDoneToday {
                profile.streakDays = 1
            }
        }
        
        // Update last completed date only if done today
        if allDoneToday {
            profile.lastHabitDate = today
            // Optional: Bonus XP for maintaining streak
            // let bonusXP = profile.streakDays * 10
            // profile.xp += bonusXP
        }
        
        // Save changes
        saveHabits()  // Recursive call safe because merge=true
    }
    
    // MARK: - Reminders
    func toggleReminders(enabled: Bool) {
        profile.remindersEnabled = enabled
        saveHabits()
        
        if enabled {
            requestNotificationPermission()
            scheduleDailyReminder()
        } else {
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    private func scheduleDailyReminder() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        let content = UNMutableNotificationContent()
        content.title = "Daily Habit Check-in"
        content.body = "Log your water (\(Int(profile.dailyWaterML)) ml target), sleep, and \(profile.customHabitName) today!"
        content.sound = .default
        
        // Schedule at 8:00 PM IST
        var dateComponents = DateComponents()
        dateComponents.hour = 20
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(identifier: "dailyHabitReminder", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("Notification scheduling error: \(error)")
            }
        }
    }
}
