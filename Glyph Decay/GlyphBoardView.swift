import SwiftUI

// Renders a GlyphBoard as a grid of charge cells. Inscribes itself within the
// supplied size using min() so it can never overflow neighbours (grid-overflow pitfall).
// `board` is a value type, so the view reliably re-renders on every change.
struct GlyphBoardView: View {
    let board: GlyphBoard
    let target: [Int]
    var interactive: Bool = true
    var onTap: (Int, Int) -> Void = { _, _ in }

    var body: some View {
        GeometryReader { geo in
            // Clamp the drawing area to the on-screen size and inscribe a square-ish grid.
            let screen = UIScreen.main.bounds.size
            let availW = min(geo.size.width, screen.width)
            let availH = min(geo.size.height, screen.height)
            let spacing: CGFloat = 6
            let cell = min(
                (availW - spacing * CGFloat(board.cols - 1)) / CGFloat(board.cols),
                (availH - spacing * CGFloat(board.rows - 1)) / CGFloat(board.rows)
            )
            let boardW = cell * CGFloat(board.cols) + spacing * CGFloat(board.cols - 1)
            let boardH = cell * CGFloat(board.rows) + spacing * CGFloat(board.rows - 1)

            VStack(spacing: spacing) {
                ForEach(0..<board.rows, id: \.self) { r in
                    HStack(spacing: spacing) {
                        ForEach(0..<board.cols, id: \.self) { c in
                            cellView(r: r, c: c, side: cell)
                        }
                    }
                }
            }
            .frame(width: boardW, height: boardH)
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private func cellView(r: Int, c: Int, side: CGFloat) -> some View {
        let value = board.charge(r, c)
        let want = target[board.idx(r, c)]
        let atTarget = value == want
        return ZStack {
            RoundedRectangle(cornerRadius: side * 0.16)
                .fill(GlyphTheme.chargeColor(value, maxCharge: board.maxCharge))
                .overlay(
                    RoundedRectangle(cornerRadius: side * 0.16)
                        .stroke(atTarget ? GlyphTheme.success.opacity(0.9) : GlyphTheme.stoneEdge,
                                lineWidth: atTarget ? 2.5 : 1)
                )
            // charge pips
            chargePips(value: value, side: side)
            // small target marker in the corner
            Text("\(want)")
                .font(.system(size: max(9, side * 0.18), weight: .bold, design: .rounded))
                .foregroundColor(GlyphTheme.violet.opacity(0.9))
                .padding(max(3, side * 0.07))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        }
        .frame(width: side, height: side)
        .contentShape(Rectangle())
        .onTapGesture {
            if interactive { onTap(r, c) }
        }
    }

    private func chargePips(value: Int, side: CGFloat) -> some View {
        let pip = max(4, side * 0.12)
        return HStack(spacing: pip * 0.5) {
            ForEach(0..<max(0, value), id: \.self) { _ in
                Circle()
                    .fill(GlyphTheme.textPrimary.opacity(0.85))
                    .frame(width: pip, height: pip)
            }
        }
    }
}
