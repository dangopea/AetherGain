//
//  WorkoutHistoryView.swift
//  AetherGain
//
//  Created by Dhriti on 1/4/2569 BE.
//

import Foundation
import SwiftUI

struct WorkoutHistoryView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var workoutVM = WorkoutViewModel()
    
    @State private var searchText = ""
    @State private var sortByDate = true  // true = date, false = type
    
    var filteredAndSortedHistory: [WorkoutSession] {
        var filtered = workoutVM.history
        
        if !searchText.isEmpty {
            filtered = filtered.filter { session in
                session.exercises.contains { exercise in
                    exercise.type.lowercased().contains(searchText.lowercased())
                }
            }
        }
        
        return filtered.sorted { session1, session2 in
            if sortByDate {
                return session1.date > session2.date
            } else {
                // Sort by first exercise type
                let type1 = session1.exercises.first?.type ?? ""
                let type2 = session2.exercises.first?.type ?? ""
                return type1 < type2
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredAndSortedHistory) { session in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(session.date, style: .date)
                                .font(.headline)
                            Spacer()
                            Text("+\(session.totalXP) XP")
                                .font(.caption.bold())
                                .foregroundColor(.green)
                        }
                        
                        ForEach(session.exercises) { exercise in
                            Text("\(exercise.type): \(exercise.sets)×\(exercise.reps) @ \(exercise.weightKG, specifier: "%.1f")kg")
                                .font(.subheadline)
                        }
                        
                        if !session.notes.isEmpty {
                            Text("Notes: \(session.notes)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .searchable(text: $searchText, prompt: "Search by exercise type")
            .navigationTitle("Workout History")
            .toolbar {
                Button(sortByDate ? "Sort by Type" : "Sort by Date") {
                    sortByDate.toggle()
                }
            }
            .onAppear {
                authVM.userDidInteract()
            }
        }
    }
}

#Preview {
    WorkoutHistoryView()
        .environmentObject(AuthViewModel())
}
