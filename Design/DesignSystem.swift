import SwiftUI

/// Cyberpunk design system with neon colors and dark backgrounds
/// Global constants used across the application
enum DesignSystem {
    // MARK: - Background Colors
    static let backgroundPrimary = Color(hex: "050818")
    static let backgroundSecondary = Color(hex: "0a0e1a")
    static let backgroundCard = Color(hex: "1a1f2e")
    
    // MARK: - Accent Colors (used by UI components)
    static let cyan = Color(hex: "06b6d4")
    static let purple = Color(hex: "a855f7")
    static let amber = Color(hex: "eab308")
    static let green = Color(hex: "22c55e")
    static let red = Color(hex: "ef4444")
    static let lime = Color(hex: "ccff00")
    
    // MARK: - Slate Colors
    static let slate300 = Color(hex: "cbd5e1")
    static let slate400 = Color(hex: "94a3b8")
    static let slate500 = Color(hex: "64748b")
    static let slate600 = Color(hex: "475569")
    static let slate700 = Color(hex: "334155")
    static let slate800 = Color(hex: "1e293b")
    
    // MARK: - Typography
    static let monoFont = "ShareTechMono-Regular"    // Technical text, time, data
    static let displayFont = "Rajdhani-Bold"         // Large headings
    static let headlineFont = "Rajdhani-SemiBold"    // Section titles
    static let bodyFont = "Rajdhani-Medium"          // Body text, cards
    static let lightFont = "Rajdhani-Regular"        // Light text, descriptions
}

// MARK: - Color Extension for Hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
