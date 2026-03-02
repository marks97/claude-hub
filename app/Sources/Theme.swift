import SwiftUI

/// Claude brand design tokens for a native macOS application.
enum Theme {
    // MARK: - Brand Colors (Claude / Anthropic)

    static let orange = Color(hex: "D97757")
    static let blue = Color(hex: "6A9BCC")
    static let green = Color(hex: "788C5D")
    static let red = Color(hex: "C75450")

    // MARK: - Semantic Colors

    static let dark = Color(hex: "141413")
    static let light = Color(hex: "FAF9F5")
    static let midGray = Color(hex: "B0AEA5")
    static let lightGray = Color(hex: "E8E6DC")
    static let pampas = Color(hex: "F4F3EE")

    // MARK: - Text

    static let textPrimary = Color(hex: "141413")
    static let textSecondary = Color(hex: "6B6961")
    static let textTertiary = Color(hex: "B0AEA5")

    // MARK: - Surfaces

    static var windowBackground: Color { Color(nsColor: .windowBackgroundColor) }
    static var sidebarBackground: Color { Color(nsColor: .controlBackgroundColor) }
    static let cardBackground = Color.white
    static let cardBorder = Color(hex: "E8E6DC")

    // MARK: - Controls

    static let toggleOn = orange
    static let toggleOff = Color(hex: "E8E6DC")

    // MARK: - Dimensions

    static let cornerRadius: CGFloat = 8
    static let smallCornerRadius: CGFloat = 6
    static let windowMinWidth: CGFloat = 700
    static let windowMinHeight: CGFloat = 500
    static let sidebarWidth: CGFloat = 220
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double((rgbValue & 0x0000FF)) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
