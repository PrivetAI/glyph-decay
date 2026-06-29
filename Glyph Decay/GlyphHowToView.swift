import SwiftUI

// How to play — concise rules with small custom illustrations.
struct GlyphHowToView: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                Text("How to Play")
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundColor(GlyphTheme.textPrimary)
                    .padding(.top, 6)

                rule(title: "The Goal",
                     body: "Each rune holds a charge. Raise every rune to its target number — shown in the corner of each cell — to stabilize the board and win.")

                rule(title: "Place Glyphs",
                     body: "Tap a rune to place the selected glyph. Kindle adds +1 to a rune and its four orthogonal neighbours. Surge adds +2 to one rune. Drain removes -1 from a rune and its neighbours. Bloom adds +1 to a rune and its four diagonal corners. Quell removes -2 from one rune. New glyphs unlock as you progress.")

                rule(title: "Everything Decays",
                     body: "After every glyph you place, the whole board loses 1 charge. You must reach the target before the decay clock — your moves left — runs out.")

                rule(title: "Earn Stars",
                     body: "Each solved level scores up to three stars. Match par to earn all three; finishing with a few extra moves earns two, and any solve earns one. Replay levels to perfect your score.")

                rule(title: "Undo & Reset",
                     body: "Made a wrong move? Undo a step, or reset the level to its starting state. Every level is guaranteed solvable.")

                HStack(spacing: 14) {
                    legendChip("Charge", GlyphTheme.ember)
                    legendChip("Target", GlyphTheme.violet)
                    legendChip("Solved", GlyphTheme.success)
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 28)
        }
        .background(GlyphTheme.bgDeep.ignoresSafeArea())
        .navigationBarHidden(true)
    }

    private func rule(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundColor(GlyphTheme.ember)
            Text(body)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(GlyphTheme.textMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(GlyphTheme.bgPanel))
    }

    private func legendChip(_ label: String, _ color: Color) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 4).fill(color).frame(width: 16, height: 16)
            Text(label)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(GlyphTheme.textMuted)
        }
    }
}
