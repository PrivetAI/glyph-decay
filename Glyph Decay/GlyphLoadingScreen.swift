import SwiftUI

struct GlyphLoadingScreen: View {
    @State private var glow = false
    var body: some View {
        ZStack {
            GlyphTheme.bgDeep.ignoresSafeArea()
            VStack(spacing: 22) {
                GlyphMark(size: 120)
                    .opacity(glow ? 1.0 : 0.65)
                    .scaleEffect(glow ? 1.03 : 0.97)
                Text("GLYPH DECAY")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .tracking(5)
                    .foregroundColor(GlyphTheme.textPrimary)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) { glow = true }
        }
    }
}
