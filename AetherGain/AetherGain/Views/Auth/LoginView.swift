//
//  LoginView.swift
//  AetherGain
//
//  Created by Dhriti on 1/4/2569 BE.
//

import SwiftUI

struct LoginView: View {
    @StateObject private var authVM = AuthViewModel()

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isSignupMode: Bool = false
    @State private var errorMessage: String? = nil
    @State private var isBusy: Bool = false
    @FocusState private var focused: Field?

    private enum Field { case email, password }

    var body: some View {
        AGScreen {
            ScrollView {
                VStack(spacing: 22) {
                    hero
                    formCard
                    footer
                }
                .padding(20)
                .padding(.top, 24)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .alert("Session expired", isPresented: $authVM.showTimeoutAlert) {
            Button("OK") { }
        } message: {
            Text("You have been logged out due to 30 minutes of inactivity. Please log in again.")
        }
        .onTapGesture { authVM.userDidInteract() }
        .onAppear { authVM.userDidInteract() }
        .environmentObject(authVM)
    }

    // MARK: - Hero

    private var hero: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(LinearGradient(colors: [AGColor.coral, AGColor.peach],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 92, height: 92)
                    .shadow(color: AGColor.coral.opacity(0.35), radius: 14, x: 0, y: 8)
                Image(systemName: "bolt.heart.fill")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundColor(.white)
            }
            Text("AetherGain").font(AGFont.display(34)).foregroundColor(AGColor.ink)
            Text(isSignupMode
                 ? "Create your account to start earning XP."
                 : "Welcome back — let's keep the streak alive.")
                .font(AGFont.body(15))
                .foregroundColor(AGColor.inkMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
    }

    // MARK: - Form

    private var formCard: some View {
        VStack(spacing: 14) {
            fieldBox(icon: "envelope.fill", tint: AGColor.sky) {
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .focused($focused, equals: .email)
                    .submitLabel(.next)
                    .onSubmit { focused = .password }
            }

            fieldBox(icon: "lock.fill", tint: AGColor.lavender) {
                SecureField("Password", text: $password)
                    .focused($focused, equals: .password)
                    .submitLabel(.go)
                    .onSubmit { submit() }
            }

            if !isSignupMode {
                HStack {
                    Spacer()
                    Button {
                        sendReset()
                    } label: {
                        Text("Forgot password?")
                            .font(AGFont.caption(12))
                            .foregroundColor(AGColor.teal)
                    }
                    .buttonStyle(.plain)
                }
            }

            if let error = errorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text(error).font(AGFont.caption(12))
                }
                .foregroundColor(AGColor.danger)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            AGPushButton(
                title: isSignupMode ? "Create account" : "Log in",
                icon: isSignupMode ? "sparkles" : "arrow.right",
                fill: AGColor.coral,
                isEnabled: !email.isEmpty && !password.isEmpty,
                isLoading: isBusy
            ) {
                submit()
            }

            Button(action: {
                withAnimation(.spring(response: 0.35)) {
                    isSignupMode.toggle()
                    errorMessage = nil
                }
            }) {
                HStack(spacing: 4) {
                    Text(isSignupMode ? "Already have an account?" : "New here?")
                        .foregroundColor(AGColor.inkMuted)
                    Text(isSignupMode ? "Log in" : "Sign up")
                        .foregroundColor(AGColor.coral).bold()
                }
                .font(AGFont.body(14))
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .agCard()
    }

    private func fieldBox<Content: View>(icon: String, tint: Color,
                                         @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(tint.opacity(0.20))
                    .frame(width: 36, height: 36)
                Image(systemName: icon).foregroundColor(tint)
            }
            content()
                .font(AGFont.body(15))
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AGColor.canvas)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AGColor.stroke, lineWidth: 1)
        )
    }

    private var footer: some View {
        VStack(spacing: 6) {
            HStack(spacing: 16) {
                perk(icon: "flame.fill", label: "Streaks")
                perk(icon: "trophy.fill", label: "Levels")
                perk(icon: "chart.bar.fill", label: "Trends")
            }
            Text("Encrypted end-to-end • Firebase Auth")
                .font(AGFont.caption(11))
                .foregroundColor(AGColor.inkMuted)
                .padding(.top, 4)
        }
        .padding(.top, 8)
    }

    private func perk(icon: String, label: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).foregroundColor(AGColor.coral)
            Text(label).foregroundColor(AGColor.inkMuted)
        }
        .font(AGFont.caption(12))
    }

    // MARK: - Actions

    private func sendReset() {
        errorMessage = nil
        AGHaptics.tap()
        authVM.sendPasswordReset(email: email) { error in
            DispatchQueue.main.async {
                if let err = error {
                    errorMessage = err.localizedDescription
                    AGToastCenter.shared.show(err.localizedDescription, kind: .error)
                } else {
                    AGToastCenter.shared.show("Reset link sent to \(email).", kind: .success)
                }
            }
        }
    }

    private func submit() {
        guard !isBusy else { return }
        errorMessage = nil
        isBusy = true
        let handler: (Error?) -> Void = { error in
            DispatchQueue.main.async {
                isBusy = false
                if let error = error as NSError? {
                    errorMessage = error.localizedDescription
                    AGHaptics.error()
                } else {
                    AGToastCenter.shared.show(isSignupMode ? "Welcome to AetherGain!" : "Welcome back!",
                                              kind: .success,
                                              celebrate: isSignupMode)
                }
            }
        }

        if isSignupMode {
            authVM.signUp(email: email, password: password, completion: handler)
        } else {
            authVM.signIn(email: email, password: password, completion: handler)
        }
        authVM.userDidInteract()
    }
}

#Preview {
    LoginView()
}
