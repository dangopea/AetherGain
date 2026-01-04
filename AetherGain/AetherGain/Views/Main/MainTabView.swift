//
//  MainTabView.swift
//  AetherGain
//
//  Created by Dhriti on 1/4/2569 BE.
//

import Foundation
import SwiftUI

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
            
            // Log Workout Tab
            LogWorkoutView()
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                    Text("Log Workout")
                }
            
            //Workout History Tab
            WorkoutHistoryView()
                .tabItem {
                    Image(systemName: "clock.fill")
                    Text("History")
                }
            
            // Profile Tab
            ProfileView()
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
    MainTabView()
        .environmentObject(AuthViewModel())
}
