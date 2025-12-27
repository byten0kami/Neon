import SwiftUI

// MARK: - Nyan Theme (Rainbow Easter Egg)

/// Colorful, playful - rainbow aesthetic, unlockable via quest
struct NyanTheme: Theme {
    // MARK: - Identity
    let id: ThemeID = .nyan
    let name = "Nyan"
    let description = "Rainbow Neural Link"
    
    // MARK: - Theme Colors
    private static let rainbowPink = Color(hex: "FF69B4")
    private static let rainbowOrange = Color(hex: "FFA500")
    private static let rainbowYellow = Color(hex: "FFD700")
    private static let rainbowGreen = Color(hex: "32CD32")
    private static let rainbowBlue = Color(hex: "1E90FF")
    private static let rainbowPurple = Color(hex: "9B30FF")
    private static let rainbowRed = Color(hex: "FF4500")
    
    // MARK: - Core Visual
    var mainAccent: Color { Self.rainbowYellow }
    
    /// AI accent - Rainbow blue for playful AI
    var aiAccent: Color { Self.rainbowBlue }
    
    /// Future rail: yellow at top (NOW), red at bottom (edge)
    var railGradient: LinearGradient {
        LinearGradient(
            colors: [
                Self.rainbowYellow,
                Self.rainbowGreen,
                Self.rainbowBlue,
                Self.rainbowPurple,
                Self.rainbowPink,
                Self.rainbowRed,
                Self.rainbowYellow,
                Self.rainbowGreen,
                Self.rainbowBlue,
                Self.rainbowPurple,
                Self.rainbowPink,
                Self.rainbowRed
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    /// Past rail: yellow at bottom (NOW), red at top (edge) - MIRRORED
    var pastRailGradient: LinearGradient {
        LinearGradient(
            colors: [
                Self.rainbowRed,
                Self.rainbowPink,
                Self.rainbowPurple,
                Self.rainbowBlue,
                Self.rainbowGreen,
                Self.rainbowYellow,
                Self.rainbowRed,
                Self.rainbowPink,
                Self.rainbowPurple,
                Self.rainbowBlue,
                Self.rainbowGreen,
                Self.rainbowYellow
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    // MARK: - Typography (Playful Pixel Fonts)
    var timeFont: String { "Silkscreen-Regular" }
    var titleFont: String { "Silkscreen-Regular" }
    var bodyFont: String { "Handjet-Light" }
    var bodyFontSize: CGFloat { 20 } // Handjet is visually small, bumping size
    var tagFont: String { "Silkscreen-Regular" }
    
    // MARK: - Priority Tag Styles
    func priorityTagStyle(for priority: ItemPriority) -> PriorityTagStyle {
        switch priority {
        case .critical:
            return PriorityTagStyle(
                text: "MEOW!",
                color: Self.rainbowPink,
                hasGlow: true,
                glowRadius: 6
            )
        case .ai:
            return PriorityTagStyle(
                text: "NYAN",
                color: aiAccent,
                hasGlow: true,
                glowRadius: 4
            )
        case .high:
            return PriorityTagStyle(
                text: "PURR",
                color: Self.rainbowOrange,
                hasGlow: true,
                glowRadius: 4
            )
        case .normal:
            return PriorityTagStyle(
                text: "PAWS",
                color: Self.rainbowYellow,
                hasGlow: true,
                glowRadius: 4
            )
        case .low:
            return PriorityTagStyle(
                text: "ZZZ",
                color: Self.rainbowGreen,
                hasGlow: true,
                glowRadius: 2
            )
        }
    }
}
