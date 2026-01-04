//
//  ContentView.swift
//  AetherGain
//
//  Created by Dhriti on 1/4/2569 BE.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authVM: AuthViewModel // For it to access AuthViewModel
    
    var body: some View {
        Group {
            if authVM.isSignedIn {
                // Placeholder for your future main app (workouts, profile, etc.)
                MainTabView()
                    .onAppear { authVM.userDidInteract() }
                    .onTapGesture { authVM.userDidInteract() }
            } else {
                LoginView()
            }
        }
    }
}

//Temporary home tab view
struct MainTabView: View {
    @EnvironmentObject var authVM: AuthViewModel
    
    var body: some View {
        TabView {
            // Home Tab
            VStack(spacing: 20) {
                Text("Home Dashboard")
                    .font(.largeTitle.bold())
                Text("(Workouts, Streaks, XP coming soon)")
                    .foregroundColor(.secondary)
                Spacer()
            }
            .tabItem {
                Image(systemName: "house.fill")
                Text("Home")
            }
            
            // Profile Tab (placeholder for now)
            Text("Profile Section\n(Edit name, age, goals here)")
                .font(.title2)
                .foregroundColor(.secondary)
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
            
            // Settings Tab – with proper Sign Out button
            VStack(spacing: 30) {
                Text("Settings")
                    .font(.largeTitle.bold())
                
                Button("Sign Out") {
                    authVM.signOut()
                }
                .font(.title2)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.red)
                .cornerRadius(12)
                .padding(.horizontal, 40)
                
                Spacer()
            }
            .tabItem {
                Image(systemName: "gearshape.fill")
                Text("Settings")
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
}
