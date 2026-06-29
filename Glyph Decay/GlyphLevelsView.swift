import SwiftUI

// Level select — a grid of levels showing locked / completed state and best moves.
struct GlyphLevelsView: View {
    @EnvironmentObject var store: GlyphStore

    private let columns = [GridItem(.adaptive(minimum: 96), spacing: 12)]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                header
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(store.levels) { level in
                        levelCell(level)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 24)
        }
        .background(GlyphTheme.bgDeep.ignoresSafeArea())
        .navigationBarHidden(true)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Glyph Decay")
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundColor(GlyphTheme.textPrimary)
                Spacer()
                Text("\(store.completedCount)/\(store.totalCount)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(GlyphTheme.teal)
            }
            Text("Select a sigil to begin.")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(GlyphTheme.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func levelCell(_ level: GlyphLevel) -> some View {
        let unlocked = store.isUnlocked(level)
        let completed = store.progress.isCompleted(level.id)
        let best = store.progress.best(level.id)
        let stars = store.progress.stars(level.id)
        return Button(action: {
            if unlocked { store.startLevel(level) }
        }) {
            VStack(spacing: 6) {
                ZStack {
                    if !unlocked {
                        GlyphLockIcon(size: 26, color: GlyphTheme.lockGray)
                    } else if completed {
                        GlyphCheckIcon(size: 28, color: GlyphTheme.success)
                    } else {
                        Text("\(level.id)")
                            .font(.system(size: 26, weight: .heavy, design: .rounded))
                            .foregroundColor(GlyphTheme.ember)
                    }
                }
                .frame(height: 34)
                Text(level.name)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(unlocked ? GlyphTheme.textPrimary : GlyphTheme.textFaint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text("\(level.rowsText)")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(GlyphTheme.textFaint)
                if completed {
                    GlyphStarRow(count: stars, size: 13, filledColor: GlyphTheme.ember)
                        .frame(height: 14)
                } else {
                    Color.clear.frame(height: 14)
                }
                if let best = best {
                    Text("best \(best)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(GlyphTheme.teal)
                } else {
                    Text(" ")
                        .font(.system(size: 10, design: .rounded))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(GlyphTheme.bgPanel)
                    .overlay(RoundedRectangle(cornerRadius: 14)
                        .stroke(completed ? GlyphTheme.success.opacity(0.4) : GlyphTheme.stoneEdge,
                                lineWidth: 1))
            )
            .opacity(unlocked ? 1 : 0.6)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!unlocked)
    }
}

private extension GlyphLevel {
    var rowsText: String { "\(board.rows)×\(board.cols)" }
}
