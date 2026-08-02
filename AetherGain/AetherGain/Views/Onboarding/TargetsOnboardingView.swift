//
//  TargetsOnboardingView.swift
//  AetherGain
//
//  Collects the inputs for BMR/TDEE and computes daily targets
//  (calories, protein, carbs, fat). Runs once after Privacy notice
//  but can be revisited from Profile → "Recompute my targets".
//

import SwiftUI

struct TargetsOnboardingView: View {
    @StateObject private var profileVM = ProfileViewModel()
    @AppStorage("ag.onboarding.targetsDone") private var targetsDone: Bool = false
    var onDone: () -> Void

    // Local editable copy so we don't spam Firestore per field change.
    @State private var draft = UserProfile()
    @State private var stepIndex: Int = 0
    private let stepCount = 4

    private var computed: DailyTargets {
        TargetsCalculator.compute(for: draft)
    }

    var body: some View {
        AGScreen {
            VStack(spacing: 0) {
                progressHeader
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        switch stepIndex {
                        case 0: personalStep
                        case 1: anthropometricsStep
                        case 2: lifestyleStep
                        default: goalStep
                        }
                        previewCard
                    }
                    .padding(16)
                    .padding(.bottom, 30)
                }
                navBar
            }
        }
        .onAppear {
            // Seed from any existing profile so a re-run keeps values.
            draft = profileVM.profile
            if draft.age <= 0 { draft.age = 18 }
        }
    }

    // MARK: - Header

    private var progressHeader: some View {
        VStack(spacing: 8) {
            HStack {
                Text("CALIBRATE TARGETS").kerning(2).font(AGFont.hud(11))
                    .foregroundColor(AGColor.amber)
                Spacer()
                Text("STEP \(stepIndex + 1) / \(stepCount)").kerning(1.4)
                    .font(AGFont.hud(10)).foregroundColor(AGColor.inkMuted)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle().fill(AGColor.panelHi).frame(height: 3)
                    Rectangle().fill(AGColor.amber)
                        .frame(width: geo.size.width * CGFloat(stepIndex + 1) / CGFloat(stepCount),
                               height: 3)
                        .shadow(color: AGColor.amber, radius: 4)
                }
            }
            .frame(height: 3)
        }
        .padding(.horizontal, 16).padding(.top, 12)
    }

    // MARK: - Steps

    private var personalStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            AGSectionHeader(title: "Who's calibrating?",
                            subtitle: "Basic identity for accurate metabolism.")
            fieldLabel("Name")
            TextField("Name", text: $draft.name)
                .textFieldStyle(HUDTextFieldStyle())

            fieldLabel("Sex (affects BMR formula)")
            Picker("Sex", selection: $draft.sex) {
                ForEach(Sex.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)

            fieldLabel("Age")
            Stepper("Age: \(draft.age)", value: $draft.age, in: 12...100)
                .font(AGFont.body(14))
                .foregroundColor(AGColor.ink)
        }
        .agCard()
    }

    private var anthropometricsStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            AGSectionHeader(title: "Body stats")
            HStack {
                fieldLabel("Height").frame(width: 100, alignment: .leading)
                TextField("cm", value: $draft.heightCM, format: .number)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(HUDTextFieldStyle())
                Text("cm").font(AGFont.hud(10)).foregroundColor(AGColor.inkMuted)
            }
            HStack {
                fieldLabel("Weight").frame(width: 100, alignment: .leading)
                TextField("kg", value: $draft.weightKG, format: .number)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(HUDTextFieldStyle())
                Text("kg").font(AGFont.hud(10)).foregroundColor(AGColor.inkMuted)
            }
            HStack {
                fieldLabel("Body fat %").frame(width: 100, alignment: .leading)
                TextField("optional", value: Binding(
                    get: { draft.bodyFatPercent ?? 0 },
                    set: { draft.bodyFatPercent = $0 == 0 ? nil : $0 }
                ), format: .number)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(HUDTextFieldStyle())
                Text("%").font(AGFont.hud(10)).foregroundColor(AGColor.inkMuted)
            }
            Text("Body fat is optional — if provided, we use Katch-McArdle (more accurate for lean users) instead of Mifflin-St Jeor.")
                .font(AGFont.body(11)).foregroundColor(AGColor.inkMuted)
        }
        .agCard()
    }

    private var lifestyleStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            AGSectionHeader(title: "Activity",
                            subtitle: "Used to convert BMR → TDEE.")
            fieldLabel("Average steps per day")
            HStack {
                Slider(value: Binding(
                    get: { Double(draft.avgStepsPerDay) },
                    set: { draft.avgStepsPerDay = Int($0) }
                ), in: 0...20000, step: 500).tint(AGColor.amber)
                Text("\(draft.avgStepsPerDay)").font(AGFont.mono(13))
                    .foregroundColor(AGColor.ink).frame(width: 60, alignment: .trailing)
            }

            fieldLabel("Workouts per week")
            Stepper("\(draft.workoutsPerWeek) sessions", value: $draft.workoutsPerWeek, in: 0...14)
                .foregroundColor(AGColor.ink)

            HStack(spacing: 8) {
                AGHudChip(text: "BMR = \(computed.bmr) kcal", tint: AGColor.teal)
                AGHudChip(text: "Activity ×\(String(format: "%.2f", computed.activityMultiplier))",
                          tint: AGColor.magenta)
            }
        }
        .agCard()
    }

    private var goalStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            AGSectionHeader(title: "Objective")
            fieldLabel("Goal")
            Picker("Goal", selection: $draft.fitnessGoal) {
                ForEach(FitnessGoal.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)

            if draft.fitnessGoal != .maintain {
                fieldLabel("Rate (kg / week)")
                HStack {
                    Slider(value: $draft.goalRateKgPerWeek, in: 0.1...1.0, step: 0.05)
                        .tint(AGColor.amber)
                    Text(String(format: "%.2f kg/wk", draft.goalRateKgPerWeek))
                        .font(AGFont.mono(12)).foregroundColor(AGColor.ink)
                        .frame(width: 90, alignment: .trailing)
                }
                Text("~\(Int(draft.goalRateKgPerWeek * 7700 / 7)) kcal/day \(draft.fitnessGoal == .cut ? "deficit" : "surplus")")
                    .font(AGFont.hud(10)).foregroundColor(AGColor.inkMuted).kerning(1)
            }

            fieldLabel("Protein preference")
            Picker("Protein", selection: $draft.proteinPreference) {
                ForEach(ProteinPreference.allCases) { p in
                    Text("\(p.rawValue) · \(String(format: "%.1f", p.gramsPerKg))g/kg").tag(p)
                }
            }
            .pickerStyle(.menu)
            .foregroundColor(AGColor.teal)
        }
        .agCard()
    }

    // MARK: - Live preview

    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            AGSectionHeader(title: "Computed daily targets",
                            subtitle: "Live preview — finalises when you're done.")
            HStack {
                statTile("BMR", "\(computed.bmr)", "kcal", tint: AGColor.teal)
                statTile("TDEE", "\(computed.tdee)", "kcal", tint: AGColor.magenta)
                statTile("Target", "\(computed.calories)", "kcal", tint: AGColor.amber)
            }
            HStack {
                statTile("Protein", "\(computed.proteinG)", "g", tint: AGColor.teal)
                statTile("Carbs",   "\(computed.carbsG)",   "g", tint: AGColor.amberHi)
                statTile("Fat",     "\(computed.fatG)",     "g", tint: AGColor.magenta)
            }
        }
        .agCard()
    }

    private func statTile(_ label: String, _ value: String, _ unit: String, tint: Color) -> some View {
        VStack(spacing: 4) {
            Text(label.uppercased()).kerning(1.4).font(AGFont.hud(9))
                .foregroundColor(AGColor.inkMuted)
            Text(value).font(AGFont.number(20)).foregroundColor(tint)
            Text(unit).font(AGFont.hud(9)).foregroundColor(AGColor.inkMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 10).fill(AGColor.panelHi))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(tint.opacity(0.35), lineWidth: 1))
    }

    // MARK: - Nav bar

    private var navBar: some View {
        HStack(spacing: 12) {
            if stepIndex > 0 {
                AGGhostButton(title: "Back", icon: "chevron.left", accent: AGColor.teal) {
                    withAnimation { stepIndex -= 1 }
                }
            }
            Spacer()
            AGPushButton(
                title: stepIndex == stepCount - 1 ? "Save targets" : "Next",
                icon: stepIndex == stepCount - 1 ? "checkmark" : "chevron.right",
                fill: AGColor.amber, textColor: .black
            ) {
                if stepIndex == stepCount - 1 {
                    finish()
                } else {
                    withAnimation { stepIndex += 1 }
                }
            }
            .frame(width: 200)
        }
        .padding(16)
        .background(
            LinearGradient(colors: [AGColor.canvas.opacity(0), AGColor.canvas],
                           startPoint: .top, endPoint: .bottom)
        )
    }

    private func finish() {
        let targets = TargetsCalculator.compute(for: draft)
        TargetsCalculator.apply(targets, to: &draft)
        profileVM.profile = draft
        profileVM.saveProfile()
        targetsDone = true
        AGToastCenter.shared.show("Targets calibrated: \(targets.calories) kcal / day", kind: .success, celebrate: true)
        onDone()
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text.uppercased()).kerning(1.4).font(AGFont.hud(10))
            .foregroundColor(AGColor.inkMuted)
    }
}

private struct HUDTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(AGFont.body(14))
            .foregroundColor(AGColor.ink)
            .padding(.horizontal, 10).padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 8).fill(AGColor.panelHi))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(AGColor.stroke, lineWidth: 1))
    }
}

#Preview {
    TargetsOnboardingView(onDone: {})
}
