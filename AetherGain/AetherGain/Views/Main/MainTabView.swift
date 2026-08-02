//
//  MainTabView.swift
//  AetherGain
//
//  5 tabs: Home, Workouts, Meals, Habits, Progress.
//  Each tab is wrapped here in its own NavigationStack so child views
//  don't nest navigation stacks.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authVM: AuthViewModel

    init() {
        let tab = UITabBarAppearance()
        tab.configureWithOpaqueBackground()
        tab.backgroundColor = UIColor(AGColor.card)
        tab.stackedLayoutAppearance.selected.iconColor = UIColor(AGColor.coral)
        tab.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(AGColor.coral),
            .font: UIFont.systemFont(ofSize: 11, weight: .semibold)
        ]
        tab.stackedLayoutAppearance.normal.iconColor = UIColor(AGColor.inkMuted)
        tab.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(AGColor.inkMuted),
            .font: UIFont.systemFont(ofSize: 11, weight: .medium)
        ]
        UITabBar.appearance().standardAppearance = tab
        UITabBar.appearance().scrollEdgeAppearance = tab

        let nav = UINavigationBarAppearance()
        nav.configureWithTransparentBackground()
        nav.backgroundColor = UIColor(AGColor.canvas)
        nav.titleTextAttributes = [.foregroundColor: UIColor(AGColor.ink)]
        nav.largeTitleTextAttributes = [.foregroundColor: UIColor(AGColor.ink)]
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().compactAppearance = nav
    }

    var body: some View {
        TabView {
            NavigationStack { HomeView() }
                .tabItem { Label("Home", systemImage: "house.fill") }

            NavigationStack { WorkoutsHubView() }
                .tabItem { Label("Workouts", systemImage: "dumbbell.fill") }

            NavigationStack { MealLogView() }
                .tabItem { Label("Meals", systemImage: "fork.knife") }

            NavigationStack { HabitsView() }
                .tabItem { Label("Habits", systemImage: "drop.fill") }

            NavigationStack { AGProgressScreen() }
                .tabItem { Label("Progress", systemImage: "chart.bar.fill") }
        }
        .tint(AGColor.coral)
    }
}

// MARK: - Workouts hub

struct WorkoutsHubView: View {
    @State private var selection: Int = 0

    var body: some View {
        AGScreen {
            VStack(spacing: 12) {
                Picker("", selection: $selection) {
                    Text("Log").tag(0)
                    Text("History").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.top, 8)

                if selection == 0 {
                    LogWorkoutView()
                } else {
                    WorkoutHistoryView()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Workouts").font(AGFont.headline(17))
            }
        }
    }
}

#Preview {
    MainTabView().environmentObject(AuthViewModel())
}
