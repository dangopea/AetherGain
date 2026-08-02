//
//  AGToast.swift
//  AetherGain
//
//  App-wide toast + confetti for Criterion 10 (success/error feedback).
//

import SwiftUI
import Combine

enum AGToastKind {
    case success, error, info

    var color: Color {
        switch self {
        case .success: return AGColor.success
        case .error:   return AGColor.danger
        case .info:    return AGColor.lavender
        }
    }
    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error:   return "exclamationmark.triangle.fill"
        case .info:    return "info.circle.fill"
        }
    }
}

struct AGToast: Equatable {
    var message: String
    var kind: AGToastKind
    var id = UUID()
}

@MainActor
final class AGToastCenter: ObservableObject {
    static let shared = AGToastCenter()
    @Published var current: AGToast?
    @Published var showConfetti: Bool = false

    func show(_ message: String, kind: AGToastKind = .success, celebrate: Bool = false) {
        current = AGToast(message: message, kind: kind)
        switch kind {
        case .success: AGHaptics.success()
        case .error:   AGHaptics.error()
        case .info:    AGHaptics.tap()
        }
        if celebrate {
            showConfetti = true
            Task { [weak self] in
                try? await Task.sleep(nanoseconds: 1_600_000_000)
                self?.showConfetti = false
            }
        }
        Task { [weak self, id = current?.id] in
            try? await Task.sleep(nanoseconds: 2_400_000_000)
            if self?.current?.id == id { self?.current = nil }
        }
    }
}

struct AGToastHost: View {
    @ObservedObject var center = AGToastCenter.shared

    var body: some View {
        ZStack(alignment: .top) {
            if let t = center.current {
                HStack(spacing: 10) {
                    Image(systemName: t.kind.icon)
                        .foregroundColor(t.kind.color)
                    Text(t.message)
                        .font(AGFont.headline(14))
                        .foregroundColor(AGColor.ink)
                        .lineLimit(3)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 14).padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(AGColor.card)
                        .shadow(color: Color.black.opacity(0.10), radius: 20, x: 0, y: 8)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(t.kind.color.opacity(0.25), lineWidth: 1)
                )
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            if center.showConfetti {
                AGConfettiView()
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.75), value: center.current)
        .animation(.easeOut(duration: 0.3), value: center.showConfetti)
    }
}

// MARK: - Confetti

struct AGConfettiView: View {
    private let pieces: [ConfettiPiece] = (0..<40).map { _ in
        ConfettiPiece(
            xStart: CGFloat.random(in: 0.05...0.95),
            hue: Double.random(in: 0...1),
            delay: Double.random(in: 0...0.6),
            duration: Double.random(in: 1.3...2.0),
            rotation: Double.random(in: 0...360)
        )
    }
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(pieces) { piece in
                    ConfettiParticle(piece: piece, size: geo.size)
                }
            }
        }
    }
}

private struct ConfettiPiece: Identifiable {
    let id = UUID()
    let xStart: CGFloat
    let hue: Double
    let delay: Double
    let duration: Double
    let rotation: Double
}

private struct ConfettiParticle: View {
    let piece: ConfettiPiece
    let size: CGSize
    @State private var animate = false

    var body: some View {
        Rectangle()
            .fill(Color(hue: piece.hue, saturation: 0.75, brightness: 0.95))
            .frame(width: 9, height: 14)
            .rotationEffect(.degrees(animate ? piece.rotation + 360 : piece.rotation))
            .position(
                x: piece.xStart * size.width,
                y: animate ? size.height + 40 : -30
            )
            .onAppear {
                withAnimation(.easeIn(duration: piece.duration).delay(piece.delay)) {
                    animate = true
                }
            }
    }
}
