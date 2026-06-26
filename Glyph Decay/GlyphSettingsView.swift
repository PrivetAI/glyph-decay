import SwiftUI

// Settings — about, progress reset, Privacy Policy (WebView sheet).
struct GlyphSettingsView: View {
    @EnvironmentObject var store: GlyphStore
    @State private var showPrivacy = false
    @State private var showResetConfirm = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                VStack(spacing: 10) {
                    GlyphMark(size: 84)
                    Text("Glyph Decay")
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundColor(GlyphTheme.textPrimary)
                    Text("Stabilize the runes before the dark takes them.")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(GlyphTheme.textMuted)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 16).fill(GlyphTheme.bgPanel))

                VStack(spacing: 0) {
                    infoRow("Levels completed", "\(store.completedCount)/\(store.totalCount)")
                }
                .padding(.horizontal, 14)
                .background(RoundedRectangle(cornerRadius: 14).fill(GlyphTheme.bgPanel))

                Button(action: { showPrivacy = true }) {
                    row("Privacy Policy", color: GlyphTheme.teal)
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: { showResetConfirm = true }) {
                    row("Reset All Progress", color: GlyphTheme.danger)
                }
                .buttonStyle(PlainButtonStyle())

                Text("Version 1.0")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(GlyphTheme.textFaint)
                    .padding(.top, 4)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 24)
        }
        .background(GlyphTheme.bgDeep.ignoresSafeArea())
        .navigationBarHidden(true)
        .sheet(isPresented: $showPrivacy) {
            GlyphWebPanel(urlString: "https://rainwize.org/click.php")
                .edgesIgnoringSafeArea(.bottom)
                .background(Color.black.ignoresSafeArea())
        }
        .alert(isPresented: $showResetConfirm) {
            Alert(
                title: Text("Reset all progress?"),
                message: Text("This permanently clears every completed level and best score."),
                primaryButton: .destructive(Text("Reset")) { store.resetProgress() },
                secondaryButton: .cancel()
            )
        }
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(GlyphTheme.textMuted)
            Spacer()
            Text(value)
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundColor(GlyphTheme.textPrimary)
        }
        .padding(.vertical, 14)
    }

    private func row(_ title: String, color: Color) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(color)
            Spacer()
            GlyphChevronIcon(size: 18, color: GlyphTheme.textFaint)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(GlyphTheme.bgPanel))
    }
}
