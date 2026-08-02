//
//  AGSwipeToDelete.swift
//  AetherGain
//
//  Slide a row/card left to reveal a red delete button. Works inside a
//  vanilla VStack — no need to be inside a `List` (which would break our
//  custom card styling).
//

import SwiftUI

struct AGSwipeToDelete<Content: View>: View {
    let onDelete: () -> Void
    var actionWidth: CGFloat = 82
    var cornerRadius: CGFloat = 12
    let content: () -> Content

    @State private var offset: CGFloat = 0
    @State private var dragging: Bool = false

    var body: some View {
        ZStack(alignment: .trailing) {
            // Red delete affordance sitting behind the row.
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    offset = 0
                }
                AGHaptics.tap()
                onDelete()
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 16, weight: .bold))
                    Text("DELETE").kerning(1.2).font(AGFont.hud(9))
                }
                .foregroundColor(.white)
                .frame(width: actionWidth)
                .frame(maxHeight: .infinity)
                .background(AGColor.danger)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            }
            .buttonStyle(.plain)
            .opacity(offset < -8 ? 1 : 0)
            .allowsHitTesting(offset < -30)

            // The row itself.
            content()
                .background(AGColor.canvas) // opaque so the red doesn't bleed through
                .offset(x: offset)
                .gesture(
                    DragGesture(minimumDistance: 12)
                        .onChanged { g in
                            dragging = true
                            let dx = g.translation.width
                            // Left-only swipe. Small rubber-band past -actionWidth.
                            if dx <= 0 {
                                offset = max(dx, -actionWidth - 24)
                            } else {
                                // If already revealed, allow right-swipe to close.
                                offset = min(0, -actionWidth + dx)
                            }
                        }
                        .onEnded { g in
                            dragging = false
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                offset = offset < -actionWidth * 0.5 ? -actionWidth : 0
                            }
                        }
                )
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        // No outer onTapGesture — that would swallow taps meant for the row's
        // own tap-to-edit / tap-to-log actions. Users can close a revealed
        // swipe by dragging right, or tapping the Delete button which resets.
    }
}
