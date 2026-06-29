import Foundation
import SwiftUI

// Persisted progress (Codable to a file in Application Support).
//
// SAVE SAFETY: this struct is loaded with `try? JSONDecoder()`. Synthesized
// Decodable throws if a stored key is missing, which would silently wipe an old
// save whenever we add a field. The custom init(from:) below uses
// decodeIfPresent(...) ?? default for EVERY property, so adding fields (like
// bestStars) never wipes existing progress.
struct GlyphProgress: Codable {
    // levelID -> best (fewest) moves used to win
    var bestMoves: [Int: Int] = [:]
    // set of completed level IDs
    var completed: [Int] = []
    // levelID -> best (most) stars earned (0...3)
    var bestStars: [Int: Int] = [:]

    init() {}

    enum CodingKeys: String, CodingKey {
        case bestMoves, completed, bestStars
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        bestMoves = try c.decodeIfPresent([Int: Int].self, forKey: .bestMoves) ?? [:]
        completed = try c.decodeIfPresent([Int].self, forKey: .completed) ?? []
        bestStars = try c.decodeIfPresent([Int: Int].self, forKey: .bestStars) ?? [:]
    }

    func isCompleted(_ id: Int) -> Bool { completed.contains(id) }
    func best(_ id: Int) -> Int? { bestMoves[id] }
    func stars(_ id: Int) -> Int { bestStars[id] ?? 0 }
}

// MARK: - Live play session for one level (value-type board so SwiftUI re-renders).
struct GlyphSession {
    let level: GlyphLevel
    var board: GlyphBoard
    var moves: Int
    var history: [GlyphBoard]      // snapshots for undo (board before each move)
    var historyMoveCounts: [Int]   // moves count before each undoable action
    var won: Bool
    var failed: Bool               // ran out of decay clock without matching

    init(level: GlyphLevel) {
        self.level = level
        self.board = level.board
        self.moves = 0
        self.history = []
        self.historyMoveCounts = []
        self.won = level.matchesTarget(level.board)
        self.failed = false
    }

    var movesLeft: Int { max(0, level.moveLimit - moves) }

    // 3-star rating from moves vs par:
    //   3 = solved in <= par, 2 = within par + margin, 1 = solved at all.
    static func starRating(par: Int, moves: Int) -> Int {
        let p = max(1, par)
        if moves <= p { return 3 }
        if moves <= p + max(2, p / 2) { return 2 }
        return 1
    }

    var stars: Int { won ? GlyphSession.starRating(par: level.par, moves: moves) : 0 }

    mutating func place(_ kind: GlyphKind, at r: Int, _ c: Int) {
        guard !won, !failed else { return }
        history.append(board)
        historyMoveCounts.append(moves)
        // Apply glyph, then decay (the core turn).
        board = board.applying(kind, at: r, c)
        board = board.decayed()
        moves += 1
        if level.matchesTarget(board) {
            won = true
        } else if moves >= level.moveLimit {
            failed = true
        }
    }

    mutating func undo() {
        guard let prev = history.popLast() else { return }
        let pc = historyMoveCounts.popLast() ?? max(0, moves - 1)
        board = prev
        moves = pc
        won = level.matchesTarget(board)
        failed = false
    }

    mutating func reset() {
        board = level.board
        moves = 0
        history.removeAll()
        historyMoveCounts.removeAll()
        won = level.matchesTarget(board)
        failed = false
    }

    var canUndo: Bool { !history.isEmpty }
}

// MARK: - App-wide store
final class GlyphStore: ObservableObject {
    @Published private(set) var levels: [GlyphLevel]
    @Published var progress: GlyphProgress
    @Published var session: GlyphSession?

    private let saveURL: URL

    init() {
        self.levels = GlyphLevelCatalog.makeLevels()
        let fm = FileManager.default
        let base = (try? fm.url(for: .applicationSupportDirectory, in: .userDomainMask,
                                appropriateFor: nil, create: true))
            ?? fm.temporaryDirectory
        self.saveURL = base.appendingPathComponent("glyph_decay_progress.json")
        self.progress = GlyphStore.load(from: saveURL)
    }

    // A level is unlocked if it's level 1 or the previous level is completed.
    func isUnlocked(_ level: GlyphLevel) -> Bool {
        if level.id <= 1 { return true }
        return progress.isCompleted(level.id - 1)
    }

    func startLevel(_ level: GlyphLevel) {
        session = GlyphSession(level: level)
    }

    func place(_ kind: GlyphKind, at r: Int, _ c: Int) {
        guard var s = session else { return }
        s.place(kind, at: r, c)
        session = s
        if s.won { recordWin(level: s.level, moves: s.moves) }
    }

    func undo() {
        guard var s = session else { return }
        s.undo()
        session = s
    }

    func resetLevel() {
        guard var s = session else { return }
        s.reset()
        session = s
    }

    // Advance to the next level if it exists & is now unlocked; else nil.
    func nextLevel(after level: GlyphLevel) -> GlyphLevel? {
        guard let idx = levels.firstIndex(where: { $0.id == level.id }),
              idx + 1 < levels.count else { return nil }
        return levels[idx + 1]
    }

    private func recordWin(level: GlyphLevel, moves: Int) {
        if !progress.completed.contains(level.id) {
            progress.completed.append(level.id)
        }
        if let prev = progress.bestMoves[level.id] {
            if moves < prev { progress.bestMoves[level.id] = moves }
        } else {
            progress.bestMoves[level.id] = moves
        }
        let earned = GlyphSession.starRating(par: level.par, moves: moves)
        if earned > (progress.bestStars[level.id] ?? 0) {
            progress.bestStars[level.id] = earned
        }
        save()
    }

    func resetProgress() {
        progress = GlyphProgress()
        session = nil
        save()
    }

    var completedCount: Int { progress.completed.count }
    var totalCount: Int { levels.count }

    // MARK: persistence
    private func save() {
        do {
            let data = try JSONEncoder().encode(progress)
            try data.write(to: saveURL, options: .atomic)
        } catch {
            // Non-fatal: progress just won't persist this session.
        }
    }

    private static func load(from url: URL) -> GlyphProgress {
        guard let data = try? Data(contentsOf: url),
              let p = try? JSONDecoder().decode(GlyphProgress.self, from: data) else {
            return GlyphProgress()
        }
        return p
    }
}
