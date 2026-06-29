import Foundation

// MARK: - Glyph types
// Each glyph applies a delta pattern to the tapped cell and (for some kinds) its
// orthogonal neighbours. Effects are clamped into [0, maxCharge] after application.
enum GlyphKind: Int, CaseIterable, Codable, Identifiable {
    case boost   // +1 self, +1 orthogonal neighbours
    case pulse   // +2 self only
    case siphon  // -1 self, -1 orthogonal neighbours
    case bloom   // +1 self, +1 diagonal neighbours
    case quell   // -2 self only

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .boost:  return "Kindle"
        case .pulse:  return "Surge"
        case .siphon: return "Drain"
        case .bloom:  return "Bloom"
        case .quell:  return "Quell"
        }
    }

    var hint: String {
        switch self {
        case .boost:  return "+1 charge to the rune and its four neighbours."
        case .pulse:  return "+2 charge to the single tapped rune only."
        case .siphon: return "-1 charge from the rune and its four neighbours."
        case .bloom:  return "+1 charge to the rune and its four diagonal corners."
        case .quell:  return "-2 charge from the single tapped rune only."
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
        case .bloom:
            return [(0,0,1),(-1,-1,1),(-1,1,1),(1,-1,1),(1,1,1)]
        case .quell:
            return [(0,0,-2)]
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

// MARK: - Level generation (GUARANTEED solvable by FORWARD construction)
//
// Strategy: generate every level FORWARD so the target is DEFINED as the result
// of a known move sequence — solvability is guaranteed, never pre-solved.
//   1. Build a random START board (each cell a random value in 0...maxCharge).
//   2. Build a random SOLUTION of `solutionLen` moves (random allowed glyph at a
//      random cell each step).
//   3. target = simulate(start, solution).cells. Because the solution literally
//      produces the target, replaying it from the start always wins.
//   4. Reject trivial/degenerate boards (start == target, an all-equal target, or
//      an all-equal start) and retry with the next deterministic seed. A final
//      perturbation guarantees a non-trivial level even in the worst case.
//   5. par = solution length; moveLimit = solutionLen + a fair buffer.
// Deterministic: the same seed always yields the same level.
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

    private static func randomStart(rows: Int, cols: Int, maxCharge: Int,
                                    rng: inout GlyphRNG) -> GlyphBoard {
        let n = rows * cols
        var cells = [Int](repeating: 0, count: n)
        for i in 0..<n {
            cells[i] = Int(rng.next() % UInt64(maxCharge + 1))
        }
        return GlyphBoard(rows: rows, cols: cols, maxCharge: maxCharge, cells: cells)
    }

    private static func randomSolution(rows: Int, cols: Int, allowed: [GlyphKind],
                                       length: Int, rng: inout GlyphRNG) -> [GlyphMove] {
        var moves: [GlyphMove] = []
        for _ in 0..<max(1, length) {
            let kind = allowed[Int(rng.next() % UInt64(allowed.count))]
            let r = Int(rng.next() % UInt64(rows))
            let c = Int(rng.next() % UInt64(cols))
            moves.append(GlyphMove(kind: kind, r: r, c: c))
        }
        return moves
    }

    // Build one level of the given dimensions by forward construction.
    static func makeLevel(id: Int,
                          rows: Int,
                          cols: Int,
                          maxCharge: Int,
                          allowed: [GlyphKind],
                          solutionLen: Int,
                          name: String,
                          seed: UInt64) -> GlyphLevel {

        // Candidates: prefer a "rich" non-trivial board; keep an "acceptable"
        // (start != target) fallback in case richness is hard to hit.
        var richStart: GlyphBoard? = nil
        var richMoves: [GlyphMove] = []
        var richTarget: [Int] = []

        var okStart: GlyphBoard? = nil
        var okMoves: [GlyphMove] = []
        var okTarget: [Int] = []

        for attempt in 0..<96 {
            var rng = GlyphRNG(seed: seed &+ UInt64(attempt) &* 0x100000001B3)
            let start = randomStart(rows: rows, cols: cols, maxCharge: maxCharge, rng: &rng)
            let moves = randomSolution(rows: rows, cols: cols, allowed: allowed,
                                       length: solutionLen, rng: &rng)
            let target = simulate(start: start, moves: moves).cells

            // Must require at least one move to solve.
            if target == start.cells { continue }

            // First start!=target candidate is our safety net.
            if okStart == nil {
                okStart = start; okMoves = moves; okTarget = target
            }

            // "Rich": neither target nor start is a single repeated value.
            let targetVaried = !target.allSatisfy { $0 == target.first }
            let startVaried  = !start.cells.allSatisfy { $0 == start.cells.first }
            if targetVaried && startVaried {
                richStart = start; richMoves = moves; richTarget = target
                break
            }
        }

        var finalStart: GlyphBoard
        var finalMoves: [GlyphMove]
        var finalTarget: [Int]

        if let s = richStart {
            finalStart = s; finalMoves = richMoves; finalTarget = richTarget
        } else if let s = okStart {
            finalStart = s; finalMoves = okMoves; finalTarget = okTarget
        } else {
            // Extreme fallback: perturb a fresh start until start != target.
            var rng = GlyphRNG(seed: seed ^ 0xD1CE_F00D_BAAD_5EED)
            var start = randomStart(rows: rows, cols: cols, maxCharge: maxCharge, rng: &rng)
            let moves = randomSolution(rows: rows, cols: cols, allowed: allowed,
                                       length: solutionLen, rng: &rng)
            var target = simulate(start: start, moves: moves).cells
            var bump = 0
            while target == start.cells && bump < rows * cols {
                start.cells[bump] = (start.cells[bump] + 1) % (maxCharge + 1)
                target = simulate(start: start, moves: moves).cells
                bump += 1
            }
            finalStart = start; finalMoves = moves; finalTarget = target
        }

        let par = finalMoves.count
        let moveLimit = solutionLen + max(3, solutionLen / 2)   // fair decay clock buffer
        return GlyphLevel(id: id, name: name, board: finalStart, target: finalTarget,
                          allowedGlyphs: allowed, moveLimit: moveLimit, par: par)
    }
}
