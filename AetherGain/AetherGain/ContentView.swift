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

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
}
