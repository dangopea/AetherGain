//
//  AetherGainApp.swift
//  AetherGain
//
//  Created by Dhriti on 1/4/2569 BE.
//


//Initialization code pasted from Firebase Console
import SwiftUI
import FirebaseCore

//Initialization of Firebase
class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()

    return true
  }
}

@main
struct AetherGainApp: App {
  // Register app delegate for Firebase setup
  @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    @StateObject private var authVM = AuthViewModel() // AuthViewModel shared
        
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authVM)  //Makes authVM available everywhere
        }
    }
}
