//
//  AGTheme.swift
//  AetherGain
//
//  Gamified Blade Runner 2049 visual language:
//  amber-orange primary, holographic teal secondary, near-black canvas,
//  monospaced numerals with cinematic HUD framing.
//

import SwiftUI

// MARK: - Palette

enum AGColor {
    // Backgrounds
    static let canvas   = Color(red: 0.037, green: 0.043, blue: 0.055)  // near-black w/ blue tint
    static let panel    = Color(red: 0.070, green: 0.078, blue: 0.098)  // card surface
    static let panelHi  = Color(red: 0.100, green: 0.113, blue: 0.140)  // raised card
    static let stroke   = Color.white.opacity(0.08)
    static let strokeHi = Color(red: 1.00, green: 0.55, blue: 0.18).opacity(0.35)

    // Ink
    static let ink       = Color(red: 0.965, green: 0.933, blue: 0.858) // parchment
    static let inkMuted  = Color(red: 0.60, green: 0.60, blue: 0.66)
    static let inkDim    = Color(red: 0.40, green: 0.40, blue: 0.46)

    // Primary neon
    static let amber      = Color(red: 1.00, green: 0.55, blue: 0.18)   // K's 2049 orange
    static let amberHi    = Color(red: 1.00, green: 0.72, blue: 0.42)
    static let amberLo    = Color(red: 0.55, green: 0.28, blue: 0.06)

    // Secondary neons
    static let teal       = Color(red: 0.24, green: 0.86, blue: 0.82)   // holographic
    static let magenta    = Color(red: 0.94, green: 0.36, blue: 0.85)
    static let sky        = Color(red: 0.42, green: 0.72, blue: 1.00)
    static let sage       = Color(red: 0.62, green: 0.88, blue: 0.66)

    // Semantic
    static let success = teal
    static let warn    = Color(red: 1.00, green: 0.82, blue: 0.35)
    static let danger  = Color(red: 1.00, green: 0.32, blue: 0.32)

    // Legacy aliases (keep existing views compiling until fully migrated)
    static let coral      = amber
    static let peach      = amberHi
    static let mint       = teal
    static let lavender   = magenta
    static let sunshine   = warn
    static let rose       = magenta
    static let card       = panel
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
        .system(size: size, weight: .regular, design: .default)
    }
    static func caption(_ size: CGFloat = 12) -> Font {
        .system(size: size, weight: .medium, design: .rounded)
    }
    static func mono(_ size: CGFloat = 14, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
    /// Big HUD-style numerals.
    static func number(_ size: CGFloat = 28) -> Font {
        .system(size: size, weight: .heavy, design: .monospaced)
    }
    /// Uppercase HUD label.
    static func hud(_ size: CGFloat = 10) -> Font {
        .system(size: size, weight: .semibold, design: .monospaced)
    }
}

// MARK: - Card / HUD panel modifier

struct AGCardStyle: ViewModifier {
    var background: Color = AGColor.panel
    var corner: CGFloat = 14
    var padded: Bool = true
    var glow: Color? = nil

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
            .overlay(
                // Corner bracket accents on the top-left, HUD-style.
                CornerBrackets()
                    .stroke(AGColor.amber.opacity(0.35), lineWidth: 1)
                    .allowsHitTesting(false)
            )
            .shadow(color: (glow ?? .clear).opacity(0.35), radius: 20, x: 0, y: 0)
    }
}

private struct CornerBrackets: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let len: CGFloat = 12
        let inset: CGFloat = 4
        // top-left
        p.move(to: CGPoint(x: rect.minX + inset, y: rect.minY + inset + len))
        p.addLine(to: CGPoint(x: rect.minX + inset, y: rect.minY + inset))
        p.addLine(to: CGPoint(x: rect.minX + inset + len, y: rect.minY + inset))
        // top-right
        p.move(to: CGPoint(x: rect.maxX - inset - len, y: rect.minY + inset))
        p.addLine(to: CGPoint(x: rect.maxX - inset, y: rect.minY + inset))
        p.addLine(to: CGPoint(x: rect.maxX - inset, y: rect.minY + inset + len))
        // bottom-right
        p.move(to: CGPoint(x: rect.maxX - inset, y: rect.maxY - inset - len))
        p.addLine(to: CGPoint(x: rect.maxX - inset, y: rect.maxY - inset))
        p.addLine(to: CGPoint(x: rect.maxX - inset - len, y: rect.maxY - inset))
        // bottom-left
        p.move(to: CGPoint(x: rect.minX + inset + len, y: rect.maxY - inset))
        p.addLine(to: CGPoint(x: rect.minX + inset, y: rect.maxY - inset))
        p.addLine(to: CGPoint(x: rect.minX + inset, y: rect.maxY - inset - len))
        return p
    }
}

extension View {
    func agCard(background: Color = AGColor.panel, corner: CGFloat = 14,
                padded: Bool = true, glow: Color? = nil) -> some View {
        modifier(AGCardStyle(background: background, corner: corner, padded: padded, glow: glow))
    }
}

// MARK: - Push button (HUD style with amber glow)

struct AGPushButton: View {
    let title: String
    var icon: String? = nil
    var fill: Color = AGColor.amber
    var textColor: Color = .black
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
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(fill.opacity(isEnabled ? 0.55 : 0.22))
                    .offset(y: 4)
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(fill.opacity(isEnabled ? 1 : 0.4))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.white.opacity(0.25), lineWidth: 1)
                    )
                    .offset(y: pressed ? 2 : 0)
                    .shadow(color: fill.opacity(isEnabled ? 0.55 : 0), radius: 14, x: 0, y: 0)
                    .overlay(
                        HStack(spacing: 8) {
                            if isLoading {
                                ProgressView().tint(textColor)
                            } else {
                                if let icon { Image(systemName: icon) }
                                Text(title.uppercased())
                                    .kerning(1.4)
                            }
                        }
                        .font(AGFont.headline(14))
                        .foregroundColor(textColor)
                        .offset(y: pressed ? 2 : 0)
                    )
            }
            .frame(height: 50)
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
    var accent: Color = AGColor.teal
    let action: () -> Void

    var body: some View {
        Button(action: { AGHaptics.tap(); action() }) {
            HStack(spacing: 6) {
                if let icon { Image(systemName: icon) }
                Text(title.uppercased()).kerning(1.2)
            }
            .font(AGFont.hud(11))
            .foregroundColor(accent)
            .padding(.horizontal, 14).padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(accent.opacity(0.10))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(accent.opacity(0.35), lineWidth: 1)
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
                HStack(spacing: 6) {
                    Rectangle()
                        .fill(AGColor.amber)
                        .frame(width: 3, height: 12)
                    Text(title.uppercased()).kerning(1.6)
                        .font(AGFont.hud(11))
                        .foregroundColor(AGColor.amber)
                }
                if let subtitle {
                    Text(subtitle).font(AGFont.body(12))
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
    var tint: Color = AGColor.amber

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 12, weight: .bold))
                .foregroundColor(tint)
            VStack(alignment: .leading, spacing: 0) {
                Text(title.uppercased()).kerning(1.2)
                    .font(AGFont.hud(9)).foregroundColor(AGColor.inkMuted)
                Text(value).font(AGFont.mono(13, weight: .semibold))
                    .foregroundColor(AGColor.ink)
            }
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8).fill(tint.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8).stroke(tint.opacity(0.35), lineWidth: 1)
        )
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

// MARK: - Progress ring (fixed sublabel overflow)

struct AGProgressRing: View {
    var progress: Double
    var color: Color = AGColor.amber
    var lineWidth: CGFloat = 8
    var size: CGFloat = 84
    var label: String? = nil
    var sublabel: String? = nil

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.15), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.001, min(1, progress)))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: color.opacity(0.5), radius: 6, x: 0, y: 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
            VStack(spacing: 2) {
                if let label {
                    Text(label).font(AGFont.number(min(size * 0.24, 22)))
                        .foregroundColor(color)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
                if let sublabel {
                    Text(sublabel).font(AGFont.hud(9))
                        .foregroundColor(AGColor.inkMuted)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.4)
                        .allowsTightening(true)
                        .padding(.horizontal, 2)
                }
            }
            .frame(width: size - lineWidth - 4)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Streak badge

struct AGStreakBadge: View {
    let days: Int
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "flame.fill").foregroundColor(AGColor.amber)
            Text("\(days)").font(AGFont.mono(14, weight: .heavy))
                .foregroundColor(AGColor.ink)
            Text("DAY").font(AGFont.hud(9))
                .foregroundColor(AGColor.inkMuted).kerning(1)
        }
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 8).fill(AGColor.amber.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8).stroke(AGColor.amber.opacity(0.4), lineWidth: 1)
        )
    }
}

// MARK: - Screen background with subtle grid

struct AGScreen<Content: View>: View {
    let content: () -> Content
    init(@ViewBuilder content: @escaping () -> Content) { self.content = content }
    var body: some View {
        ZStack {
            AGColor.canvas.ignoresSafeArea()
            AGGrid().opacity(0.4).ignoresSafeArea()
            content()
        }
    }
}

/// Faint dot-grid backdrop for the Blade Runner HUD feel.
struct AGGrid: View {
    var spacing: CGFloat = 24
    var body: some View {
        GeometryReader { geo in
            Canvas { ctx, size in
                let cols = Int(size.width / spacing) + 1
                let rows = Int(size.height / spacing) + 1
                for r in 0..<rows {
                    for c in 0..<cols {
                        let x = CGFloat(c) * spacing
                        let y = CGFloat(r) * spacing
                        let rect = CGRect(x: x, y: y, width: 1, height: 1)
                        ctx.fill(Path(ellipseIn: rect),
                                 with: .color(Color.white.opacity(0.06)))
                    }
                }
            }
        }
    }
}

// MARK: - Avatar

struct AGAvatar: View {
    let urlString: String?
    let initial: String
    var size: CGFloat = 44
    var tint: Color = AGColor.amber

    var body: some View {
        ZStack {
            Circle().fill(tint.opacity(0.15))
                .overlay(Circle().stroke(tint.opacity(0.5), lineWidth: 1))
            if let s = urlString, let url = URL(string: s) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:   ProgressView().tint(tint)
                    case .success(let img):
                        img.resizable().scaledToFill()
                    case .failure: fallback
                    @unknown default: fallback
                    }
                }
                .clipShape(Circle())
            } else {
                fallback
            }
        }
        .frame(width: size, height: size)
    }

    private var fallback: some View {
        Text(initial).font(AGFont.display(size * 0.42))
            .foregroundColor(tint)
    }
}

// MARK: - HUD chip

struct AGHudChip: View {
    let text: String
    var tint: Color = AGColor.teal
    var body: some View {
        Text(text.uppercased()).kerning(1.4)
            .font(AGFont.hud(10))
            .foregroundColor(tint)
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6).fill(tint.opacity(0.10))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6).stroke(tint.opacity(0.35), lineWidth: 1)
            )
    }
}
