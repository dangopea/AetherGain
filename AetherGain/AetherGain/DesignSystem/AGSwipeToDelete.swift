








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


            content()
                .background(AGColor.canvas)
                .offset(x: offset)
                .gesture(
                    DragGesture(minimumDistance: 12)
                        .onChanged { g in
                            dragging = true
                            let dx = g.translation.width

                            if dx <= 0 {
                                offset = max(dx, -actionWidth - 24)
                            } else {

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



    }
}
