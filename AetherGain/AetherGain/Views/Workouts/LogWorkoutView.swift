//
//  LogWorkoutView.swift
//  AetherGain
//

import SwiftUI

struct LogWorkoutView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var workoutVM = WorkoutViewModel()
    @State private var showCustomExerciseSheet = false
    @State private var customExerciseName = ""

    private var estimatedXP: Int { GameEngine.workoutXP(for: workoutVM.currentSession) }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                xpHeaderCard
                dateCard

                ForEach(workoutVM.currentSession.exercises.indices, id: \.self) { index in
                    exerciseCard(index: index)
                }

                addExerciseCard
                completeCard
            }
            .padding(16)
            .padding(.bottom, 40)
        }
        .background(AGColor.canvas.ignoresSafeArea())
        .sheet(isPresented: $showCustomExerciseSheet) { customExerciseSheet }
        .onAppear {
            if workoutVM.currentSession.exercises.isEmpty {
                workoutVM.addExercise()
            }
            authVM.userDidInteract()
        }
    }

    // MARK: - Cards

    private var xpHeaderCard: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(LinearGradient(colors: [AGColor.coral, AGColor.peach],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 62, height: 62)
                Image(systemName: "bolt.fill").foregroundColor(.white).font(.system(size: 28, weight: .bold))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Estimated XP").font(AGFont.caption(12)).foregroundColor(AGColor.inkMuted)
                Text("+\(estimatedXP)").font(AGFont.number(28)).foregroundColor(AGColor.ink)
                Text("Base 50 + exercise bonuses")
                    .font(AGFont.caption(11)).foregroundColor(AGColor.inkMuted)
            }
            Spacer()
        }
        .agCard()
    }

    private var dateCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "calendar")
                .foregroundColor(AGColor.teal)
                .font(.system(size: 16, weight: .bold))
            VStack(alignment: .leading, spacing: 2) {
                Text("SESSION DATE").kerning(1.4).font(AGFont.hud(9))
                    .foregroundColor(AGColor.inkMuted)
                Text("Backdate to log a past workout.")
                    .font(AGFont.body(11)).foregroundColor(AGColor.inkMuted)
            }
            Spacer()
            DatePicker(
                "",
                selection: Binding(
                    get: { workoutVM.currentSession.date },
                    set: { workoutVM.currentSession.date = $0 }
                ),
                in: ...Date(),
                displayedComponents: [.date, .hourAndMinute]
            )
            .labelsHidden()
            .datePickerStyle(.compact)
            .tint(AGColor.amber)
        }
        .agCard()
    }

    private func exerciseCard(index: Int) -> some View {
        // Bounds-guard: array can transiently shrink around save/reset.
        let category: ExerciseCategory = {
            guard workoutVM.currentSession.exercises.indices.contains(index) else { return .strength }
            return workoutVM.currentSession.exercises[index].category ?? .strength
        }()
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Exercise \(index + 1)").font(AGFont.headline(15))
                Spacer()
                Button(role: .destructive) {
                    guard workoutVM.currentSession.exercises.indices.contains(index) else { return }
                    workoutVM.removeExercise(at: index)
                    AGHaptics.tap()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AGColor.inkMuted)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 8) {
                TextField("Exercise name", text: safeText(index: index))
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .font(AGFont.body(15))
                    .foregroundColor(AGColor.ink)
                    .padding(.horizontal, 12).padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 12).fill(AGColor.canvas))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(AGColor.stroke, lineWidth: 1))
                    .onChange(of: workoutVM.currentSession.exercises.indices.contains(index)
                              ? workoutVM.currentSession.exercises[index].type : "") { _, _ in
                        authVM.userDidInteract()
                    }

                Menu {
                    ForEach(ExerciseTemplate.catalog) { template in
                        Button(template.name) {
                            workoutVM.applyTemplate(template, at: index)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "list.bullet")
                        Text("TEMPLATES").kerning(1.4)
                    }
                    .font(AGFont.hud(10))
                    .foregroundColor(AGColor.teal)
                    .padding(.horizontal, 10).padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(AGColor.teal.opacity(0.10)))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(AGColor.teal.opacity(0.35), lineWidth: 1))
                }
            }

            // Manual category picker — no auto-inference on keystroke anymore.
            categoryPicker(index: index, currentCategory: category)

            HStack(spacing: 8) {
                Spacer()
                Text("+\(safeExerciseXP(index: index)) XP")
                    .font(AGFont.caption(12))
                    .foregroundColor(AGColor.success)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Capsule().fill(AGColor.success.opacity(0.15)))
            }

            switch category {
            case .strength: strengthFields(for: index)
            case .cardio:   cardioFields(for: index)
            case .mobility: mobilityFields(for: index)
            }

            TextField("Notes (optional)", text: safeNotes(index: index))
                .textInputAutocapitalization(.sentences)
                .padding(.horizontal, 12).padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 12).fill(AGColor.canvas))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(AGColor.stroke, lineWidth: 1))
        }
        .agCard()
    }

    // MARK: - Category picker (manual)

    private func categoryPicker(index: Int, currentCategory: ExerciseCategory) -> some View {
        HStack(spacing: 6) {
            ForEach(ExerciseCategory.allCases) { c in
                Button {
                    guard workoutVM.currentSession.exercises.indices.contains(index) else { return }
                    workoutVM.currentSession.exercises[index].category = c
                        AGHaptics.tap()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: iconFor(c))
                        Text(c.displayName.uppercased()).kerning(1.2)
                    }
                    .font(AGFont.hud(10))
                    .foregroundColor(c == currentCategory ? .black : colorFor(c))
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(c == currentCategory ? colorFor(c) : colorFor(c).opacity(0.08))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(colorFor(c).opacity(0.5), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }

    private func colorFor(_ c: ExerciseCategory) -> Color {
        switch c {
        case .strength: return AGColor.amber
        case .cardio:   return AGColor.teal
        case .mobility: return AGColor.magenta
        }
    }

    private func iconFor(_ c: ExerciseCategory) -> String {
        switch c {
        case .strength: return "dumbbell.fill"
        case .cardio:   return "figure.run"
        case .mobility: return "figure.mind.and.body"
        }
    }

    // MARK: - Safe bindings (guard against Index out of range after session reset)

    private func safeText(index: Int) -> Binding<String> {
        Binding(
            get: {
                guard workoutVM.currentSession.exercises.indices.contains(index) else { return "" }
                return workoutVM.currentSession.exercises[index].type
            },
            set: {
                guard workoutVM.currentSession.exercises.indices.contains(index) else { return }
                workoutVM.currentSession.exercises[index].type = $0
            }
        )
    }

    private func safeNotes(index: Int) -> Binding<String> {
        Binding(
            get: {
                guard workoutVM.currentSession.exercises.indices.contains(index) else { return "" }
                return workoutVM.currentSession.exercises[index].notes
            },
            set: {
                guard workoutVM.currentSession.exercises.indices.contains(index) else { return }
                workoutVM.currentSession.exercises[index].notes = $0
            }
        )
    }

    private func safeInt(index: Int, keyPath: WritableKeyPath<Exercise, Int>) -> Binding<Int> {
        Binding(
            get: {
                guard workoutVM.currentSession.exercises.indices.contains(index) else { return 0 }
                return workoutVM.currentSession.exercises[index][keyPath: keyPath]
            },
            set: {
                guard workoutVM.currentSession.exercises.indices.contains(index) else { return }
                workoutVM.currentSession.exercises[index][keyPath: keyPath] = $0
            }
        )
    }

    private func safeDouble(index: Int, keyPath: WritableKeyPath<Exercise, Double>) -> Binding<Double> {
        Binding(
            get: {
                guard workoutVM.currentSession.exercises.indices.contains(index) else { return 0 }
                return workoutVM.currentSession.exercises[index][keyPath: keyPath]
            },
            set: {
                guard workoutVM.currentSession.exercises.indices.contains(index) else { return }
                workoutVM.currentSession.exercises[index][keyPath: keyPath] = $0
            }
        )
    }

    private func safeOptionalDouble(index: Int, keyPath: WritableKeyPath<Exercise, Double?>) -> Binding<Double> {
        Binding(
            get: {
                guard workoutVM.currentSession.exercises.indices.contains(index) else { return 0 }
                return workoutVM.currentSession.exercises[index][keyPath: keyPath] ?? 0
            },
            set: {
                guard workoutVM.currentSession.exercises.indices.contains(index) else { return }
                workoutVM.currentSession.exercises[index][keyPath: keyPath] = $0
            }
        )
    }

    private func safeExerciseXP(index: Int) -> Int {
        guard workoutVM.currentSession.exercises.indices.contains(index) else { return 0 }
        return GameEngine.exerciseXP(for: workoutVM.currentSession.exercises[index])
    }

    private func safeSets(index: Int) -> Int {
        guard workoutVM.currentSession.exercises.indices.contains(index) else { return 0 }
        return workoutVM.currentSession.exercises[index].sets
    }

    private func safeReps(index: Int) -> Int {
        guard workoutVM.currentSession.exercises.indices.contains(index) else { return 0 }
        return workoutVM.currentSession.exercises[index].reps
    }

    // MARK: - Field variants

    private func strengthFields(for index: Int) -> some View {
        VStack(spacing: 10) {
            Stepper("Sets: \(safeSets(index: index))",
                    value: safeInt(index: index, keyPath: \.sets), in: 1...20)
            Stepper("Reps: \(safeReps(index: index))",
                    value: safeInt(index: index, keyPath: \.reps), in: 1...50)
            numberRow(label: "Weight", unit: "kg",
                      value: safeDouble(index: index, keyPath: \.weightKG))
        }
    }

    private func cardioFields(for index: Int) -> some View {
        VStack(spacing: 10) {
            numberRow(label: "Distance", unit: "km",
                      value: safeOptionalDouble(index: index, keyPath: \.distanceKM))
            numberRow(label: "Time", unit: "min",
                      value: safeOptionalDouble(index: index, keyPath: \.durationMinutes))
            numberRow(label: "Incline", unit: "%",
                      value: safeOptionalDouble(index: index, keyPath: \.inclinePercent))
        }
    }

    private func mobilityFields(for index: Int) -> some View {
        numberRow(label: "Time", unit: "min",
                  value: safeOptionalDouble(index: index, keyPath: \.durationMinutes))
    }

    private func numberRow(label: String, unit: String, value: Binding<Double>) -> some View {
        HStack {
            Text(label).font(AGFont.body(14)).foregroundColor(AGColor.ink)
            Spacer()
            TextField(unit, value: value, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 90)
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 10).fill(AGColor.canvas))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(AGColor.stroke, lineWidth: 1))
            Text(unit).font(AGFont.caption(12)).foregroundColor(AGColor.inkMuted)
        }
    }

    private var addExerciseCard: some View {
        HStack(spacing: 12) {
            AGGhostButton(title: "Add exercise", icon: "plus", accent: AGColor.coral) {
                workoutVM.addExercise()
                authVM.userDidInteract()
            }
            AGGhostButton(title: "Custom", icon: "square.and.pencil", accent: AGColor.lavender) {
                showCustomExerciseSheet = true
            }
            Spacer()
        }
    }

    private var completeCard: some View {
        VStack(spacing: 10) {
            if let error = workoutVM.errorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text(error).font(AGFont.caption(12))
                }
                .foregroundColor(AGColor.danger)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            AGPushButton(
                title: "Complete workout · +\(estimatedXP) XP",
                icon: "checkmark",
                fill: AGColor.success,
                isEnabled: workoutVM.currentSession.isValidForXP,
                isLoading: workoutVM.isLoading
            ) {
                let xpForToast = estimatedXP
                workoutVM.completeSession()
                authVM.userDidInteract()
                // Feedback is raised on the validation result, not on a server
                // acknowledgement. `completeSession()` sets `errorMessage`
                // synchronously when a guard rejects the session, and hands the
                // batch to Firestore otherwise. Firestore's own completion
                // handler only fires once the server has acknowledged the
                // write, so waiting for it would mean no confirmation at all
                // while offline — exactly the case success criterion 9 is
                // about. Waiting on `history.count` was worse still: the
                // listener often needs longer than the 0.4 s this code allowed,
                // so a successful save silently produced nothing.
                if let msg = workoutVM.errorMessage {
                    AGToastCenter.shared.show(msg, kind: .error)
                } else {
                    AGToastCenter.shared.show("Workout logged! +\(xpForToast) XP earned",
                                              kind: .success, celebrate: true)
                }
            }
        }
    }

    // MARK: - Custom exercise sheet

    private var customExerciseSheet: some View {
        NavigationStack {
            AGScreen {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Exercise name").font(AGFont.headline(15))
                        TextField("e.g. Kettlebell swing", text: $customExerciseName)
                            .textInputAutocapitalization(.words)
                            .padding(.horizontal, 12).padding(.vertical, 10)
                            .background(RoundedRectangle(cornerRadius: 12).fill(AGColor.canvas))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AGColor.stroke, lineWidth: 1))
                    }
                    .agCard()

                    Text("Names like Running, Cycling, Swimming, Yoga, or Stretching auto-classify. Others default to strength.")
                        .font(AGFont.caption(11)).foregroundColor(AGColor.inkMuted)

                    Spacer()
                }
                .padding(16)
            }
            .navigationTitle("New exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        customExerciseName = ""
                        showCustomExerciseSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        workoutVM.addCustomExercise(named: customExerciseName)
                        customExerciseName = ""
                        showCustomExerciseSheet = false
                    }
                    .disabled(customExerciseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

#Preview {
    LogWorkoutView().environmentObject(AuthViewModel())
}
