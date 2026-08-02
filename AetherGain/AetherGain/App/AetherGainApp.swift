//
//  AetherGainApp.swift
//  AetherGain
//
//  Created by Dhriti on 1/4/2569 BE.
//

import SwiftUI
import FirebaseCore
import FirebaseFirestore

// Firebase bootstrap + Firestore offline persistence (Criterion 9).
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()

        // Enable offline persistence and unlimited cache so writes queue while offline
        // and reads work from local snapshots on cold launch without a connection.
        let settings = Firestore.firestore().settings
        settings.cacheSettings = PersistentCacheSettings(sizeBytes: NSNumber(value: FirestoreCacheSizeUnlimited))
        Firestore.firestore().settings = settings

        // Start monitoring reachability so we can surface toasts + auto-flush queued writes.
        NetworkMonitor.shared.start()

        return true
    }
}

@main
struct AetherGainApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    @StateObject private var authVM = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            ZStack(alignment: .top) {
                ContentView()
                    .environmentObject(authVM)
                AGToastHost()
            }
        }
    }
}
