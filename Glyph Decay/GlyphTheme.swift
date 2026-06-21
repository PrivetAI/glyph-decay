import SwiftUI

// Theme-independent palette. All colours are explicit RGB so the app looks
// identical regardless of the device light/dark setting.
enum GlyphTheme {
    // Deep slate / stone backgrounds
    static let bgDeep       = Color(red: 0.06, green: 0.07, blue: 0.10)
    static let bgPanel      = Color(red: 0.10, green: 0.11, blue: 0.15)
    static let stone        = Color(red: 0.16, green: 0.17, blue: 0.22)
    static let stoneEdge    = Color(red: 0.27, green: 0.28, blue: 0.35)
    static let stoneInset   = Color(red: 0.12, green: 0.13, blue: 0.17)

    // Rune glows — ember / violet
    static let ember        = Color(red: 0.98, green: 0.55, blue: 0.22)
    static let emberDim     = Color(red: 0.55, green: 0.30, blue: 0.14)
    static let violet        = Color(red: 0.66, green: 0.42, blue: 0.96)
    static let violetDim    = Color(red: 0.36, green: 0.24, blue: 0.55)
    static let teal         = Color(red: 0.30, green: 0.78, blue: 0.74)

    // Text
    static let textPrimary  = Color(red: 0.93, green: 0.92, blue: 0.97)
    static let textMuted    = Color(red: 0.62, green: 0.63, blue: 0.72)
    static let textFaint    = Color(red: 0.42, green: 0.43, blue: 0.52)

    // States
    static let success      = Color(red: 0.40, green: 0.82, blue: 0.50)
    static let danger       = Color(red: 0.90, green: 0.34, blue: 0.38)
    static let lockGray     = Color(red: 0.30, green: 0.31, blue: 0.38)

    // Charge brightness ramp (0..maxCharge). Index 0 = empty stone.
    static func chargeColor(_ value: Int, maxCharge: Int) -> Color {
        if value <= 0 { return stoneInset }
        let t = Double(value) / Double(max(1, maxCharge))
        // interpolate ember -> bright ember
        let r = 0.45 + 0.53 * t
        let g = 0.22 + 0.40 * t
        let b = 0.14 + 0.16 * t
        return Color(red: r, green: g, blue: b)
    }

    static func targetColor(_ value: Int, maxCharge: Int) -> Color {
        if value <= 0 { return violetDim.opacity(0.35) }
        let t = Double(value) / Double(max(1, maxCharge))
        let r = 0.40 + 0.26 * t
        let g = 0.26 + 0.16 * t
        let b = 0.55 + 0.41 * t
        return Color(red: r, green: g, blue: b)
    }
}
