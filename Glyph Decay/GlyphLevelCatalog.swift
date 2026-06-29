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
        // -- Kindle only: learn the core loop on tiny boards --
        Spec(name: "First Ember",    rows: 2, cols: 2, maxCharge: 3, allowed: [.boost],                                 solutionLen: 2,  seed: 0xA11CE),
        Spec(name: "Twin Wards",     rows: 2, cols: 2, maxCharge: 3, allowed: [.boost],                                 solutionLen: 3,  seed: 0xB22D5),
        Spec(name: "Quiet Sigil",    rows: 2, cols: 3, maxCharge: 3, allowed: [.boost],                                 solutionLen: 3,  seed: 0xC33E6),
        // -- Surge joins --
        Spec(name: "Ashen Cross",    rows: 2, cols: 3, maxCharge: 4, allowed: [.boost, .pulse],                         solutionLen: 4,  seed: 0xD44F7),
        Spec(name: "Hollow Mark",    rows: 3, cols: 3, maxCharge: 4, allowed: [.boost, .pulse],                         solutionLen: 4,  seed: 0xE5508),
        Spec(name: "Drifting Rune",  rows: 3, cols: 3, maxCharge: 4, allowed: [.boost, .pulse],                         solutionLen: 5,  seed: 0xF6619),
        // -- Drain joins --
        Spec(name: "Ember Lattice",  rows: 3, cols: 3, maxCharge: 5, allowed: [.boost, .pulse, .siphon],                solutionLen: 6,  seed: 0x1772A),
        Spec(name: "Cinder Knot",    rows: 3, cols: 4, maxCharge: 5, allowed: [.boost, .pulse, .siphon],                solutionLen: 6,  seed: 0x2883B),
        Spec(name: "Violet Gate",    rows: 3, cols: 4, maxCharge: 5, allowed: [.boost, .pulse, .siphon],                solutionLen: 7,  seed: 0x3994C),
        Spec(name: "Stone Chorus",   rows: 4, cols: 4, maxCharge: 5, allowed: [.boost, .pulse, .siphon],                solutionLen: 8,  seed: 0x4AA5D),
        // -- Bloom joins (diagonals) --
        Spec(name: "Petal Ward",     rows: 4, cols: 4, maxCharge: 5, allowed: [.boost, .pulse, .siphon, .bloom],        solutionLen: 8,  seed: 0x5BB6E),
        Spec(name: "Corner Bloom",   rows: 4, cols: 4, maxCharge: 6, allowed: [.boost, .pulse, .siphon, .bloom],        solutionLen: 9,  seed: 0x6CC7F),
        Spec(name: "Thorn Spiral",   rows: 4, cols: 5, maxCharge: 6, allowed: [.boost, .pulse, .bloom],                 solutionLen: 9,  seed: 0x7DD80),
        Spec(name: "Lattice Veil",   rows: 4, cols: 5, maxCharge: 6, allowed: [.boost, .pulse, .siphon, .bloom],        solutionLen: 10, seed: 0x8EE91),
        Spec(name: "Glass Meridian", rows: 5, cols: 5, maxCharge: 6, allowed: [.boost, .pulse, .siphon, .bloom],        solutionLen: 10, seed: 0x9FFA2),
        // -- Quell joins (-2 single) --
        Spec(name: "Silent Hex",     rows: 5, cols: 5, maxCharge: 6, allowed: [.boost, .pulse, .siphon, .bloom, .quell],solutionLen: 11, seed: 0xA00B3),
        Spec(name: "Fading Choir",   rows: 5, cols: 5, maxCharge: 6, allowed: [.boost, .pulse, .siphon, .bloom, .quell],solutionLen: 12, seed: 0xB11C4),
        Spec(name: "Ember Cathedral",rows: 5, cols: 6, maxCharge: 7, allowed: [.boost, .pulse, .siphon, .bloom],        solutionLen: 12, seed: 0xC22D5),
        Spec(name: "Withered Crown", rows: 5, cols: 6, maxCharge: 7, allowed: [.boost, .pulse, .siphon, .bloom, .quell],solutionLen: 13, seed: 0xD33E6),
        // -- Full toolkit, large boards --
        Spec(name: "Ashfall Grid",   rows: 6, cols: 6, maxCharge: 7, allowed: [.boost, .pulse, .siphon, .bloom, .quell],solutionLen: 13, seed: 0xE44F7),
        Spec(name: "Obsidian Weave", rows: 6, cols: 6, maxCharge: 7, allowed: [.boost, .pulse, .siphon, .bloom, .quell],solutionLen: 14, seed: 0xF5508),
        Spec(name: "Runebreaker",    rows: 6, cols: 6, maxCharge: 7, allowed: [.boost, .pulse, .siphon, .bloom, .quell],solutionLen: 15, seed: 0x10619),
        Spec(name: "Last Constellation", rows: 6, cols: 6, maxCharge: 7, allowed: [.boost, .pulse, .siphon, .bloom, .quell], solutionLen: 16, seed: 0x1172A),
        Spec(name: "Final Decay",    rows: 6, cols: 6, maxCharge: 7, allowed: [.boost, .pulse, .siphon, .bloom, .quell],solutionLen: 18, seed: 0x1283B),
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
