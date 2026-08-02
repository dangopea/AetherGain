//
//  ContentView.swift
//  AetherGain
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @ObservedObject private var network = NetworkMonitor.shared
    @AppStorage("ag.privacy.accepted") private var privacyAccepted: Bool = false
    @AppStorage("ag.onboarding.targetsDone") private var targetsDone: Bool = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                if !privacyAccepted {
                    PrivacyNoticeView(onDone: { privacyAccepted = true })
                } else if !authVM.isSignedIn {
                    LoginView()
                } else if !targetsDone {
                    TargetsOnboardingView(onDone: { targetsDone = true })
                } else {
                    MainTabView()
                        .onAppear { authVM.userDidInteract() }
                        .onTapGesture { authVM.userDidInteract() }
                }
            }

            if !network.isOnline && privacyAccepted {
                HStack(spacing: 8) {
                    Image(systemName: "wifi.slash")
                    Text("Offline — changes will sync when you're back online.")
                        .lineLimit(2)
                }
                .font(AGFont.hud(11)).kerning(1)
                .foregroundColor(AGColor.ink)
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(Capsule().fill(AGColor.panelHi))
                .overlay(Capsule().stroke(AGColor.amber.opacity(0.4), lineWidth: 1))
                .padding(.bottom, 12)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .preferredColorScheme(.dark)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: network.isOnline)
    }
}

#Preview {
    ContentView().environmentObject(AuthViewModel())
}
