






import SwiftUI
import Charts

struct AGProgressScreen: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var workoutVM = WorkoutViewModel()
    @StateObject private var mealVM = MealViewModel()
    @StateObject private var habitsVM = HabitsViewModel()
    @StateObject private var profileVM = ProfileViewModel()

    @State private var shareURL: URL?
    @State private var showShare = false

    private var stats: [DailyStat] {
        ProgressAnalytics.weeklyStats(
            workouts: workoutVM.history,
            meals: mealVM.meals,
            profile: habitsVM.profile
        )
    }
    private var heatmap: [ProgressAnalytics.HeatmapCell] {
        ProgressAnalytics.heatmap(workouts: workoutVM.history)
    }

    private var totalXPThisWeek: Int { stats.reduce(0) { $0 + $1.xp } }
    private var totalWorkouts: Int { stats.reduce(0) { $0 + $1.workouts } }
    private var avgCalories: Double {
        let logged = stats.filter { $0.calories > 0 }
        guard !logged.isEmpty else { return 0 }
        return logged.reduce(0) { $0 + $1.calories } / Double(logged.count)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                summaryCard
                heatmapCard
                xpChartCard
                workoutsChartCard
                macrosChartCard
                habitsRingsCard
                targetsCard
                exportCard
            }
            .padding(16)
            .padding(.bottom, 40)
        }
        .background(AGColor.canvas.ignoresSafeArea())
        .overlay(AGGrid().opacity(0.35).ignoresSafeArea().allowsHitTesting(false))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("PROGRESS").kerning(2).font(AGFont.hud(12))
                    .foregroundColor(AGColor.amber)
            }
        }
        .sheet(isPresented: $showShare) {
            if let url = shareURL { ShareSheet(items: [url]) }
        }
        .onAppear { authVM.userDidInteract() }
    }



    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("LAST 7 DAYS").kerning(1.6).font(AGFont.hud(10))
                        .foregroundColor(AGColor.inkMuted)
                    Text("Your trend").font(AGFont.title(22))
                        .foregroundColor(AGColor.ink)
                }
                Spacer()
                AGStreakBadge(days: habitsVM.profile.streakDays)
            }
            HStack(spacing: 8) {
                AGStatPill(icon: "star.fill", title: "XP", value: "\(totalXPThisWeek)", tint: AGColor.magenta)
                AGStatPill(icon: "dumbbell.fill", title: "Workouts", value: "\(totalWorkouts)", tint: AGColor.amber)
                AGStatPill(icon: "flame.fill", title: "Avg kcal", value: "\(Int(avgCalories))", tint: AGColor.teal)
            }
        }
        .agCard()
    }

    private var heatmapCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            AGSectionHeader(title: "Activity heatmap",
                            subtitle: "12 weeks · XP intensity per day")
            HeatmapGrid(cells: heatmap, columns: 12, rows: 7)
                .frame(height: 130)
            HStack(spacing: 4) {
                Text("LOW").font(AGFont.hud(9)).foregroundColor(AGColor.inkMuted)
                ForEach(0..<5) { i in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(AGColor.amber.opacity(0.1 + Double(i) * 0.2))
                        .frame(width: 14, height: 8)
                }
                Text("HIGH").font(AGFont.hud(9)).foregroundColor(AGColor.inkMuted)
            }
        }
        .agCard()
    }

    private var xpChartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            AGSectionHeader(title: "XP earned",
                            subtitle: "From workouts each day")
            Chart(stats) { s in
                BarMark(x: .value("Day", s.dayLabel),
                        y: .value("XP", s.xp))
                    .foregroundStyle(LinearGradient(colors: [AGColor.amberHi, AGColor.amber],
                                                    startPoint: .top, endPoint: .bottom))
                    .cornerRadius(6)
            }
            .frame(height: 160)
        }
        .agCard()
    }

    private var workoutsChartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            AGSectionHeader(title: "Workouts",
                            subtitle: "Sessions per day")
            Chart(stats) { s in
                BarMark(x: .value("Day", s.dayLabel),
                        y: .value("Count", s.workouts))
                    .foregroundStyle(AGColor.teal)
                    .cornerRadius(4)
            }
            .frame(height: 130)
        }
        .agCard()
    }

    private var macrosChartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            AGSectionHeader(title: "Macros trend")
            Chart {
                ForEach(stats) { s in
                    LineMark(x: .value("Day", s.dayLabel), y: .value("Protein", s.protein))
                        .foregroundStyle(by: .value("Macro", "Protein"))
                        .symbol(by: .value("Macro", "Protein"))
                    LineMark(x: .value("Day", s.dayLabel), y: .value("Carbs", s.carbs))
                        .foregroundStyle(by: .value("Macro", "Carbs"))
                        .symbol(by: .value("Macro", "Carbs"))
                    LineMark(x: .value("Day", s.dayLabel), y: .value("Fat", s.fat))
                        .foregroundStyle(by: .value("Macro", "Fat"))
                        .symbol(by: .value("Macro", "Fat"))
                }
            }
            .chartForegroundStyleScale([
                "Protein": AGColor.teal,
                "Carbs":   AGColor.amberHi,
                "Fat":     AGColor.magenta
            ])
            .frame(height: 180)
        }
        .agCard()
    }

    private var habitsRingsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            AGSectionHeader(title: "Today's habits")
            HStack(spacing: 12) {
                AGProgressRing(progress: min(1, habitsVM.profile.dailyWaterML / max(1, habitsVM.profile.waterMLTarget)),
                               color: AGColor.teal, size: 82,
                               label: "\(Int(habitsVM.profile.dailyWaterML))",
                               sublabel: "ML")
                AGProgressRing(progress: min(1, habitsVM.profile.sleepHours / max(1, habitsVM.profile.sleepHoursTarget)),
                               color: AGColor.magenta, size: 82,
                               label: String(format: "%.1f", habitsVM.profile.sleepHours),
                               sublabel: "H")
                AGProgressRing(progress: habitsVM.profile.customHabitCompletedToday ? 1 : 0,
                               color: AGColor.amber, size: 82,
                               label: habitsVM.profile.customHabitCompletedToday ? "✓" : "—",
                               sublabel: habitsVM.profile.customHabitName)
            }
        }
        .agCard()
    }

    private var targetsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            AGSectionHeader(title: "Daily targets",
                            subtitle: "From your BMR / TDEE calibration")
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

    private var exportCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            AGSectionHeader(title: "Export report",
                            subtitle: "Saved to Files → On My iPhone → AetherGain. Also opens Share sheet.")
            AGPushButton(title: "Export CSV", icon: "square.and.arrow.up",
                         fill: AGColor.teal, textColor: .black) {
                let csv = ProgressAnalytics.csv(from: stats)
                if let url = ProgressAnalytics.writeCSVToTemp(csv),
                   FileManager.default.fileExists(atPath: url.path) {


                    shareURL = url
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        showShare = true
                    }
                    AGToastCenter.shared.show("Report saved: \(url.lastPathComponent)", kind: .success)
                } else {
                    AGToastCenter.shared.show("Couldn't create export file.", kind: .error)
                }
            }
            if let url = shareURL {
                Text("LAST EXPORT: \(url.lastPathComponent)").kerning(1)
                    .font(AGFont.hud(9)).foregroundColor(AGColor.inkMuted)
            }
        }
        .agCard()
    }
}



private struct HeatmapGrid: View {
    let cells: [ProgressAnalytics.HeatmapCell]
    let columns: Int
    let rows: Int

    var body: some View {
        GeometryReader { geo in
            let spacing: CGFloat = 3
            let w = (geo.size.width - CGFloat(columns - 1) * spacing) / CGFloat(columns)
            let h = (geo.size.height - CGFloat(rows - 1) * spacing) / CGFloat(rows)


            HStack(spacing: spacing) {
                ForEach(0..<columns, id: \.self) { c in
                    VStack(spacing: spacing) {
                        ForEach(0..<rows, id: \.self) { r in
                            let idx = c * rows + r
                            if idx < cells.count {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(color(for: cells[idx].intensity))
                                    .frame(width: w, height: h)
                            } else {
                                Color.clear.frame(width: w, height: h)
                            }
                        }
                    }
                }
            }
        }
    }

    private func color(for intensity: Double) -> Color {
        if intensity <= 0 { return AGColor.panelHi }
        return AGColor.amber.opacity(0.15 + intensity * 0.85)
    }
}



struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack { AGProgressScreen().environmentObject(AuthViewModel()) }
}
