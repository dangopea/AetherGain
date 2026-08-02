//
//  AGTheme.swift
//  AetherGain
//
//  Shared visual language: colors, typography, spacing, shadows, cards, buttons.
//

import SwiftUI

// MARK: - Palette

enum AGColor {
    // Backgrounds
    static let canvas = Color(red: 0.98, green: 0.97, blue: 0.94)   // warm cream
    static let card   = Color.white
    static let stroke = Color.black.opacity(0.06)

    // Ink
    static let ink       = Color(red: 0.10, green: 0.13, blue: 0.18)
    static let inkMuted  = Color(red: 0.40, green: 0.43, blue: 0.50)

    // Brand accents (pastel + Duolingo energy)
    static let coral    = Color(red: 1.00, green: 0.55, blue: 0.48)   // energy
    static let peach    = Color(red: 1.00, green: 0.78, blue: 0.65)
    static let mint     = Color(red: 0.55, green: 0.85, blue: 0.70)   // habits
    static let sky      = Color(red: 0.55, green: 0.80, blue: 0.98)   // water
    static let lavender = Color(red: 0.72, green: 0.68, blue: 0.98)   // xp
    static let sunshine = Color(red: 1.00, green: 0.85, blue: 0.40)   // streak
    static let rose     = Color(red: 1.00, green: 0.70, blue: 0.78)   // meals
    static let sage     = Color(red: 0.75, green: 0.87, blue: 0.72)

    // Semantic
    static let success = Color(red: 0.35, green: 0.75, blue: 0.55)
    static let warn    = Color(red: 0.95, green: 0.65, blue: 0.30)
    static let danger  = Color(red: 0.92, green: 0.42, blue: 0.42)
}

// MARK: - Typography

enum AGFont {
    static func display(_ size: CGFloat = 34) -> Font {
        .system(size: size, weight: .heavy, design: .rounded)
    }
    static func title(_ size: CGFloat = 22) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }
    static func headline(_ size: CGFloat = 17) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }
    static func body(_ size: CGFloat = 15) -> Font {
        .system(size: size, weight: .regular, design: .rounded)
    }
    static func caption(_ size: CGFloat = 12) -> Font {
        .system(size: size, weight: .medium, design: .rounded)
    }
    static func number(_ size: CGFloat = 28) -> Font {
        .system(size: size, weight: .heavy, design: .rounded)
    }
}

// MARK: - Card modifier

struct AGCardStyle: ViewModifier {
    var background: Color = AGColor.card
    var corner: CGFloat = 22
    var padded: Bool = true

    func body(content: Content) -> some View {
        content
            .padding(padded ? 16 : 0)
            .background(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(background)
            )
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .stroke(AGColor.stroke, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 6)
    }
}

extension View {
    func agCard(background: Color = AGColor.card, corner: CGFloat = 22, padded: Bool = true) -> some View {
        modifier(AGCardStyle(background: background, corner: corner, padded: padded))
    }
}

// MARK: - Duolingo-style push button

struct AGPushButton: View {
    let title: String
    var icon: String? = nil
    var fill: Color = AGColor.coral
    var textColor: Color = .white
    var isEnabled: Bool = true
    var isLoading: Bool = false
    let action: () -> Void

    @State private var pressed = false

    var body: some View {
        Button(action: {
            guard isEnabled, !isLoading else { return }
            AGHaptics.tap()
            action()
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(fill.opacity(isEnabled ? 0.9 : 0.35))
                    .offset(y: 5)

                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(fill.opacity(isEnabled ? 1 : 0.5))
                    .offset(y: pressed ? 3 : 0)
                    .overlay(
                        HStack(spacing: 8) {
                            if isLoading {
                                ProgressView().tint(textColor)
                            } else {
                                if let icon { Image(systemName: icon) }
                                Text(title)
                            }
                        }
                        .font(AGFont.headline(16))
                        .foregroundColor(textColor)
                        .offset(y: pressed ? 3 : 0)
                    )
            }
            .frame(height: 54)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled || isLoading)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in withAnimation(.easeOut(duration: 0.06)) { pressed = true } }
                .onEnded { _ in withAnimation(.easeOut(duration: 0.10)) { pressed = false } }
        )
    }
}

struct AGGhostButton: View {
    let title: String
    var icon: String? = nil
    var accent: Color = AGColor.ink
    let action: () -> Void

    var body: some View {
        Button(action: { AGHaptics.tap(); action() }) {
            HStack(spacing: 6) {
                if let icon { Image(systemName: icon) }
                Text(title)
            }
            .font(AGFont.headline(15))
            .foregroundColor(accent)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule().fill(accent.opacity(0.10))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Section header

struct AGSectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var trailing: AnyView? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(AGFont.title(20))
                    .foregroundColor(AGColor.ink)
                if let subtitle {
                    Text(subtitle).font(AGFont.caption(12))
                        .foregroundColor(AGColor.inkMuted)
                }
            }
            Spacer()
            trailing
        }
    }
}

// MARK: - Stat pill

struct AGStatPill: View {
    let icon: String
    let title: String
    let value: String
    var tint: Color = AGColor.coral

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle().fill(tint.opacity(0.18)).frame(width: 30, height: 30)
                Image(systemName: icon).font(.system(size: 14, weight: .bold))
                    .foregroundColor(tint)
            }
            VStack(alignment: .leading, spacing: 0) {
                Text(title).font(AGFont.caption(11)).foregroundColor(AGColor.inkMuted)
                Text(value).font(AGFont.headline(15)).foregroundColor(AGColor.ink)
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(Capsule().fill(AGColor.card))
        .overlay(Capsule().stroke(AGColor.stroke, lineWidth: 1))
    }
}

// MARK: - Haptics

enum AGHaptics {
    static func tap() {
        let g = UIImpactFeedbackGenerator(style: .light)
        g.impactOccurred()
    }
    static func success() {
        let g = UINotificationFeedbackGenerator()
        g.notificationOccurred(.success)
    }
    static func error() {
        let g = UINotificationFeedbackGenerator()
        g.notificationOccurred(.error)
    }
}

// MARK: - Progress ring

struct AGProgressRing: View {
    var progress: Double            // 0...1
    var color: Color = AGColor.coral
    var lineWidth: CGFloat = 10
    var size: CGFloat = 84
    var label: String? = nil
    var sublabel: String? = nil

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.18), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.001, min(1, progress)))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
            VStack(spacing: 0) {
                if let label {
                    Text(label).font(AGFont.number(18)).foregroundColor(AGColor.ink)
                }
                if let sublabel {
                    Text(sublabel).font(AGFont.caption(10)).foregroundColor(AGColor.inkMuted)
                }
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Streak flame badge

struct AGStreakBadge: View {
    let days: Int
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "flame.fill")
                .foregroundColor(AGColor.coral)
            Text("\(days)").font(AGFont.headline(15)).foregroundColor(AGColor.ink)
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(Capsule().fill(AGColor.coral.opacity(0.14)))
    }
}

// MARK: - Screen background

struct AGScreen<Content: View>: View {
    let content: () -> Content
    init(@ViewBuilder content: @escaping () -> Content) { self.content = content }
    var body: some View {
        ZStack {
            AGColor.canvas.ignoresSafeArea()
            content()
        }
    }
}
