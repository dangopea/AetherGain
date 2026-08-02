//
//  HomeView.swift
//  AetherGain — Blade Runner HUD dashboard.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var profileVM = ProfileViewModel()
    @StateObject private var habitsVM  = HabitsViewModel()
    @StateObject private var mealVM    = MealViewModel()
    @StateObject private var workoutVM = WorkoutViewModel()

    // Derived
    private var xp: Int { profileVM.profile.xp }
    private var level: Int { GameEngine.level(for: xp) }
    private var xpForLevel: Int { max(1, level * 500 - (level - 1) * 500) }
    private var progressToNext: Double {
        let base = (level - 1) * 500
        let toNext = level * 500
        let span = max(1, toNext - base)
        return Double(xp - base) / Double(span)
    }

    private var todaysMeals: [MealEntry] {
        let start = Calendar.current.startOfDay(for: Date())
        return mealVM.meals.filter { Calendar.current.isDate($0.date, inSameDayAs: start) }
    }
    private var todaysCalories: Int { Int(todaysMeals.reduce(0) { $0 + $1.calories }) }
    private var todaysProtein: Int { Int(todaysMeals.reduce(0) { $0 + $1.protein }) }
    private var calorieTarget: Int {
        profileVM.profile.calorieTarget > 0 ? profileVM.profile.calorieTarget : 2500
    }

    private var greeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        switch h {
        case 5..<12: return "Rise, replicant"
        case 12..<17: return "Standby active"
        case 17..<22: return "Nightshift approach"
        default: return "3AM run detected"
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                hudHeader
                targetsHUD
                heroLevelCard
                quickTiles
                mealsPreviewCard
                lastWorkoutCard
                habitsMiniCard
            }
            .padding(16)
            .padding(.bottom, 60)
        }
        .background(AGColor.canvas.ignoresSafeArea())
        .overlay(AGGrid().opacity(0.35).ignoresSafeArea().allowsHitTesting(false))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("AETHERGAIN").kerning(3).font(AGFont.hud(13))
                    .foregroundColor(AGColor.amber)
            }
            ToolbarItem(placement: .topBarLeading) {
                NavigationLink { LeaderboardView() } label: {
                    Image(systemName: "trophy.fill").foregroundColor(AGColor.amber)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink { ProfileView() } label: {
                    Image(systemName: "person.crop.circle.fill").foregroundColor(AGColor.teal)
                }
            }
        }
        .onAppear { authVM.userDidInteract() }
    }

    // MARK: - HUD greeting

    private var hudHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(greeting.uppercased()).kerning(1.8).font(AGFont.hud(10))
                    .foregroundColor(AGColor.inkMuted)
                Text(profileVM.profile.name.isEmpty ? "Operator" : profileVM.profile.name)
                    .font(AGFont.display(28)).foregroundColor(AGColor.ink)
            }
            Spacer()
            AGStreakBadge(days: habitsVM.profile.streakDays)
        }
    }

    // MARK: - Targets HUD

    private var targetsHUD: some View {
        let remaining = calorieTarget - todaysCalories
        return VStack(alignment: .leading, spacing: 10) {
            AGSectionHeader(title: "Calories Remaining",
                            subtitle: "Goal − Food + Exercise")
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                col("\(calorieTarget)", "GOAL")
                sign("−")
                col("\(todaysCalories)", "FOOD", tint: AGColor.amber)
                sign("+")
                col("0", "EXERCISE")
                sign("=")
                col("\(remaining)", "REMAIN",
                    tint: remaining >= 0 ? AGColor.teal : AGColor.danger)
            }
            ProgressView(value: min(1, Double(todaysCalories) / Double(max(1, calorieTarget))))
                .tint(AGColor.amber)
            HStack(spacing: 8) {
                AGHudChip(text: "P \(todaysProtein)/\(profileVM.profile.proteinTargetG)g", tint: AGColor.teal)
                AGHudChip(text: "TDEE \(profileVM.profile.tdee) kcal", tint: AGColor.magenta)
                AGHudChip(text: profileVM.profile.fitnessGoal.rawValue.uppercased(), tint: AGColor.amber)
            }
        }
        .agCard()
    }
    private func col(_ value: String, _ label: String, tint: Color = AGColor.ink) -> some View {
        VStack(spacing: 2) {
            Text(value).font(AGFont.number(18)).foregroundColor(tint).lineLimit(1)
                .minimumScaleFactor(0.5)
            Text(label).kerning(1).font(AGFont.hud(9)).foregroundColor(AGColor.inkMuted)
        }
        .frame(maxWidth: .infinity)
    }
    private func sign(_ s: String) -> some View {
        Text(s).font(AGFont.mono(14)).foregroundColor(AGColor.inkMuted)
    }

    // MARK: - Level card

    private var heroLevelCard: some View {
        HStack(spacing: 14) {
            AGProgressRing(progress: progressToNext, color: AGColor.amber, size: 88,
                           label: "L\(level)", sublabel: "\(xp) XP")
            VStack(alignment: .leading, spacing: 6) {
                Text("LEVEL \(level)").kerning(1.4).font(AGFont.hud(11))
                    .foregroundColor(AGColor.amber)
                Text("\(GameEngine.xpForNextLevel(from: xp)) XP to L\(level + 1)")
                    .font(AGFont.body(13)).foregroundColor(AGColor.inkMuted)
                ProgressView(value: progressToNext).tint(AGColor.amber)
            }
            Spacer(minLength: 0)
        }
        .agCard()
    }

    // MARK: - Quick tiles

    private var quickTiles: some View {
        HStack(spacing: 10) {
            NavigationLink { WorkoutsHubView() } label: {
                tile(icon: "dumbbell.fill", label: "LOG WORKOUT", tint: AGColor.amber)
            }.buttonStyle(.plain)
            NavigationLink { MealLogView() } label: {
                tile(icon: "fork.knife", label: "LOG MEAL", tint: AGColor.teal)
            }.buttonStyle(.plain)
            NavigationLink { HabitsView() } label: {
                tile(icon: "drop.fill", label: "HABITS", tint: AGColor.magenta)
            }.buttonStyle(.plain)
        }
    }
    private func tile(icon: String, label: String, tint: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).foregroundColor(tint)
                .font(.system(size: 20, weight: .bold))
            Text(label).kerning(1.4).font(AGFont.hud(9)).foregroundColor(AGColor.ink)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 12).fill(AGColor.panel))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(tint.opacity(0.35), lineWidth: 1))
    }

    // MARK: - Today's meals preview

    private var mealsPreviewCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            AGSectionHeader(title: "Today's diary",
                            subtitle: todaysMeals.isEmpty ? "Nothing logged yet" : "\(todaysMeals.count) items · \(todaysCalories) kcal")
            if todaysMeals.isEmpty {
                NavigationLink { MealLogView() } label: {
                    HStack {
                        Image(systemName: "plus.circle").foregroundColor(AGColor.teal)
                        Text("Log your first meal").font(AGFont.body(13))
                            .foregroundColor(AGColor.ink)
                        Spacer()
                        Image(systemName: "arrow.right").foregroundColor(AGColor.amber)
                    }
                }
                .buttonStyle(.plain)
            } else {
                ForEach(todaysMeals.prefix(4)) { meal in
                    HStack(spacing: 10) {
                        Image(systemName: meal.mealType.icon).foregroundColor(AGColor.amber)
                            .frame(width: 20)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(meal.foodName).font(AGFont.body(14))
                                .foregroundColor(AGColor.ink).lineLimit(1)
                            Text("\(Int(meal.grams))g · \(meal.mealType.rawValue.uppercased())")
                                .kerning(1).font(AGFont.hud(9)).foregroundColor(AGColor.inkMuted)
                        }
                        Spacer()
                        Text("\(Int(meal.calories))")
                            .font(AGFont.mono(13, weight: .semibold))
                            .foregroundColor(AGColor.ink)
                    }
                }
            }
        }
        .agCard()
    }

    // MARK: - Last workout

    private var lastWorkoutCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            AGSectionHeader(title: "Last workout")
            if let last = workoutVM.history.first {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(last.date, style: .date).font(AGFont.body(14))
                            .foregroundColor(AGColor.ink)
                        Text("\(last.exercises.count) EXERCISES").kerning(1.2)
                            .font(AGFont.hud(9)).foregroundColor(AGColor.inkMuted)
                    }
                    Spacer()
                    Text("+\(last.totalXP) XP").font(AGFont.mono(14, weight: .semibold))
                        .foregroundColor(AGColor.teal)
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(Capsule().fill(AGColor.teal.opacity(0.10)))
                        .overlay(Capsule().stroke(AGColor.teal.opacity(0.35), lineWidth: 1))
                }
            } else {
                NavigationLink { WorkoutsHubView() } label: {
                    HStack {
                        Text("Start your first workout").font(AGFont.body(13))
                            .foregroundColor(AGColor.ink)
                        Spacer()
                        Image(systemName: "arrow.right").foregroundColor(AGColor.amber)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .agCard()
    }

    // MARK: - Habits mini

    private var habitsMiniCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            AGSectionHeader(title: "Habits today")
            HStack(spacing: 10) {
                AGProgressRing(progress: min(1, habitsVM.profile.dailyWaterML / max(1, habitsVM.profile.waterMLTarget)),
                               color: AGColor.teal, size: 78,
                               label: "\(Int(habitsVM.profile.dailyWaterML))",
                               sublabel: "ML / \(Int(habitsVM.profile.waterMLTarget))")
                AGProgressRing(progress: min(1, habitsVM.profile.sleepHours / max(1, habitsVM.profile.sleepHoursTarget)),
                               color: AGColor.magenta, size: 78,
                               label: String(format: "%.1f", habitsVM.profile.sleepHours),
                               sublabel: "H / \(String(format: "%.0f", habitsVM.profile.sleepHoursTarget))")
                AGProgressRing(progress: habitsVM.profile.customHabitCompletedToday ? 1 : 0,
                               color: AGColor.amber, size: 78,
                               label: habitsVM.profile.customHabitCompletedToday ? "✓" : "—",
                               sublabel: habitsVM.profile.customHabitName)
            }
        }
        .agCard()
    }
}

#Preview {
    NavigationStack { HomeView().environmentObject(AuthViewModel()) }
}
