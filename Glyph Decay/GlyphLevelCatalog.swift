import Foundation

// The shipped, ordered set of levels. Each is generated deterministically via the
// exact reverse-construction factory (GlyphLevelFactory.makeLevel) — every level is
// GUARANTEED solvable by construction and re-verified by forward simulation.
enum GlyphLevelCatalog {

    // Blueprint for one level (dimensions + difficulty knobs).
    private struct Spec {
        let name: String
        let rows: Int
        let cols: Int
        let maxCharge: Int
        let allowed: [GlyphKind]
        let solutionLen: Int
        let seed: UInt64
    }

    private static let specs: [Spec] = [
        Spec(name: "First Ember",   rows: 2, cols: 2, maxCharge: 3, allowed: [.boost],                 solutionLen: 3,  seed: 0xA11CE),
        Spec(name: "Twin Wards",    rows: 2, cols: 3, maxCharge: 3, allowed: [.boost],                 solutionLen: 4,  seed: 0xB22D5),
        Spec(name: "Quiet Sigil",   rows: 3, cols: 3, maxCharge: 3, allowed: [.boost, .pulse],         solutionLen: 5,  seed: 0xC33E6),
        Spec(name: "Ashen Cross",   rows: 3, cols: 3, maxCharge: 4, allowed: [.boost, .pulse],         solutionLen: 6,  seed: 0xD44F7),
        Spec(name: "Hollow Mark",   rows: 3, cols: 4, maxCharge: 4, allowed: [.boost, .pulse],         solutionLen: 7,  seed: 0xE5508),
        Spec(name: "Drifting Rune", rows: 4, cols: 4, maxCharge: 4, allowed: [.boost, .pulse],         solutionLen: 8,  seed: 0xF6619),
        Spec(name: "Ember Lattice", rows: 4, cols: 4, maxCharge: 5, allowed: [.boost, .pulse, .siphon],solutionLen: 9,  seed: 0x1772A),
        Spec(name: "Violet Gate",   rows: 4, cols: 5, maxCharge: 5, allowed: [.boost, .pulse, .siphon],solutionLen: 10, seed: 0x2883B),
        Spec(name: "Stone Chorus",  rows: 5, cols: 5, maxCharge: 5, allowed: [.boost, .pulse, .siphon],solutionLen: 12, seed: 0x3994C),
        Spec(name: "Final Decay",   rows: 5, cols: 5, maxCharge: 6, allowed: [.boost, .pulse, .siphon],solutionLen: 14, seed: 0x4AA5D),
    ]

    // Build the full level list. Deterministic: same output every launch.
    static func makeLevels() -> [GlyphLevel] {
        var out: [GlyphLevel] = []
        for (i, s) in specs.enumerated() {
            out.append(GlyphLevelFactory.makeLevel(
                id: i + 1,
                rows: s.rows,
                cols: s.cols,
                maxCharge: s.maxCharge,
                allowed: s.allowed,
                solutionLen: s.solutionLen,
                name: s.name,
                seed: s.seed))
        }
        return out
    }
}
