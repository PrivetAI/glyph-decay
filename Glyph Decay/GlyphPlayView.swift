import SwiftUI

// The active puzzle screen. Shown by GlyphRootView as an overlay while a session exists.
struct GlyphPlayView: View {
    @EnvironmentObject var store: GlyphStore
    @State private var selected: GlyphKind = .boost

    var body: some View {
        ZStack {
            GlyphTheme.bgDeep.ignoresSafeArea()
            if let session = store.session {
                content(session)
                if session.won { winOverlay(session) }
                else if session.failed { failOverlay(session) }
            }
        }
        .onAppear {
            if let s = store.session { selected = s.level.allowedGlyphs.first ?? .boost }
        }
    }

    private func content(_ session: GlyphSession) -> some View {
        VStack(spacing: 0) {
            topBar(session)
            Spacer(minLength: 6)
            // Goal line
            Text("Charge every rune to its target number before the decay clock runs out.")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(GlyphTheme.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
                .padding(.bottom, 6)

            GlyphBoardView(board: session.board,
                           target: session.level.target,
                           interactive: !session.won && !session.failed) { r, c in
                store.place(selected, at: r, c)
                GlyphHaptics.tap()
                if let s = store.session, s.won { GlyphHaptics.win() }
            }
            .padding(.horizontal, 18)
            .layoutPriority(1)

            glyphPicker(session)
            actionBar(session)
        }
    }

    private func topBar(_ session: GlyphSession) -> some View {
        HStack(spacing: 12) {
            Button(action: { store.session = nil }) {
                GlyphChevronIcon(size: 20, color: GlyphTheme.textPrimary)
                    .rotationEffect(.degrees(180))
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(GlyphTheme.bgPanel))
            }
            .buttonStyle(PlainButtonStyle())

            VStack(alignment: .leading, spacing: 1) {
                Text(session.level.name)
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .foregroundColor(GlyphTheme.textPrimary)
                Text("Level \(session.level.id)")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(GlyphTheme.textFaint)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 1) {
                Text("\(session.movesLeft)")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundColor(session.movesLeft <= 2 ? GlyphTheme.danger : GlyphTheme.teal)
                Text("moves left")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(GlyphTheme.textFaint)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private func glyphPicker(_ session: GlyphSession) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 10) {
                ForEach(session.level.allowedGlyphs) { kind in
                    Button(action: { selected = kind }) {
                        VStack(spacing: 3) {
                            Text(kind.title)
                                .font(.system(size: 14, weight: .heavy, design: .rounded))
                                .foregroundColor(selected == kind ? GlyphTheme.bgDeep : GlyphTheme.textPrimary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selected == kind ? GlyphTheme.ember : GlyphTheme.bgPanel)
                                .overlay(RoundedRectangle(cornerRadius: 12)
                                    .stroke(GlyphTheme.stoneEdge, lineWidth: selected == kind ? 0 : 1))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            Text(selected.hint)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(GlyphTheme.textMuted)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private func actionBar(_ session: GlyphSession) -> some View {
        HStack(spacing: 12) {
            Button(action: { store.undo() }) {
                actionLabel("Undo", AnyView(GlyphUndoIcon(size: 22, color: session.canUndo ? GlyphTheme.textPrimary : GlyphTheme.textFaint)))
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(!session.canUndo)

            Button(action: { store.resetLevel() }) {
                actionLabel("Reset", AnyView(GlyphResetIcon(size: 22, color: GlyphTheme.textPrimary)))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 18)
    }

    private func actionLabel(_ title: String, _ icon: AnyView) -> some View {
        VStack(spacing: 4) {
            icon.frame(height: 24)
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(GlyphTheme.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 12).fill(GlyphTheme.bgPanel))
    }

    private func winOverlay(_ session: GlyphSession) -> some View {
        overlay(
            tint: GlyphTheme.success,
            title: "STABILIZED",
            stars: session.stars,
            detail: "Solved in \(session.moves) moves" + (parText(session)),
            primaryTitle: store.nextLevel(after: session.level) != nil ? "Next Level" : "Back to Levels",
            primary: {
                if let next = store.nextLevel(after: session.level), store.isUnlocked(next) {
                    store.startLevel(next)
                    selected = next.allowedGlyphs.first ?? .boost
                } else {
                    store.session = nil
                }
            },
            secondaryTitle: "Levels",
            secondary: { store.session = nil }
        )
    }

    private func parText(_ session: GlyphSession) -> String {
        session.level.par > 0 ? " (par \(session.level.par))" : ""
    }

    private func failOverlay(_ session: GlyphSession) -> some View {
        overlay(
            tint: GlyphTheme.danger,
            title: "DECAYED",
            detail: "The runes fell dark before stabilizing.",
            primaryTitle: "Try Again",
            primary: { store.resetLevel() },
            secondaryTitle: "Levels",
            secondary: { store.session = nil }
        )
    }

    private func overlay(tint: Color, title: String, stars: Int? = nil, detail: String,
                         primaryTitle: String, primary: @escaping () -> Void,
                         secondaryTitle: String, secondary: @escaping () -> Void) -> some View {
        ZStack {
            Color.black.opacity(0.7).ignoresSafeArea()
            VStack(spacing: 16) {
                GlyphMark(size: 64)
                Text(title)
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .tracking(2)
                    .foregroundColor(tint)
                if let stars = stars {
                    GlyphStarRow(count: stars, size: 34, filledColor: GlyphTheme.ember)
                }
                Text(detail)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(GlyphTheme.textMuted)
                    .multilineTextAlignment(.center)
                Button(action: primary) {
                    Text(primaryTitle)
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundColor(GlyphTheme.bgDeep)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(RoundedRectangle(cornerRadius: 14).fill(tint))
                }
                .buttonStyle(PlainButtonStyle())
                Button(action: secondary) {
                    Text(secondaryTitle)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(GlyphTheme.textMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(RoundedRectangle(cornerRadius: 12).stroke(GlyphTheme.stoneEdge, lineWidth: 1))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(26)
            .frame(maxWidth: 360)
            .background(RoundedRectangle(cornerRadius: 22).fill(GlyphTheme.bgPanel)
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(tint.opacity(0.4), lineWidth: 1)))
            .padding(.horizontal, 28)
        }
    }
}
