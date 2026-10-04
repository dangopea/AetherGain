//
//  MealLogView.swift
//  AetherGain
//
//  MyFitnessPal-style diary UI: meal groups (Breakfast/Lunch/Dinner/Snack),
//  Calories Remaining formula bar, per-100g reference hint, gram-aware amounts.
//

import SwiftUI
import PhotosUI

struct MealLogView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var mealVM = MealViewModel()
    @StateObject private var profileVM = ProfileViewModel()

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var previewImage: UIImage?
    @State private var showLogSheet = false
    @State private var focusedMealType: MealType = .breakfast

    /// Which day's diary we're viewing. Defaults to today; prev/next arrows adjust.
    @State private var selectedDate: Date = Calendar.current.startOfDay(for: Date())

    private let unitOptions = ["g", "kg", "ml", "cup", "tbsp", "tsp", "oz", "piece", "serving", "small", "medium", "large"]

    // MARK: - Selected-day totals

    private var mealsForSelectedDay: [MealEntry] {
        mealVM.meals.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }
    private func meals(for type: MealType) -> [MealEntry] {
        mealsForSelectedDay.filter { $0.mealType == type }
    }
    private var totalCalories: Int { Int(mealsForSelectedDay.reduce(0) { $0 + $1.calories }) }
    private var totalProtein: Int  { Int(mealsForSelectedDay.reduce(0) { $0 + $1.protein }) }
    private var totalCarbs: Int    { Int(mealsForSelectedDay.reduce(0) { $0 + $1.carbs }) }
    private var totalFat: Int      { Int(mealsForSelectedDay.reduce(0) { $0 + $1.fat }) }

    private var calorieTarget: Int {
        profileVM.profile.calorieTarget > 0 ? profileVM.profile.calorieTarget : 2500
    }

    private var isToday: Bool { Calendar.current.isDateInToday(selectedDate) }

    /// The date+time to stamp on a new meal — respects the day the user is
    /// currently viewing, so "Add food" on yesterday's diary logs to yesterday.
    private var dateForNewMeal: Date {
        if isToday { return Date() }
        // Keep the current time-of-day but on the selected calendar day.
        let cal = Calendar.current
        let now = cal.dateComponents([.hour, .minute, .second], from: Date())
        return cal.date(bySettingHour: now.hour ?? 12,
                        minute: now.minute ?? 0,
                        second: now.second ?? 0,
                        of: selectedDate) ?? selectedDate
    }
    private var isTomorrowBlocked: Bool {
        // Don't allow scrolling past today.
        Calendar.current.startOfDay(for: selectedDate) >= Calendar.current.startOfDay(for: Date())
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                dayPickerBar
                caloriesRemainingCard
                macrosDailyCard
                ForEach(MealType.allCases) { type in
                    mealSection(type: type)
                }
            }
            .padding(16)
            .padding(.bottom, 40)
        }
        .background(AGColor.canvas.ignoresSafeArea())
        .overlay(AGGrid().opacity(0.35).ignoresSafeArea().allowsHitTesting(false))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("DIARY").kerning(2).font(AGFont.hud(12))
                    .foregroundColor(AGColor.amber)
            }
        }
        .sheet(isPresented: $showLogSheet) { logSheet.agToastLayer() }
        .onAppear { authVM.userDidInteract() }
    }

    // MARK: - Calories Remaining (MyFitnessPal style formula)

    private var caloriesRemainingCard: some View {
        let remaining = calorieTarget - totalCalories

        return VStack(alignment: .leading, spacing: 12) {
            AGSectionHeader(title: "Calories Remaining", subtitle: "Goal − Food + Exercise")
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                formulaColumn(value: "\(calorieTarget)", label: "GOAL")
                sign("−")
                formulaColumn(value: "\(totalCalories)", label: "FOOD")
                sign("+")
                formulaColumn(value: "0", label: "EXERCISE")
                sign("=")
                formulaColumn(value: "\(remaining)",
                              label: "REMAINING",
                              tint: remaining >= 0 ? AGColor.teal : AGColor.danger)
            }
            ProgressView(value: min(1, max(0, Double(totalCalories) / Double(max(1, calorieTarget)))))
                .tint(AGColor.amber)
        }
        .agCard()
    }

    private func formulaColumn(value: String, label: String, tint: Color = AGColor.ink) -> some View {
        VStack(alignment: .center, spacing: 2) {
            Text(value).font(AGFont.number(20)).foregroundColor(tint).lineLimit(1)
                .minimumScaleFactor(0.5)
            Text(label).font(AGFont.hud(9)).kerning(1)
                .foregroundColor(AGColor.inkMuted)
        }
        .frame(maxWidth: .infinity)
    }
    private func sign(_ s: String) -> some View {
        Text(s).font(AGFont.mono(16, weight: .semibold)).foregroundColor(AGColor.inkMuted)
    }

    // MARK: - Macros ring row (daily)

    private var macrosDailyCard: some View {
        HStack(spacing: 14) {
            AGProgressRing(progress: ratio(totalCalories, profileVM.profile.calorieTarget),
                           color: AGColor.amber, size: 88,
                           label: "\(totalCalories)", sublabel: "KCAL")
            VStack(alignment: .leading, spacing: 8) {
                macroLine(label: "Protein", value: totalProtein,
                          target: profileVM.profile.proteinTargetG, tint: AGColor.teal)
                macroLine(label: "Carbs", value: totalCarbs,
                          target: profileVM.profile.carbsTargetG, tint: AGColor.amberHi)
                macroLine(label: "Fat",   value: totalFat,
                          target: profileVM.profile.fatTargetG, tint: AGColor.magenta)
            }
        }
        .agCard()
    }
    private func macroLine(label: String, value: Int, target: Int, tint: Color) -> some View {
        let t = max(1, target)
        return VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(label.uppercased()).kerning(1.2).font(AGFont.hud(10))
                    .foregroundColor(AGColor.inkMuted)
                Spacer()
                Text("\(value) / \(target) g").font(AGFont.mono(11))
                    .foregroundColor(AGColor.ink)
            }
            ProgressView(value: min(1, Double(value) / Double(t))).tint(tint)
        }
    }
    private func ratio(_ value: Int, _ target: Int) -> Double {
        guard target > 0 else { return 0 }
        return min(1, Double(value) / Double(target))
    }

    // MARK: - Meal sections

    private func mealSection(type: MealType) -> some View {
        let items = meals(for: type)
        let kcal = Int(items.reduce(0) { $0 + $1.calories })
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: type.icon).foregroundColor(AGColor.amber)
                Text(type.rawValue.uppercased()).kerning(1.6).font(AGFont.hud(11))
                    .foregroundColor(AGColor.amber)
                Spacer()
                Text("\(kcal) KCAL").font(AGFont.mono(11))
                    .foregroundColor(AGColor.inkMuted)
            }
            if items.isEmpty {
                Button {
                    focusedMealType = type
                    mealVM.currentMeal.mealType = type
                    mealVM.currentMeal.date = dateForNewMeal
                    showLogSheet = true
                    AGHaptics.tap()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle")
                        Text("Add food").font(AGFont.body(13))
                        Spacer()
                    }
                    .foregroundColor(AGColor.teal)
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            } else {
                ForEach(items) { entry in
                    AGSwipeToDelete(onDelete: {
                        mealVM.deleteMeal(entry)
                        AGToastCenter.shared.show("Removed \(entry.foodName)", kind: .info)
                    }) {
                        mealRow(entry)
                    }
                    Divider().background(AGColor.stroke)
                }
                Button {
                    focusedMealType = type
                    mealVM.currentMeal.mealType = type
                    mealVM.currentMeal.date = dateForNewMeal
                    showLogSheet = true
                } label: {
                    HStack {
                        Image(systemName: "plus")
                        Text("Add another").font(AGFont.body(12))
                        Spacer()
                    }
                    .foregroundColor(AGColor.teal)
                }
                .buttonStyle(.plain)
            }
        }
        .agCard()
    }

    // MARK: - Meal row (with source badge + explicit delete)

    private func mealRow(_ entry: MealEntry) -> some View {
        HStack(alignment: .center, spacing: 10) {
            Button {
                mealVM.editMeal(entry)
                focusedMealType = entry.mealType
                showLogSheet = true
                AGHaptics.tap()
            } label: {
                HStack(alignment: .top, spacing: 10) {
                    Rectangle().fill(AGColor.amber.opacity(0.5)).frame(width: 2)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(entry.foodName).font(AGFont.body(14))
                            .foregroundColor(AGColor.ink)
                        Text("\(formatted(entry.amount)) \(entry.unit) · \(Int(entry.grams)) g")
                            .font(AGFont.hud(10)).foregroundColor(AGColor.inkMuted)
                            .kerning(1)
                        sourceBadge(entry.macroSource)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(Int(entry.calories))").font(AGFont.mono(14, weight: .semibold))
                            .foregroundColor(AGColor.ink)
                        Text("KCAL").font(AGFont.hud(9)).kerning(1)
                            .foregroundColor(AGColor.inkMuted)
                    }
                }
            }
            .buttonStyle(.plain)

            Button(role: .destructive) {
                mealVM.deleteMeal(entry)
                AGToastCenter.shared.show("Removed \(entry.foodName)", kind: .info)
                AGHaptics.tap()
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AGColor.danger)
                    .padding(6)
                    .background(RoundedRectangle(cornerRadius: 8).fill(AGColor.danger.opacity(0.10)))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(AGColor.danger.opacity(0.35), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }

    private func sourceBadge(_ source: String) -> some View {
        let tint: Color = {
            switch source {
            case "Local DB":      return AGColor.teal
            case "OpenFoodFacts": return AGColor.magenta
            default:              return AGColor.inkMuted
            }
        }()
        return HStack(spacing: 4) {
            Image(systemName: source == "Manual" ? "hand.point.up.left.fill" :
                              source == "Local DB" ? "cylinder.split.1x2.fill" :
                              "globe")
                .font(.system(size: 8, weight: .bold))
            Text("SRC · \(source.uppercased())")
                .font(AGFont.hud(9)).kerning(1)
        }
        .foregroundColor(tint)
        .padding(.horizontal, 6).padding(.vertical, 2)
        .background(RoundedRectangle(cornerRadius: 5).fill(tint.opacity(0.10)))
        .overlay(RoundedRectangle(cornerRadius: 5).stroke(tint.opacity(0.35), lineWidth: 1))
    }

    private func formatted(_ v: Double) -> String {
        v == v.rounded() ? String(Int(v)) : String(format: "%.1f", v)
    }

    // MARK: - Day picker bar

    private var dayPickerBar: some View {
        HStack(spacing: 12) {
            Button {
                selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
                AGHaptics.tap()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AGColor.amber)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(AGColor.panel))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(AGColor.stroke, lineWidth: 1))
            }
            .buttonStyle(.plain)

            VStack(spacing: 2) {
                Text(isToday ? "TODAY" : selectedDate.formatted(.dateTime.weekday(.wide)).uppercased())
                    .kerning(2).font(AGFont.hud(11))
                    .foregroundColor(AGColor.amber)
                Text(selectedDate.formatted(.dateTime.day().month(.wide).year()))
                    .font(AGFont.mono(12)).foregroundColor(AGColor.ink)
            }
            .frame(maxWidth: .infinity)

            Button {
                let next = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
                let today = Calendar.current.startOfDay(for: Date())
                if next > today { return }
                selectedDate = next
                AGHaptics.tap()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(isTomorrowBlocked ? AGColor.inkDim : AGColor.amber)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(AGColor.panel))
                    .overlay(RoundedRectangle(cornerRadius: 10)
                        .stroke((isTomorrowBlocked ? AGColor.stroke : AGColor.amber.opacity(0.4)), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .disabled(isTomorrowBlocked)
        }
    }

    // MARK: - Log Sheet

    private var logSheet: some View {
        NavigationStack {
            AGScreen {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        Picker("Meal", selection: $mealVM.currentMeal.mealType) {
                            ForEach(MealType.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.segmented)

                        photoCard
                        foodNameCard
                        amountUnitCard
                        macrosCard
                        notesCard
                        saveButton
                    }
                    .padding(16)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(mealVM.editingMealID == nil ? "ADD FOOD" : "EDIT FOOD")
                        .kerning(2).font(AGFont.hud(12))
                        .foregroundColor(AGColor.amber)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        mealVM.resetCurrentMeal()
                        showLogSheet = false
                    }
                    .foregroundColor(AGColor.teal)
                }
            }
        }
        .onChange(of: selectedPhoto) { _, newItem in
            handlePhotoChange(newItem)
        }
    }

    // MARK: - Sheet cards

    private var photoCard: some View {
        VStack(spacing: 10) {
            if let previewImage {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: previewImage)
                        .resizable().scaledToFill()
                        .frame(height: 180)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12)
                            .stroke(AGColor.amber.opacity(0.4), lineWidth: 1))
                    Button {
                        self.previewImage = nil
                        self.selectedPhoto = nil
                        mealVM.clearPhotoAnalysis()
                        AGHaptics.tap()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Circle().fill(Color.black.opacity(0.7)))
                            .overlay(Circle().stroke(AGColor.danger, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .padding(8)
                }
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AGColor.panelHi)
                        .frame(height: 140)
                    VStack(spacing: 6) {
                        Image(systemName: "viewfinder").font(.system(size: 28, weight: .bold))
                            .foregroundColor(AGColor.amber)
                        Text("SNAP FOOD").kerning(2).font(AGFont.hud(10))
                            .foregroundColor(AGColor.amber)
                    }
                }
            }

            HStack(spacing: 10) {
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    HStack(spacing: 6) {
                        Image(systemName: "photo.on.rectangle.angled")
                        Text(previewImage == nil ? "CHOOSE PHOTO" : "CHANGE").kerning(1.4)
                    }
                    .font(AGFont.hud(11))
                    .foregroundColor(.black)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(AGColor.amber))
                }
                if mealVM.isAnalyzingPhoto {
                    ProgressView().tint(AGColor.amber)
                    Text("ANALYZING…").kerning(1.4).font(AGFont.hud(10))
                        .foregroundColor(AGColor.inkMuted)
                }
                Spacer()
            }

            if !mealVM.candidates.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("DETECTED · TAP TO USE").kerning(1.4).font(AGFont.hud(9))
                        .foregroundColor(AGColor.inkMuted)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(mealVM.candidates) { c in
                                Button {
                                    mealVM.selectCandidate(c)
                                    AGHaptics.tap()
                                } label: {
                                    HStack(spacing: 6) {
                                        Text(c.matched ?? c.rawLabel)
                                            .font(AGFont.hud(10)).kerning(1)
                                        Text("\(Int(c.confidence * 100))%")
                                            .font(AGFont.hud(9))
                                            .foregroundColor(AGColor.inkMuted)
                                    }
                                    .padding(.horizontal, 10).padding(.vertical, 5)
                                    .background(RoundedRectangle(cornerRadius: 8)
                                        .fill(c.matched != nil ? AGColor.teal.opacity(0.15) : AGColor.panelHi))
                                    .overlay(RoundedRectangle(cornerRadius: 8)
                                        .stroke((c.matched != nil ? AGColor.teal : AGColor.stroke), lineWidth: 1))
                                    .foregroundColor(c.matched != nil ? AGColor.teal : AGColor.ink)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
        .agCard()
    }

    private var foodNameCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            AGSectionHeader(title: "Food", subtitle: "One item OR a bowl of comma-separated items.")
            TextField("e.g. Oats · or · 100g oats, 2 cups milk, 30g protein",
                      text: $mealVM.currentMeal.foodName, axis: .vertical)
                .lineLimit(1...3)
                .font(AGFont.body(15))
                .foregroundColor(AGColor.ink)
                .padding(.horizontal, 12).padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 10).fill(AGColor.panelHi))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(AGColor.stroke, lineWidth: 1))

            Text("TIP: separate multiple items with commas to log as one bowl.")
                .kerning(1).font(AGFont.hud(9))
                .foregroundColor(AGColor.inkMuted)

            HStack(spacing: 10) {
                AGGhostButton(title: "Calculate macros", icon: "function", accent: AGColor.teal) {
                    mealVM.calculateNutritionForCurrentMeal()
                    authVM.userDidInteract()
                }
                Spacer()
            }
            if let hint = mealVM.referenceHint {
                Text(hint).font(AGFont.mono(11)).foregroundColor(AGColor.teal)
                    .padding(.top, 2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let err = mealVM.errorMessage {
                Text(err).font(AGFont.body(12)).foregroundColor(AGColor.danger)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .agCard()
    }

    private var amountUnitCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            AGSectionHeader(title: "Amount",
                            subtitle: "e.g. 30 g, 1 cup, 2 pieces — macros scale automatically.")
            HStack(spacing: 10) {
                TextField("Amount", value: $mealVM.currentMeal.amount, format: .number)
                    .keyboardType(.decimalPad)
                    .font(AGFont.number(22))
                    .foregroundColor(AGColor.ink)
                    .padding(.horizontal, 12).padding(.vertical, 10)
                    .frame(width: 110)
                    .background(RoundedRectangle(cornerRadius: 10).fill(AGColor.panelHi))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(AGColor.stroke, lineWidth: 1))
                    .onChange(of: mealVM.currentMeal.amount) { _, _ in mealVM.recalculateFromCurrent() }

                Menu {
                    ForEach(unitOptions, id: \.self) { u in
                        Button(u) {
                            mealVM.currentMeal.unit = u
                            mealVM.recalculateFromCurrent()
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(mealVM.currentMeal.unit.uppercased()).kerning(1.4)
                        Image(systemName: "chevron.down").font(.system(size: 10, weight: .bold))
                    }
                    .font(AGFont.hud(11))
                    .foregroundColor(AGColor.amber)
                    .padding(.horizontal, 12).padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 10).fill(AGColor.panelHi))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(AGColor.amber.opacity(0.4), lineWidth: 1))
                }
                Spacer()
                Text("= \(Int(mealVM.currentMeal.grams)) g")
                    .font(AGFont.mono(13)).foregroundColor(AGColor.inkMuted)
            }
        }
        .agCard()
    }

    private var macrosCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            AGSectionHeader(title: "Macros for this entry")
            HStack(spacing: 12) {
                AGProgressRing(progress: min(1, mealVM.currentMeal.calories / 1000),
                               color: AGColor.amber, size: 92,
                               label: "\(Int(mealVM.currentMeal.calories))",
                               sublabel: "KCAL")
                VStack(alignment: .leading, spacing: 10) {
                    editableMacroRow(name: "Protein", tint: AGColor.teal,
                                     value: Binding(get: { mealVM.currentMeal.protein },
                                                    set: { mealVM.currentMeal.protein = $0 }))
                    editableMacroRow(name: "Carbs", tint: AGColor.amberHi,
                                     value: Binding(get: { mealVM.currentMeal.carbs },
                                                    set: { mealVM.currentMeal.carbs = $0 }))
                    editableMacroRow(name: "Fat", tint: AGColor.magenta,
                                     value: Binding(get: { mealVM.currentMeal.fat },
                                                    set: { mealVM.currentMeal.fat = $0 }))
                }
            }
        }
        .agCard()
    }

    private func editableMacroRow(name: String, tint: Color, value: Binding<Double>) -> some View {
        HStack {
            Circle().fill(tint).frame(width: 8, height: 8)
            Text(name.uppercased()).kerning(1.2).font(AGFont.hud(10))
                .foregroundColor(AGColor.inkMuted)
            Spacer()
            TextField("g", value: value, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 60)
                .font(AGFont.mono(13))
                .foregroundColor(AGColor.ink)
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(RoundedRectangle(cornerRadius: 8).fill(AGColor.panelHi))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(AGColor.stroke, lineWidth: 1))
            Text("g").font(AGFont.hud(10)).foregroundColor(AGColor.inkMuted)
        }
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            AGSectionHeader(title: "Notes")
            TextField("Optional", text: $mealVM.currentMeal.notes)
                .font(AGFont.body(14))
                .foregroundColor(AGColor.ink)
                .padding(.horizontal, 12).padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 10).fill(AGColor.panelHi))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(AGColor.stroke, lineWidth: 1))
        }
        .agCard()
    }

    private var saveButton: some View {
        let editing = mealVM.editingMealID != nil
        return AGPushButton(
            title: editing
                ? "Update \(mealVM.currentMeal.mealType.rawValue.uppercased())"
                : "Log to \(mealVM.currentMeal.mealType.rawValue.uppercased())",
            icon: "checkmark",
            fill: AGColor.amber,
            textColor: .black,
            isEnabled: !mealVM.currentMeal.foodName.isEmpty && mealVM.currentMeal.calories > 0,
            isLoading: mealVM.isLoading
        ) {
            let foodName = mealVM.currentMeal.foodName
            let mealType = mealVM.currentMeal.mealType
            mealVM.saveMeal()
            authVM.userDidInteract()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                if mealVM.errorMessage == nil {
                    AGToastCenter.shared.show(
                        editing ? "Updated \(foodName)" : "Logged \(foodName) → \(mealType.rawValue)",
                        kind: .success
                    )
                    previewImage = nil
                    selectedPhoto = nil
                    showLogSheet = false
                } else if let msg = mealVM.errorMessage {
                    AGToastCenter.shared.show(msg, kind: .error)
                }
            }
        }
    }

    // MARK: - Photo change handler

    private func handlePhotoChange(_ newItem: PhotosPickerItem?) {
        Task {
            guard let newItem else { return }
            do {
                if let data = try await newItem.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    await MainActor.run {
                        self.previewImage = uiImage
                    }
                    mealVM.analyzeMealPhoto(uiImage)
                } else {
                    await MainActor.run {
                        mealVM.errorMessage = "Couldn't read that image — try another."
                    }
                }
            } catch {
                await MainActor.run {
                    mealVM.errorMessage = "Photo load failed: \(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    NavigationStack { MealLogView().environmentObject(AuthViewModel()) }
}
