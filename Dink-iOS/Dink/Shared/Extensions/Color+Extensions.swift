import SwiftUI

// MARK: - Hex Initializer

extension Color {
    /// Create a Color from a hex string (e.g. "#FF3B30" or "FF3B30").
    init(hex: String) {
        let sanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        Scanner(string: sanitized).scanHexInt64(&rgb)

        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - DINK Brand Palette

extension Color {

    // ── Primary ──────────────────────────────────────────────
    /// Deep navy — the core brand color. Use for headers, prominent UI, avatar fallbacks.
    static let dinkNavy = Color(red: 0.11, green: 0.17, blue: 0.30)       // #1C2B4D

    /// Vibrant teal — primary accent for interactive elements, links, icons.
    static let dinkTeal = Color(red: 0.0, green: 0.71, blue: 0.76)        // #00B5C2

    // ── Secondary ────────────────────────────────────────────
    /// Court green — for sport-related elements, success states, court surfaces.
    static let dinkGreen = Color(red: 0.30, green: 0.70, blue: 0.36)      // #4DB35C

    /// Warm orange — featured items, attention, "next session" highlights.
    static let dinkOrange = Color(red: 0.95, green: 0.48, blue: 0.20)     // #F27A33

    // ── Semantic Aliases ─────────────────────────────────────
    /// App-wide accent (used by .tint and interactive controls).
    static let dinkAccent = Color.dinkTeal

    /// Gradient pair for branded surfaces (sign-in background, hero cards).
    static let dinkGradientStart = Color.dinkNavy
    static let dinkGradientEnd = Color(red: 0.08, green: 0.12, blue: 0.22)  // darker navy

    // ── Legacy aliases (keep call-sites compiling) ───────────
    static let appGreen = Color.dinkGreen
    static let appRed = Color.red
    static let appYellow = Color.yellow
    static let appBlue = Color.dinkTeal
    static let appPurple = Color.dinkNavy  // avoid purple throughout

    /// Color for skill level (2.0-5.0 scale) — brand-aligned tones.
    static func skillLevelColor(_ level: Double) -> Color {
        switch level {
        case ..<2.5: .dinkGreen
        case 2.5..<3.5: .dinkTeal
        case 3.5..<4.5: .dinkNavy
        default: .dinkOrange
        }
    }
}

// MARK: - ShapeStyle Convenience

extension ShapeStyle where Self == Color {
    static var dinkTeal: Color { Color.dinkTeal }
    static var dinkNavy: Color { Color.dinkNavy }
    static var dinkGreen: Color { Color.dinkGreen }
    static var dinkOrange: Color { Color.dinkOrange }
}

// MARK: - Brand Gradient Convenience

extension LinearGradient {
    /// The signature DINK gradient — navy to deeper navy. Use for hero backgrounds.
    static let dinkBrand = LinearGradient(
        colors: [.dinkNavy, .dinkGradientEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// A lighter accent gradient — teal to navy. Use for avatar fallbacks, featured cards.
    static let dinkAccent = LinearGradient(
        colors: [.dinkTeal, .dinkNavy],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
