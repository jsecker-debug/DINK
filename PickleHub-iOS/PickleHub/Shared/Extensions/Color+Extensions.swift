import SwiftUI

extension Color {
    static let appGreen = Color.green
    static let appRed = Color.red
    static let appYellow = Color.yellow
    static let appBlue = Color.blue
    static let appPurple = Color.purple

    /// Color for skill level (2.0-5.0 scale)
    static func skillLevelColor(_ level: Double) -> Color {
        switch level {
        case ..<2.5: .green
        case 2.5..<3.5: .blue
        case 3.5..<4.5: .purple
        default: .red
        }
    }
}
