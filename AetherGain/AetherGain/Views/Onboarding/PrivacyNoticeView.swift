//
//  PrivacyNoticeView.swift
//  AetherGain
//

import SwiftUI

struct PrivacyNoticeView: View {
    @AppStorage("ag.privacy.accepted") private var accepted: Bool = false
    @AppStorage("ag.privacy.shareLeaderboard") var optInLeaderboard: Bool = false
    var onDone: () -> Void

    var body: some View {
        AGScreen {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    rightsCard(icon: "lock.shield.fill", tint: AGColor.teal,
                               title: "Encrypted",
                               body: "Every byte is encrypted in transit (HTTPS) and at rest on Google Cloud Firestore.")
                    rightsCard(icon: "person.crop.circle.badge.checkmark", tint: AGColor.amber,
                               title: "You control what's shared",
                               body: "Profile, workouts, meals, and habits stay private by default. Nothing appears on the leaderboard unless you opt in below.")
                    rightsCard(icon: "trash.circle.fill", tint: AGColor.magenta,
                               title: "Right to delete",
                               body: "Edit or delete any entry from the app. You may also request full account erasure.")
                    rightsCard(icon: "cloud.fill", tint: AGColor.amberHi,
                               title: "What we store",
                               body: "Email (login), profile info you enter, workout/meal/habit logs, XP and streaks. No location, contacts, or health data unless you connect it explicitly.")

                    Toggle(isOn: $optInLeaderboard) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Show me on the leaderboard")
                                .font(AGFont.headline(14)).foregroundColor(AGColor.ink)
                            Text("Display name, XP, level, and badges become visible to other users. Toggle any time in Profile.")
                                .font(AGFont.body(11)).foregroundColor(AGColor.inkMuted)
                        }
                    }
                    .tint(AGColor.amber)
                    .agCard()

                    AGPushButton(title: "I agree — continue", icon: "checkmark",
                                 fill: AGColor.amber, textColor: .black) {
                        accepted = true
                        onDone()
                    }
                    .padding(.top, 4)

                    Text("You are agreeing to the practices above. Revisit any time from Profile → Privacy.")
                        .font(AGFont.body(11)).foregroundColor(AGColor.inkMuted)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 30)
                }
                .padding(16)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("WELCOME").kerning(3).font(AGFont.hud(11))
                .foregroundColor(AGColor.amber)
            Text("AetherGain").font(AGFont.display(32)).foregroundColor(AGColor.ink)
            Text("Before you jack in, a quick word on your data and your rights.")
                .font(AGFont.body(13)).foregroundColor(AGColor.inkMuted)
        }
    }

    private func rightsCard(icon: String, tint: Color, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(tint.opacity(0.15))
                    .frame(width: 44, height: 44)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(tint.opacity(0.4), lineWidth: 1))
                Image(systemName: icon).font(.system(size: 18, weight: .bold))
                    .foregroundColor(tint)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title.uppercased()).kerning(1.4).font(AGFont.hud(11))
                    .foregroundColor(tint)
                Text(body).font(AGFont.body(12)).foregroundColor(AGColor.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .agCard()
    }
}

#Preview {
    PrivacyNoticeView(onDone: {})
}
