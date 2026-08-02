//
//  WorkoutHistoryView.swift
//  AetherGain
//
//  Sessions list with header aggregates, category breakdown, search, sort,
//  and swipe-to-delete (refunds XP).
//

import SwiftUI

struct WorkoutHistoryView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var workoutVM = WorkoutViewModel()

    @State private var searchText = ""
    @State private var sortByDate = true
    @State private var sessionToDelete: WorkoutSession?
    @State private var sessionToEdit: WorkoutSession?

    // MARK: - Derived

    var filteredAndSortedHistory: [WorkoutSession] {
        var filtered = workoutVM.history
        if !searchText.isEmpty {
            filtered = filtered.filter { session in
                session.exercises.contains { $0.type.lowercased().contains(searchText.lowercased()) }
            }
        }
        return filtered.sorted { a, b in
            if sortByDate { return a.date > b.date }
            let ta = a.exercises.first?.type ?? ""
            let tb = b.exercises.first?.type ?? ""
            return ta < tb
        }
    }

    private var totalXP: Int { workoutVM.history.reduce(0) { $0 + $1.totalXP } }
    private var totalSessions: Int { workoutVM.history.count }
    private var thisWeekSessions: Int {
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return workoutVM.history.filter { $0.date >= cutoff }.count
    }
    private var categoryBreakdown: [ExerciseCategory: Int] {
        var counts: [ExerciseCategory: Int] = [.strength: 0, .cardio: 0, .mobility: 0]
        for session in workoutVM.history {
            for ex in session.exercises {
                counts[ex.category ?? .strength, default: 0] += 1
            }
        }
        return counts
    }

    var body: some View {
        VStack(spacing: 12) {
            aggregatesCard
            searchBar
            sortRow
            ScrollView {
                LazyVStack(spacing: 10) {
                    if filteredAndSortedHistory.isEmpty {
                        emptyState
                    } else {
                        ForEach(filteredAndSortedHistory) { session in
                            sessionCard(session)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
        }
        .padding(.top, 8)
        .background(AGColor.canvas.ignoresSafeArea())
        .sheet(item: $sessionToEdit) { session in
            WorkoutEditSheet(session: session, workoutVM: workoutVM)
        }
        .alert("Delete workout?", isPresented: Binding(
            get: { sessionToDelete != nil },
            set: { if !$0 { sessionToDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) { sessionToDelete = nil }
            Button("Delete", role: .destructive) {
                if let s = sessionToDelete {
                    let xp = s.totalXP
                    workoutVM.deleteSession(s)
                    AGToastCenter.shared.show("Deleted · refunded \(xp) XP", kind: .info)
                }
                sessionToDelete = nil
            }
        } message: {
            Text("This will refund the XP earned from this session.")
        }
        .onAppear { authVM.userDidInteract() }
    }

    // MARK: - Aggregates card

    private var aggregatesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("HISTORY").kerning(1.6).font(AGFont.hud(11))
                    .foregroundColor(AGColor.amber)
                Spacer()
                Text("\(totalSessions) SESSIONS")
                    .kerning(1.2).font(AGFont.hud(10))
                    .foregroundColor(AGColor.inkMuted)
            }
            HStack(spacing: 8) {
                aggregateStat(icon: "star.fill", label: "TOTAL XP",
                              value: "\(totalXP)", tint: AGColor.magenta)
                aggregateStat(icon: "calendar", label: "7 DAYS",
                              value: "\(thisWeekSessions)", tint: AGColor.teal)
                aggregateStat(icon: "flame.fill", label: "AVG XP",
                              value: totalSessions > 0 ? "\(totalXP / totalSessions)" : "0",
                              tint: AGColor.amber)
            }
            HStack(spacing: 8) {
                categoryChip(.strength, count: categoryBreakdown[.strength] ?? 0)
                categoryChip(.cardio,   count: categoryBreakdown[.cardio]   ?? 0)
                categoryChip(.mobility, count: categoryBreakdown[.mobility] ?? 0)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 14).fill(AGColor.panel))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(AGColor.stroke, lineWidth: 1))
        .padding(.horizontal, 16)
    }

    private func aggregateStat(icon: String, label: String, value: String, tint: Color) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon).foregroundColor(tint)
                Text(label).kerning(1.2).font(AGFont.hud(9))
                    .foregroundColor(AGColor.inkMuted)
            }
            Text(value).font(AGFont.number(18)).foregroundColor(AGColor.ink)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 10).fill(AGColor.panelHi))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(tint.opacity(0.3), lineWidth: 1))
    }

    private func categoryChip(_ category: ExerciseCategory, count: Int) -> some View {
        let color = colorFor(category)
        return HStack(spacing: 4) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(category.displayName.uppercased()).kerning(1.2).font(AGFont.hud(9))
                .foregroundColor(color)
            Text("\(count)").font(AGFont.mono(11, weight: .semibold))
                .foregroundColor(AGColor.ink)
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(Capsule().fill(color.opacity(0.1)))
        .overlay(Capsule().stroke(color.opacity(0.3), lineWidth: 1))
    }

    // MARK: - Search + sort

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass").foregroundColor(AGColor.inkMuted)
            TextField("Search by exercise", text: $searchText)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .font(AGFont.body(14))
                .foregroundColor(AGColor.ink)
            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundColor(AGColor.inkMuted)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 12).fill(AGColor.panel))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AGColor.stroke, lineWidth: 1))
        .padding(.horizontal, 16)
    }

    private var sortRow: some View {
        HStack {
            Text("\(filteredAndSortedHistory.count) shown")
                .font(AGFont.hud(10)).kerning(1).foregroundColor(AGColor.inkMuted)
            Spacer()
            Button {
                sortByDate.toggle()
                AGHaptics.tap()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: sortByDate ? "calendar" : "text.alignleft")
                    Text(sortByDate ? "BY DATE" : "BY TYPE").kerning(1.2)
                }
                .font(AGFont.hud(10))
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(Capsule().fill(AGColor.amber.opacity(0.15)))
                .overlay(Capsule().stroke(AGColor.amber.opacity(0.4), lineWidth: 1))
                .foregroundColor(AGColor.amber)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Session card

    private func sessionCard(_ session: WorkoutSession) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(session.date, style: .date).font(AGFont.headline(14))
                        .foregroundColor(AGColor.ink)
                    Text(session.date, style: .time)
                        .font(AGFont.hud(9)).kerning(1)
                        .foregroundColor(AGColor.inkMuted)
                }
                Spacer()
                Text("+\(session.totalXP) XP")
                    .font(AGFont.mono(13, weight: .semibold))
                    .foregroundColor(AGColor.teal)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Capsule().fill(AGColor.teal.opacity(0.1)))
                    .overlay(Capsule().stroke(AGColor.teal.opacity(0.35), lineWidth: 1))
                Button {
                    sessionToEdit = session
                    AGHaptics.tap()
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AGColor.amber)
                        .padding(6)
                        .background(RoundedRectangle(cornerRadius: 8).fill(AGColor.amber.opacity(0.10)))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(AGColor.amber.opacity(0.35), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }

            // Volume + count summary
            HStack(spacing: 6) {
                AGHudChip(text: "\(session.exercises.count) EXERCISES", tint: AGColor.amber)
                if session.exercises.contains(where: { $0.category == .strength }) {
                    let vol = strengthVolume(session)
                    AGHudChip(text: "VOL \(Int(vol)) kg", tint: AGColor.amberHi)
                }
                if session.exercises.contains(where: { $0.category == .cardio }) {
                    let mins = cardioMinutes(session)
                    AGHudChip(text: "\(Int(mins)) MIN CARDIO", tint: AGColor.teal)
                }
            }

            Divider().background(AGColor.stroke)

            ForEach(session.exercises) { exercise in
                HStack(spacing: 10) {
                    Circle().fill(colorFor(exercise.category ?? .strength))
                        .frame(width: 8, height: 8)
                    Text(exerciseSummary(exercise))
                        .font(AGFont.body(13))
                        .foregroundColor(AGColor.ink)
                    Spacer()
                }
            }
            if !session.notes.isEmpty {
                Text(session.notes)
                    .font(AGFont.body(11)).foregroundColor(AGColor.inkMuted)
                    .padding(.top, 2)
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 12).fill(AGColor.panel))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AGColor.stroke, lineWidth: 1))
        .contentShape(Rectangle())
        .onTapGesture {
            sessionToEdit = session
            AGHaptics.tap()
        }
        .contextMenu {
            Button {
                sessionToEdit = session
            } label: { Label("Edit", systemImage: "pencil") }
            Button(role: .destructive) {
                sessionToDelete = session
            } label: { Label("Delete", systemImage: "trash") }
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "dumbbell.fill").font(.system(size: 32))
                .foregroundColor(AGColor.amber.opacity(0.5))
            Text("NO WORKOUTS YET").kerning(1.6).font(AGFont.hud(11))
                .foregroundColor(AGColor.amber)
            Text("Log your first session in the Log tab.")
                .font(AGFont.body(12)).foregroundColor(AGColor.inkMuted)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 12).fill(AGColor.panel))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AGColor.stroke, lineWidth: 1))
    }

    // MARK: - Helpers

    private func colorFor(_ c: ExerciseCategory) -> Color {
        switch c {
        case .strength: return AGColor.amber
        case .cardio:   return AGColor.teal
        case .mobility: return AGColor.magenta
        }
    }

    private func strengthVolume(_ session: WorkoutSession) -> Double {
        session.exercises
            .filter { $0.category == .strength }
            .reduce(0) { $0 + Double($1.sets * $1.reps) * max($1.weightKG, 1) }
    }

    private func cardioMinutes(_ session: WorkoutSession) -> Double {
        session.exercises
            .filter { $0.category == .cardio }
            .reduce(0) { $0 + ($1.durationMinutes ?? 0) }
    }

    private func exerciseSummary(_ exercise: Exercise) -> String {
        switch exercise.category ?? .strength {
        case .strength:
            return String(format: "%@ · %dx%d @ %.1f kg",
                          exercise.type, exercise.sets, exercise.reps, exercise.weightKG)
        case .cardio:
            let d = exercise.distanceKM ?? 0
            let t = exercise.durationMinutes ?? 0
            let i = exercise.inclinePercent ?? 0
            return String(format: "%@ · %.1f km · %.0f min · %.0f%% incline",
                          exercise.type, d, t, i)
        case .mobility:
            let t = exercise.durationMinutes ?? 0
            return String(format: "%@ · %.0f min", exercise.type, t)
        }
    }
}

#Preview {
    WorkoutHistoryView().environmentObject(AuthViewModel())
}
