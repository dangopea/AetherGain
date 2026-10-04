//
//  ProfileView.swift
//  AetherGain
//

import SwiftUI
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var profileVM = ProfileViewModel()
    @AppStorage("ag.privacy.shareLeaderboard") private var appOptIn: Bool = false
    @AppStorage("ag.onboarding.targetsDone") private var targetsDone: Bool = false
    @State private var confirmSignOut = false
    @State private var showTargetsOnboarding = false
    @State private var pfpItem: PhotosPickerItem?
    @State private var isUploadingPfp = false

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                identityCard
                targetsCard
                statsCard
                personalCard
                privacyCard
                actionsCard
            }
            .padding(16)
            .padding(.bottom, 40)
        }
        .background(AGColor.canvas.ignoresSafeArea())
        .overlay(AGGrid().opacity(0.35).ignoresSafeArea().allowsHitTesting(false))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("PROFILE").kerning(2).font(AGFont.hud(12))
                    .foregroundColor(AGColor.amber)
            }
        }
        .sheet(isPresented: $showTargetsOnboarding) {
            TargetsOnboardingView(onDone: { showTargetsOnboarding = false })
                .agToastLayer()
        }
        .onAppear { authVM.userDidInteract() }
    }

    // MARK: - Identity

    private var identityCard: some View {
        HStack(spacing: 14) {
            ZStack(alignment: .bottomTrailing) {
                AGAvatar(urlString: profileVM.profile.profileImageURL,
                         initial: initial, size: 72, tint: AGColor.amber)
                PhotosPicker(selection: $pfpItem, matching: .images) {
                    ZStack {
                        Circle().fill(AGColor.amber)
                            .frame(width: 24, height: 24)
                            .shadow(color: AGColor.amber.opacity(0.6), radius: 4)
                        if isUploadingPfp {
                            ProgressView().tint(.black).scaleEffect(0.5)
                        } else {
                            Image(systemName: "camera.fill").font(.system(size: 10, weight: .bold))
                                .foregroundColor(.black)
                        }
                    }
                }
                .offset(x: 2, y: 2)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(profileVM.profile.name.isEmpty ? "Operator" : profileVM.profile.name)
                    .font(AGFont.title(20)).foregroundColor(AGColor.ink)
                Text("LVL \(GameEngine.level(for: profileVM.profile.xp)) · \(profileVM.profile.xp) XP")
                    .kerning(1.4).font(AGFont.hud(10))
                    .foregroundColor(AGColor.inkMuted)
            }
            Spacer()
        }
        .agCard()
        .onChange(of: pfpItem) { _, newItem in
            uploadPfp(newItem)
        }
    }

    private func uploadPfp(_ item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            isUploadingPfp = true
            defer { isUploadingPfp = false }
            do {
                guard let data = try await item.loadTransferable(type: Data.self),
                      let uiImage = UIImage(data: data) else {
                    AGToastCenter.shared.show("Couldn't read that image.", kind: .error)
                    return
                }
                let url = try await ProfileImageService.upload(image: uiImage)
                await MainActor.run {
                    profileVM.profile.profileImageURL = url.absoluteString
                    profileVM.saveProfile()
                    AGToastCenter.shared.show("Avatar updated.", kind: .success)
                }
            } catch {
                await MainActor.run {
                    AGToastCenter.shared.show("Upload failed: \(error.localizedDescription)", kind: .error)
                }
            }
        }
    }

    private var initial: String {
        String(profileVM.profile.name.trimmingCharacters(in: .whitespaces).prefix(1)).uppercased()
            .ifEmpty("A")
    }

    // MARK: - Targets

    private var targetsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            AGSectionHeader(title: "Daily targets",
                            subtitle: profileVM.profile.hasOnboardedTargets
                                        ? "From your calibration"
                                        : "Not calibrated yet")
            if profileVM.profile.hasOnboardedTargets {
                HStack {
                    miniStat("BMR", "\(profileVM.profile.bmr)", "kcal", AGColor.teal)
                    miniStat("TDEE", "\(profileVM.profile.tdee)", "kcal", AGColor.magenta)
                    miniStat("Target", "\(profileVM.profile.calorieTarget)", "kcal", AGColor.amber)
                }
                HStack {
                    miniStat("Protein", "\(profileVM.profile.proteinTargetG)", "g", AGColor.teal)
                    miniStat("Carbs", "\(profileVM.profile.carbsTargetG)", "g", AGColor.amberHi)
                    miniStat("Fat", "\(profileVM.profile.fatTargetG)", "g", AGColor.magenta)
                }
                Text("GOAL: \(profileVM.profile.fitnessGoal.rawValue.uppercased()) · \(String(format: "%.2f", profileVM.profile.goalRateKgPerWeek)) KG/WK · \(profileVM.profile.proteinPreference.rawValue.uppercased()) PROTEIN")
                    .kerning(1.2).font(AGFont.hud(10))
                    .foregroundColor(AGColor.inkMuted)
                    .padding(.top, 4)
            }
            AGGhostButton(title: profileVM.profile.hasOnboardedTargets ? "Recompute" : "Calibrate now",
                          icon: "arrow.triangle.2.circlepath",
                          accent: AGColor.amber) {
                showTargetsOnboarding = true
            }
        }
        .agCard()
    }

    private func miniStat(_ label: String, _ value: String, _ unit: String, _ tint: Color) -> some View {
        VStack(spacing: 4) {
            Text(label.uppercased()).kerning(1.4).font(AGFont.hud(9))
                .foregroundColor(AGColor.inkMuted)
            Text(value).font(AGFont.number(18)).foregroundColor(tint)
            Text(unit).font(AGFont.hud(9)).foregroundColor(AGColor.inkMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 10).fill(AGColor.panelHi))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(tint.opacity(0.3), lineWidth: 1))
    }

    // MARK: - Stats

    private var statsCard: some View {
        HStack(spacing: 10) {
            statBox(icon: "star.fill", tint: AGColor.magenta, label: "XP", value: "\(profileVM.profile.xp)")
            statBox(icon: "flame.fill", tint: AGColor.amber, label: "Streak", value: "\(profileVM.profile.streakDays)")
            statBox(icon: "trophy.fill", tint: AGColor.teal, label: "Level", value: "\(GameEngine.level(for: profileVM.profile.xp))")
        }
    }

    private func statBox(icon: String, tint: Color, label: String, value: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).foregroundColor(tint)
            Text(value).font(AGFont.number(20)).foregroundColor(AGColor.ink)
            Text(label.uppercased()).kerning(1.2).font(AGFont.hud(9))
                .foregroundColor(AGColor.inkMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 12).fill(AGColor.panel))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(tint.opacity(0.3), lineWidth: 1))
    }

    // MARK: - Personal

    private var personalCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            AGSectionHeader(title: "Personal")
            hudField(icon: "person.fill", tint: AGColor.amber) {
                TextField("Name", text: $profileVM.profile.name)
            }
            HStack {
                Image(systemName: "calendar").foregroundColor(AGColor.teal).frame(width: 24)
                Stepper("Age: \(profileVM.profile.age)", value: $profileVM.profile.age, in: 10...100)
                    .foregroundColor(AGColor.ink)
            }
            .padding(.horizontal, 12).padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 10).fill(AGColor.panelHi))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(AGColor.stroke, lineWidth: 1))

            hudField(icon: "target", tint: AGColor.teal) {
                TextField("Goals (e.g. Build muscle)", text: $profileVM.profile.goals)
                    .textInputAutocapitalization(.sentences)
            }
            hudField(icon: "leaf.fill", tint: AGColor.magenta) {
                TextField("Preferences (diet, workouts)", text: $profileVM.profile.preferences)
                    .textInputAutocapitalization(.sentences)
            }
        }
        .agCard()
    }

    private func hudField<Content: View>(icon: String, tint: Color,
                                         @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).foregroundColor(tint).frame(width: 24)
            content()
                .font(AGFont.body(14))
                .foregroundColor(AGColor.ink)
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 10).fill(AGColor.panelHi))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(AGColor.stroke, lineWidth: 1))
    }

    // MARK: - Privacy

    private var privacyCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            AGSectionHeader(title: "Privacy",
                            subtitle: "Encrypted at rest and in transit.")
            Toggle(isOn: leaderboardBinding) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Share on leaderboard").font(AGFont.headline(14))
                        .foregroundColor(AGColor.ink)
                    Text("Name, XP, level, and badges are visible to others.")
                        .font(AGFont.body(11)).foregroundColor(AGColor.inkMuted)
                }
            }
            .tint(AGColor.amber)
        }
        .agCard()
    }

    private var leaderboardBinding: Binding<Bool> {
        Binding(
            get: { profileVM.profile.sharesToLeaderboard ?? false },
            set: {
                profileVM.profile.sharesToLeaderboard = $0
                appOptIn = $0
            }
        )
    }

    // MARK: - Actions

    private var actionsCard: some View {
        VStack(spacing: 10) {
            AGPushButton(title: "Save profile", icon: "checkmark",
                         fill: AGColor.amber, textColor: .black,
                         isLoading: profileVM.isLoading) {
                profileVM.saveProfile()
                authVM.userDidInteract()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    if profileVM.errorMessage == nil {
                        AGToastCenter.shared.show("Profile saved.", kind: .success)
                    } else if let msg = profileVM.errorMessage {
                        AGToastCenter.shared.show(msg, kind: .error)
                    }
                }
            }
            AGGhostButton(title: "Sign out", icon: "rectangle.portrait.and.arrow.right",
                          accent: AGColor.danger) {
                confirmSignOut = true
            }
        }
        .alert("Sign out?", isPresented: $confirmSignOut) {
            Button("Cancel", role: .cancel) {}
            Button("Sign out", role: .destructive) {
                authVM.signOut()
                AGToastCenter.shared.show("Signed out.", kind: .info)
            }
        } message: {
            Text("Your data stays synced in the cloud.")
        }
    }
}

private extension String {
    func ifEmpty(_ fallback: String) -> String {
        isEmpty ? fallback : self
    }
}

#Preview {
    NavigationStack { ProfileView().environmentObject(AuthViewModel()) }
}
