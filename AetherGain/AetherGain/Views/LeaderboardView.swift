//
//  LeaderboardView.swift
//  AetherGain
//

import SwiftUI

struct LeaderboardView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var leaderboardVM = LeaderboardViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                header
                if let error = leaderboardVM.errorMessage {
                    hintCard("Leaderboard could not load: " + error)
                }
                if let hint = leaderboardVM.rulesHint {
                    hintCard(hint)
                }
                if leaderboardVM.users.isEmpty {
                    emptyCard
                } else {
                    podiumCard
                    fullListCard
                }
                scoringCard
            }
            .padding(16)
            .padding(.bottom, 40)
        }
        .background(AGColor.canvas.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Leaderboard").font(AGFont.headline(17))
            }
        }
        .onAppear {
            leaderboardVM.loadLeaderboard()
            authVM.userDidInteract()
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(LinearGradient(colors: [AGColor.sunshine, AGColor.peach],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 56, height: 56)
                Image(systemName: "trophy.fill").foregroundColor(.white)
                    .font(.system(size: 24, weight: .bold))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Global XP ranking").font(AGFont.title(20))
                Text("Only users who opted in appear here.")
                    .font(AGFont.caption(12)).foregroundColor(AGColor.inkMuted)
            }
            Spacer()
        }
        .agCard()
    }

    private func hintCard(_ hint: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle.fill").foregroundColor(AGColor.amber)
            Text(hint).font(AGFont.body(12)).foregroundColor(AGColor.inkMuted)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10).fill(AGColor.amber.opacity(0.08)))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(AGColor.amber.opacity(0.3), lineWidth: 1))
    }

    private var emptyCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.3.fill").font(.system(size: 30))
                .foregroundColor(AGColor.inkMuted)
            Text("No opt-ins yet").font(AGFont.headline(15))
            Text("Toggle 'Share on leaderboard' in Profile to appear here.")
                .font(AGFont.caption(12)).foregroundColor(AGColor.inkMuted)
                .multilineTextAlignment(.center)
        }
        .padding(30)
        .frame(maxWidth: .infinity)
        .agCard()
    }

    private var podiumCard: some View {
        let top = Array(leaderboardVM.users.prefix(3))
        return HStack(alignment: .bottom, spacing: 12) {
            if top.count >= 2 {
                podiumTile(rank: 2, user: top[1], height: 92, tint: AGColor.sky)
            } else { Spacer().frame(maxWidth: .infinity) }
            if top.count >= 1 {
                podiumTile(rank: 1, user: top[0], height: 116, tint: AGColor.sunshine)
            } else { Spacer().frame(maxWidth: .infinity) }
            if top.count >= 3 {
                podiumTile(rank: 3, user: top[2], height: 76, tint: AGColor.peach)
            } else { Spacer().frame(maxWidth: .infinity) }
        }
        .padding(.vertical, 10)
        .agCard()
    }

    private func podiumTile(rank: Int, user: LeaderboardUser, height: CGFloat, tint: Color) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle().fill(tint.opacity(0.25)).frame(width: 46, height: 46)
                Text(String(user.name.prefix(1)).uppercased())
                    .font(AGFont.title(20)).foregroundColor(tint)
            }
            Text(user.name.isEmpty ? "Anon" : user.name)
                .font(AGFont.headline(12)).lineLimit(1)
            Text("\(user.xp) XP").font(AGFont.caption(11)).foregroundColor(AGColor.inkMuted)
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 12).fill(tint.opacity(0.25))
                    .frame(height: height)
                Text("\(rank)")
                    .font(AGFont.number(28))
                    .foregroundColor(tint)
                    .padding(.top, 6)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var fullListCard: some View {
        VStack(spacing: 8) {
            ForEach(Array(leaderboardVM.users.enumerated()), id: \.element.id) { index, user in
                HStack(spacing: 12) {
                    Text("\(index + 1)")
                        .font(AGFont.number(16))
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(index < 3 ? AGColor.sunshine.opacity(0.25) : AGColor.canvas))
                        .overlay(Circle().stroke(AGColor.stroke, lineWidth: 1))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(user.name.isEmpty ? "Unnamed" : user.name)
                            .font(AGFont.headline(14))
                        Text("Level \(user.level) · \(user.xp) XP · \(GameEngine.xpForNextLevel(from: user.xp)) to next")
                            .font(AGFont.caption(11)).foregroundColor(AGColor.inkMuted)
                        if !user.badges.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(user.badges) { badge in
                                        Text(badge.title)
                                            .font(AGFont.caption(10).weight(.semibold))
                                            .padding(.horizontal, 8).padding(.vertical, 3)
                                            .background(Capsule().fill(AGColor.coral.opacity(0.15)))
                                            .foregroundColor(AGColor.coral)
                                    }
                                }
                            }
                        }
                    }
                    Spacer()
                }
                .padding(.vertical, 6)
                if index < leaderboardVM.users.count - 1 {
                    Divider().background(AGColor.stroke)
                }
            }
        }
        .agCard()
    }

    private var scoringCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            AGSectionHeader(title: "How XP works")
            Text("Workouts award a base 50 XP plus bonuses: strength scales with volume, cardio with duration/distance/incline, mobility with time. Levels roll over every 500 XP. Habit streaks add 20 + 5 × streak days once all three habits are logged.")
                .font(AGFont.body(13))
                .foregroundColor(AGColor.inkMuted)
        }
        .agCard()
    }
}

#Preview {
    NavigationStack { LeaderboardView().environmentObject(AuthViewModel()) }
}
