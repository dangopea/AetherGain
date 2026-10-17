










import SwiftUI

struct WorkoutEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var workoutVM: WorkoutViewModel


    @State private var draft: WorkoutSession
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(session: WorkoutSession, workoutVM: WorkoutViewModel) {
        _draft = State(initialValue: session)
        self.workoutVM = workoutVM
    }

    private var estimatedXP: Int { GameEngine.workoutXP(for: draft) }
    private var xpDelta: Int { estimatedXP - draft.totalXP }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    headerCard
                    ForEach(draft.exercises.indices, id: \.self) { index in
                        if draft.exercises.indices.contains(index) {
                            exerciseCard(index: index)
                        }
                    }
                    addExerciseRow
                    if let msg = errorMessage {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text(msg).font(AGFont.body(12))
                        }
                        .foregroundColor(AGColor.danger)
                    }
                    AGPushButton(
                        title: "Save changes",
                        icon: "checkmark",
                        fill: AGColor.amber, textColor: .black,
                        isEnabled: draft.isValidForXP,
                        isLoading: isSaving
                    ) {
                        save()
                    }
                }
                .padding(16)
                .padding(.bottom, 40)
            }
            .background(AGColor.canvas.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("EDIT WORKOUT").kerning(2).font(AGFont.hud(12))
                        .foregroundColor(AGColor.amber)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundColor(AGColor.teal)
                }
            }
        }
    }



    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            AGSectionHeader(title: "Session summary",
                            subtitle: "XP will adjust by the delta below.")
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("ORIGINAL XP").kerning(1.2).font(AGFont.hud(9))
                        .foregroundColor(AGColor.inkMuted)
                    Text("\(draft.totalXP)").font(AGFont.number(20))
                        .foregroundColor(AGColor.inkMuted)
                }
                Spacer()
                VStack(alignment: .center, spacing: 2) {
                    Text("NEW XP").kerning(1.2).font(AGFont.hud(9))
                        .foregroundColor(AGColor.amber)
                    Text("\(estimatedXP)").font(AGFont.number(24))
                        .foregroundColor(AGColor.amber)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("DELTA").kerning(1.2).font(AGFont.hud(9))
                        .foregroundColor(AGColor.inkMuted)
                    Text(xpDelta >= 0 ? "+\(xpDelta)" : "\(xpDelta)")
                        .font(AGFont.number(20))
                        .foregroundColor(xpDelta >= 0 ? AGColor.teal : AGColor.danger)
                }
            }
        }
        .agCard()
    }



    private func exerciseCard(index: Int) -> some View {
        let cat = draft.exercises[index].category ?? .strength
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Exercise \(index + 1)").font(AGFont.headline(15))
                    .foregroundColor(AGColor.ink)
                Spacer()
                Button(role: .destructive) {
                    guard draft.exercises.indices.contains(index) else { return }
                    draft.exercises.remove(at: index)
                    AGHaptics.tap()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AGColor.inkMuted)
                }
                .buttonStyle(.plain)
            }

            TextField("Exercise name", text: safeText(index: index))
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .font(AGFont.body(15))
                .foregroundColor(AGColor.ink)
                .padding(.horizontal, 12).padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 12).fill(AGColor.canvas))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(AGColor.stroke, lineWidth: 1))

            categoryPicker(index: index, currentCategory: cat)

            switch cat {
            case .strength: strengthFields(index: index)
            case .cardio:   cardioFields(index: index)
            case .mobility: mobilityFields(index: index)
            }

            TextField("Notes (optional)", text: safeNotes(index: index))
                .padding(.horizontal, 12).padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 12).fill(AGColor.canvas))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(AGColor.stroke, lineWidth: 1))
        }
        .agCard()
    }



    private func categoryPicker(index: Int, currentCategory: ExerciseCategory) -> some View {
        HStack(spacing: 6) {
            ForEach(ExerciseCategory.allCases) { c in
                Button {
                    guard draft.exercises.indices.contains(index) else { return }
                    draft.exercises[index].category = c
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



    private func strengthFields(index: Int) -> some View {
        VStack(spacing: 10) {
            Stepper("Sets: \(safeInt(index: index, keyPath: \.sets).wrappedValue)",
                    value: safeInt(index: index, keyPath: \.sets), in: 1...20)
            Stepper("Reps: \(safeInt(index: index, keyPath: \.reps).wrappedValue)",
                    value: safeInt(index: index, keyPath: \.reps), in: 1...50)
            numberRow(label: "Weight", unit: "kg",
                      value: safeDouble(index: index, keyPath: \.weightKG))
        }
    }

    private func cardioFields(index: Int) -> some View {
        VStack(spacing: 10) {
            numberRow(label: "Distance", unit: "km",
                      value: safeOptionalDouble(index: index, keyPath: \.distanceKM))
            numberRow(label: "Time", unit: "min",
                      value: safeOptionalDouble(index: index, keyPath: \.durationMinutes))
            numberRow(label: "Incline", unit: "%",
                      value: safeOptionalDouble(index: index, keyPath: \.inclinePercent))
        }
    }

    private func mobilityFields(index: Int) -> some View {
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

    private var addExerciseRow: some View {
        HStack(spacing: 12) {
            AGGhostButton(title: "Add exercise", icon: "plus", accent: AGColor.amber) {
                draft.exercises.append(ExerciseTemplate.configuredExercise(named: "Bench Press"))
            }
            Spacer()
        }
    }



    private func safeText(index: Int) -> Binding<String> {
        Binding(
            get: { draft.exercises.indices.contains(index) ? draft.exercises[index].type : "" },
            set: {
                guard draft.exercises.indices.contains(index) else { return }
                draft.exercises[index].type = $0
            }
        )
    }

    private func safeNotes(index: Int) -> Binding<String> {
        Binding(
            get: { draft.exercises.indices.contains(index) ? draft.exercises[index].notes : "" },
            set: {
                guard draft.exercises.indices.contains(index) else { return }
                draft.exercises[index].notes = $0
            }
        )
    }

    private func safeInt(index: Int, keyPath: WritableKeyPath<Exercise, Int>) -> Binding<Int> {
        Binding(
            get: { draft.exercises.indices.contains(index) ? draft.exercises[index][keyPath: keyPath] : 0 },
            set: {
                guard draft.exercises.indices.contains(index) else { return }
                draft.exercises[index][keyPath: keyPath] = $0
            }
        )
    }

    private func safeDouble(index: Int, keyPath: WritableKeyPath<Exercise, Double>) -> Binding<Double> {
        Binding(
            get: { draft.exercises.indices.contains(index) ? draft.exercises[index][keyPath: keyPath] : 0 },
            set: {
                guard draft.exercises.indices.contains(index) else { return }
                draft.exercises[index][keyPath: keyPath] = $0
            }
        )
    }

    private func safeOptionalDouble(index: Int, keyPath: WritableKeyPath<Exercise, Double?>) -> Binding<Double> {
        Binding(
            get: { draft.exercises.indices.contains(index) ? (draft.exercises[index][keyPath: keyPath] ?? 0) : 0 },
            set: {
                guard draft.exercises.indices.contains(index) else { return }
                draft.exercises[index][keyPath: keyPath] = $0
            }
        )
    }

    private func iconFor(_ c: ExerciseCategory) -> String {
        switch c {
        case .strength: return "dumbbell.fill"
        case .cardio:   return "figure.run"
        case .mobility: return "figure.mind.and.body"
        }
    }
    private func colorFor(_ c: ExerciseCategory) -> Color {
        switch c {
        case .strength: return AGColor.amber
        case .cardio:   return AGColor.teal
        case .mobility: return AGColor.magenta
        }
    }



    private func save() {
        errorMessage = nil
        isSaving = true
        workoutVM.updateSession(draft) { error in
            isSaving = false
            if let err = error {
                errorMessage = err.localizedDescription
                AGToastCenter.shared.show(err.localizedDescription, kind: .error)
            } else {
                AGToastCenter.shared.show("Workout updated (delta \(xpDelta) XP).",
                                          kind: .success)
                dismiss()
            }
        }
    }
}
