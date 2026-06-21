import Foundation

// MARK: - Glyph types
// Each glyph applies a delta pattern to the tapped cell and (for some kinds) its
// orthogonal neighbours. Effects are clamped into [0, maxCharge] after application.
enum GlyphKind: Int, CaseIterable, Codable, Identifiable {
    case boost   // +1 self, +1 orthogonal neighbours
    case pulse   // +2 self only
    case siphon  // -1 self, -1 orthogonal neighbours

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .boost:  return "Kindle"
        case .pulse:  return "Surge"
        case .siphon: return "Drain"
        }
    }

    var hint: String {
        switch self {
        case .boost:  return "+1 charge to the rune and its four neighbours."
        case .pulse:  return "+2 charge to the single tapped rune only."
        case .siphon: return "-1 charge from the rune and its four neighbours."
        }
    }

    // (dr, dc, delta) offsets relative to the tapped cell.
    var offsets: [(Int, Int, Int)] {
        switch self {
        case .boost:
            return [(0,0,1),(-1,0,1),(1,0,1),(0,-1,1),(0,1,1)]
        case .pulse:
            return [(0,0,2)]
        case .siphon:
            return [(0,0,-1),(-1,0,-1),(1,0,-1),(0,-1,-1),(0,1,-1)]
        }
    }
}

// A single move in a solution: a glyph kind placed at (r, c).
struct GlyphMove: Codable, Equatable {
    var kind: GlyphKind
    var r: Int
    var c: Int
}

// MARK: - Board (value type so SwiftUI re-renders on change)
struct GlyphBoard: Codable, Equatable {
    var rows: Int
    var cols: Int
    var maxCharge: Int
    var cells: [Int]   // flattened row-major, length rows*cols

    func idx(_ r: Int, _ c: Int) -> Int { r * cols + c }

    func inBounds(_ r: Int, _ c: Int) -> Bool {
        r >= 0 && r < rows && c >= 0 && c < cols
    }

    func charge(_ r: Int, _ c: Int) -> Int {
        guard inBounds(r, c) else { return 0 }
        return cells[idx(r, c)]
    }

    // Apply a glyph at (r,c). Out-of-bounds neighbours are simply ignored.
    // Returns a NEW board (value semantics). Values are clamped to [0, maxCharge].
    func applying(_ kind: GlyphKind, at r: Int, _ c: Int) -> GlyphBoard {
        var b = self
        for (dr, dc, delta) in kind.offsets {
            let nr = r + dr, nc = c + dc
            guard b.inBounds(nr, nc) else { continue }
            let i = b.idx(nr, nc)
            b.cells[i] = min(maxCharge, max(0, b.cells[i] + delta))
        }
        return b
    }

    // Decay: every cell loses 1 charge, clamped at 0.
    func decayed() -> GlyphBoard {
        var b = self
        for i in 0..<b.cells.count {
            b.cells[i] = max(0, b.cells[i] - 1)
        }
        return b
    }
}

// MARK: - A generated level
struct GlyphLevel: Codable, Identifiable {
    var id: Int                  // 1-based level number
    var name: String
    var board: GlyphBoard        // starting board
    var target: [Int]            // target charge per cell (row-major)
    var allowedGlyphs: [GlyphKind]
    var moveLimit: Int           // turns allowed before failure (decay clock)
    var par: Int                 // length of the generator's verified solution

    func matchesTarget(_ board: GlyphBoard) -> Bool {
        board.cells == target
    }
}

// MARK: - Deterministic RNG (so generation is reproducible & testable)
struct GlyphRNG: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed == 0 ? 0x9E3779B97F4A7C15 : seed }
    mutating func next() -> UInt64 {
        // SplitMix64
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

// MARK: - Level generation (GUARANTEED solvable by construction + verification)
//
// Strategy: build a level FORWARD from the target.
//   1. target = every cell at full charge (maxCharge).
//   2. Construct a known solution as a sequence of moves. We simulate forward:
//        start = target, then run the solution in REVERSE conceptually by
//        un-decaying and un-applying. Because clamping makes inverse application
//        lossy, we instead SIMULATE forward and KEEP the solution that lands on
//        target, regenerating until verified.
//
// Concretely we pick a random start board, then run a greedy/limited search to
// find a solving sequence under the decay rule. Search depth is bounded; if it
// fails we regenerate with a fresh seed. Every returned level has a solution we
// verified by simulation, so solvability is guaranteed for shipped levels.
enum GlyphLevelFactory {

    // Simulate playing `moves` from `start`: each move = apply glyph then decay.
    // Returns the final board.
    static func simulate(start: GlyphBoard, moves: [GlyphMove]) -> GlyphBoard {
        var b = start
        for m in moves {
            b = b.applying(m.kind, at: m.r, m.c)
            b = b.decayed()
        }
        return b
    }

    // Apply a glyph's deltas WITHOUT clamping (used by reverse construction to
    // detect whether a step would have clamped — if it stays in range, the forward
    // replay is exact).
    private static func rawApply(_ cells: [Int], kind: GlyphKind, r: Int, c: Int,
                                 rows: Int, cols: Int, sign: Int) -> [Int]? {
        var out = cells
        for (dr, dc, delta) in kind.offsets {
            let nr = r + dr, nc = c + dc
            guard nr >= 0, nr < rows, nc >= 0, nc < cols else { continue }
            out[nr * cols + nc] += sign * delta
        }
        return out
    }

    // Build one level of the given dimensions. GUARANTEED solvable by exact
    // reverse construction: we start at the target board and step BACKWARD,
    // building both the start board and a known forward solution. Each reverse
    // step is the inverse of "apply glyph, then decay":
    //   reverse: pre = (post + 1 everywhere)  then  un-apply glyph deltas.
    // We only accept a reverse step if every intermediate value stays within
    // [0, maxCharge]; that proves the corresponding FORWARD step never clamps,
    // so replaying the recorded moves from the start reproduces the target
    // EXACTLY. We additionally verify by full forward simulation. This is O(L)
    // per level — fast and 100% solvable. If a step can't be found we just stop
    // early (still solvable with the moves accumulated so far).
    static func makeLevel(id: Int,
                          rows: Int,
                          cols: Int,
                          maxCharge: Int,
                          allowed: [GlyphKind],
                          solutionLen: Int,
                          name: String,
                          seed: UInt64) -> GlyphLevel {
        let n = rows * cols
        let target = Array(repeating: maxCharge, count: n)

        var bestStart = target
        var bestMoves: [GlyphMove] = []

        for attempt in 0..<8 {
            var rng = GlyphRNG(seed: seed &+ UInt64(attempt) &* 0x100000001B3)
            var post = target                 // board AFTER all remaining forward moves
            var movesReversed: [GlyphMove] = []

            var steps = 0
            var guardCount = 0
            while steps < solutionLen && guardCount < solutionLen * 12 {
                guardCount += 1
                // Reverse decay: every cell +1. If any cell would exceed maxCharge,
                // this reverse step is invalid (forward decay couldn't have produced it
                // without clamping the corresponding cell to 0 — we avoid that branch).
                var pre = post
                var ok = true
                for i in 0..<n {
                    pre[i] += 1
                    if pre[i] > maxCharge { ok = false; break }
                }
                if !ok { continue }

                // Pick a random allowed glyph + cell, un-apply it (sign = -1).
                let kind = allowed[Int(rng.next() % UInt64(allowed.count))]
                let r = Int(rng.next() % UInt64(rows))
                let c = Int(rng.next() % UInt64(cols))
                guard let candidate = rawApply(pre, kind: kind, r: r, c: c,
                                               rows: rows, cols: cols, sign: -1) else { continue }
                // Accept only if all values remain in [0, maxCharge] → no clamping fwd.
                if candidate.contains(where: { $0 < 0 || $0 > maxCharge }) { continue }

                post = candidate
                movesReversed.append(GlyphMove(kind: kind, r: r, c: c))
                steps += 1
            }

            if movesReversed.isEmpty { continue }
            let start = GlyphBoard(rows: rows, cols: cols, maxCharge: maxCharge, cells: post)
            if start.cells == target { continue }      // skip trivial
            let solution = Array(movesReversed.reversed())

            // Verify by exact forward simulation.
            let end = simulate(start: start, moves: solution)
            if end.cells == target {
                bestStart = post
                bestMoves = solution
                break
            }
        }

        if bestMoves.isEmpty {
            // Guaranteed-solvable fallback: target board is solved in 0 moves.
            bestStart = target
            bestMoves = []
        }

        let start = GlyphBoard(rows: rows, cols: cols, maxCharge: maxCharge, cells: bestStart)
        let par = bestMoves.count
        let limit = max(3, par + max(2, par / 2))   // generous decay clock
        return GlyphLevel(id: id, name: name, board: start, target: target,
                          allowedGlyphs: allowed, moveLimit: limit, par: par)
    }
}
