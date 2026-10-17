






import SwiftUI

struct HabitsView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var habitsVM = HabitsViewModel()

    @State private var reminderTime: Date = Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date()

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                streakHeader
                waterCard
                sleepCard
                customHabitCard
                reminderCard
                saveButton
            }
            .padding(16)
            .padding(.bottom, 40)
        }
        .background(AGColor.canvas.ignoresSafeArea())
        .overlay(AGGrid().opacity(0.35).ignoresSafeArea().allowsHitTesting(false))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("HABITS").kerning(2).font(AGFont.hud(12))
                    .foregroundColor(AGColor.amber)
            }
        }
        .onAppear {
            authVM.userDidInteract()
            reminderTime = Calendar.current.date(
                bySettingHour: habitsVM.profile.reminderHour,
                minute: habitsVM.profile.reminderMinute,
                second: 0, of: Date()
            ) ?? Date()
        }
    }

    private var streakProgress: Double {
        let done = [waterDone, sleepDone, habitsVM.profile.customHabitCompletedToday].filter { $0 }.count
        return Double(done) / 3.0
    }
    private var waterDone: Bool { habitsVM.profile.dailyWaterML >= habitsVM.profile.waterMLTarget * 0.8 }
    private var sleepDone: Bool { habitsVM.profile.sleepHours >= habitsVM.profile.sleepHoursTarget * 0.85 }



    private var streakHeader: some View {
        HStack(spacing: 16) {
            AGProgressRing(progress: streakProgress,
                           color: AGColor.amber, size: 88,
                           label: "\(habitsVM.profile.streakDays)",
                           sublabel: "DAY STREAK")
            VStack(alignment: .leading, spacing: 6) {
                Text("KEEP THE CHAIN ALIVE").kerning(1.4).font(AGFont.hud(10))
                    .foregroundColor(AGColor.amber)
                Text("Hit all three targets today to extend the streak by one day.")
                    .font(AGFont.body(12)).foregroundColor(AGColor.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .agCard()
    }



    private var waterCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                AGSectionHeader(title: "Water")
                Spacer()
                TextField("0", value: $habitsVM.profile.dailyWaterML, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 70)
                    .font(AGFont.mono(13, weight: .semibold))
                    .foregroundColor(AGColor.ink)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(RoundedRectangle(cornerRadius: 6).fill(AGColor.panelHi))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(AGColor.teal.opacity(0.35), lineWidth: 1))
                Text("/ \(Int(habitsVM.profile.waterMLTarget)) ml")
                    .font(AGFont.mono(11)).foregroundColor(AGColor.inkMuted)
            }

            Slider(value: $habitsVM.profile.dailyWaterML,
                   in: 0...(max(4000, habitsVM.profile.waterMLTarget * 1.5)),
                   step: 100).tint(AGColor.teal)

            HStack(spacing: 8) {
                ForEach([250, 500, 750, 1000], id: \.self) { amount in
                    Button {
                        habitsVM.profile.dailyWaterML = min(habitsVM.profile.waterMLTarget * 2,
                                                            habitsVM.profile.dailyWaterML + Double(amount))
                        AGHaptics.tap()
                    } label: {
                        Text("+\(amount)").font(AGFont.hud(10)).kerning(1)
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(RoundedRectangle(cornerRadius: 8).fill(AGColor.teal.opacity(0.10)))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(AGColor.teal.opacity(0.35), lineWidth: 1))
                            .foregroundColor(AGColor.teal)
                    }
                    .buttonStyle(.plain)
                }
            }

            targetSlider(title: "Daily target",
                         value: $habitsVM.profile.waterMLTarget,
                         range: 500...5000, step: 100,
                         format: { "\(Int($0)) ml" },
                         tint: AGColor.teal)
        }
        .agCard()
    }



    private var sleepCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                AGSectionHeader(title: "Sleep")
                Spacer()
                TextField("0", value: $habitsVM.profile.sleepHours, format: .number.precision(.fractionLength(1)))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 60)
                    .font(AGFont.mono(13, weight: .semibold))
                    .foregroundColor(AGColor.ink)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(RoundedRectangle(cornerRadius: 6).fill(AGColor.panelHi))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(AGColor.magenta.opacity(0.35), lineWidth: 1))
                Text("/ \(String(format: "%.1f", habitsVM.profile.sleepHoursTarget)) h")
                    .font(AGFont.mono(11)).foregroundColor(AGColor.inkMuted)
            }
            Slider(value: $habitsVM.profile.sleepHours, in: 0...12, step: 0.25)
                .tint(AGColor.magenta)
            targetSlider(title: "Sleep target",
                         value: $habitsVM.profile.sleepHoursTarget,
                         range: 4...12, step: 0.25,
                         format: { String(format: "%.1f h", $0) },
                         tint: AGColor.magenta)
        }
        .agCard()
    }



    private var customHabitCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                AGSectionHeader(title: "Custom habit")
                Spacer()
                Toggle("", isOn: $habitsVM.profile.customHabitCompletedToday)
                    .labelsHidden().tint(AGColor.amber)
            }
            TextField("Habit name (e.g. Meditation, Journaling)",
                      text: $habitsVM.profile.customHabitName)
                .font(AGFont.body(14))
                .foregroundColor(AGColor.ink)
                .padding(.horizontal, 12).padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 10).fill(AGColor.panelHi))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(AGColor.stroke, lineWidth: 1))
        }
        .agCard()
    }



    private var reminderCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: Binding(
                get: { habitsVM.profile.remindersEnabled },
                set: { newValue in
                    habitsVM.profile.remindersEnabled = newValue
                    habitsVM.toggleReminders(enabled: newValue)
                }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Daily reminder").font(AGFont.headline(15))
                        .foregroundColor(AGColor.ink)
                    Text("Notification to log water, sleep and your habit.")
                        .font(AGFont.body(12)).foregroundColor(AGColor.inkMuted)
                }
            }
            .tint(AGColor.amber)

            if habitsVM.profile.remindersEnabled {
                DatePicker("Time",
                           selection: $reminderTime,
                           displayedComponents: .hourAndMinute)
                    .datePickerStyle(.compact)
                    .foregroundColor(AGColor.ink)
                    .onChange(of: reminderTime) { _, new in
                        let comps = Calendar.current.dateComponents([.hour, .minute], from: new)
                        habitsVM.profile.reminderHour = comps.hour ?? 20
                        habitsVM.profile.reminderMinute = comps.minute ?? 0
                        habitsVM.saveHabits()
                        habitsVM.scheduleDailyReminder()
                    }
            }
        }
        .agCard()
    }



    private func targetSlider(title: String,
                              value: Binding<Double>,
                              range: ClosedRange<Double>,
                              step: Double,
                              format: @escaping (Double) -> String,
                              tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title.uppercased()).kerning(1.2).font(AGFont.hud(10))
                    .foregroundColor(AGColor.inkMuted)
                Spacer()
                TextField("0", value: value, format: .number.precision(.fractionLength(step < 1 ? 1 : 0)))
                    .keyboardType(step < 1 ? .decimalPad : .numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 60)
                    .font(AGFont.mono(11, weight: .semibold))
                    .foregroundColor(tint)
                    .padding(.horizontal, 6).padding(.vertical, 3)
                    .background(RoundedRectangle(cornerRadius: 6).fill(AGColor.panelHi))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(tint.opacity(0.35), lineWidth: 1))
                    .onChange(of: value.wrappedValue) { _, newVal in

                        if newVal < range.lowerBound { value.wrappedValue = range.lowerBound }
                        if newVal > range.upperBound { value.wrappedValue = range.upperBound }
                    }
            }
            Slider(value: value, in: range, step: step).tint(tint)
        }
        .padding(.top, 4)
    }



    private var saveButton: some View {
        AGPushButton(title: "Save habits", icon: "checkmark",
                     fill: AGColor.amber, textColor: .black,
                     isLoading: habitsVM.isLoading) {
            let wasStreak = habitsVM.profile.streakDays
            habitsVM.saveHabits()
            authVM.userDidInteract()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if habitsVM.profile.streakDays > wasStreak {
                    AGToastCenter.shared.show("Streak extended to \(habitsVM.profile.streakDays) days.",
                                              kind: .success, celebrate: true)
                } else if habitsVM.errorMessage == nil {
                    AGToastCenter.shared.show("Habits saved.", kind: .success)
                } else if let msg = habitsVM.errorMessage {
                    AGToastCenter.shared.show(msg, kind: .error)
                }
            }
        }
    }
}

#Preview {
    NavigationStack { HabitsView().environmentObject(AuthViewModel()) }
}
