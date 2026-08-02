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
            DispatchQueue.main.async {
                self.errorMessage = "Not logged in"
                self.isLoading = false
            }
            return
        }

        // Compute streak/XP FIRST so a single write persists everything.
        applyStreakChange()

        isLoading = true

        let ref = db.collection("users").document(uid)
        do {
            try ref.setData(from: profile, merge: true) { [weak self] error in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    if let error {
                        self.errorMessage = error.localizedDescription
                    } else {
                        self.errorMessage = nil
                    }
                    self.isLoading = false
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    // MARK: - Streak & XP Logic
    /// Only positive events touch the streak. We never reset the streak because
    /// "today's targets aren't done yet" — that's just an in-progress day.
    /// Resets only happen when we detect a *missed* day (>1 day gap when we
    /// hit all targets again).
    private func applyStreakChange() {
        let allDoneToday = waterHitToday && sleepHitToday && profile.customHabitCompletedToday
        guard allDoneToday else { return }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let last = profile.lastHabitDate {
            let lastDay = calendar.startOfDay(for: last)
            let daysSince = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0
            if daysSince == 0 { return }         // already counted today
            if daysSince == 1 {
                profile.streakDays += 1          // consecutive day
            } else {
                profile.streakDays = 1           // missed one or more days
            }
        } else {
            profile.streakDays = 1
        }
        profile.lastHabitDate = today

        let bonusXP = 20 + (profile.streakDays * 5)
        profile.xp += bonusXP
    }

    private var waterHitToday: Bool { profile.dailyWaterML >= profile.waterMLTarget * 0.8 }
    private var sleepHitToday: Bool { profile.sleepHours >= profile.sleepHoursTarget * 0.85 }
    
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
    
    func scheduleDailyReminder() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

        let content = UNMutableNotificationContent()
        content.title = "Daily habit check-in"
        content.body  = "Log \(Int(profile.waterMLTarget)) ml water, \(Int(profile.sleepHoursTarget))h sleep, and \(profile.customHabitName)."
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour   = profile.reminderHour
        dateComponents.minute = profile.reminderMinute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyHabitReminder", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error { print("Notification scheduling error: \(error)") }
        }
    }

    /// Streak logic uses configurable water/sleep targets now.
    
    // Removed stopSavingIndicatorIfServerIsSlow() as it's no longer necessary
    
}
