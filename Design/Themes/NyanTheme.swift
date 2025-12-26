import SwiftUI

// MARK: - Nyan Theme (Rainbow Easter Egg)

/// Colorful, playful - rainbow aesthetic, unlockable via quest
struct NyanTheme: Theme {
    // MARK: - Identity
    let id: ThemeID = .nyan
    let name = "Nyan"
    let description = "Rainbow Neural Link"
    
    // MARK: - Theme Colors
    static let rainbowPink = Color(hex: "FF69B4")
    static let rainbowOrange = Color(hex: "FFA500")
    static let rainbowYellow = Color(hex: "FFD700")
    static let rainbowGreen = Color(hex: "32CD32")
    static let rainbowBlue = Color(hex: "1E90FF")
    
    // MARK: - Core Visual
    var mainAccent: Color { Self.rainbowYellow }
    
    /// Future rail: yellow at top (NOW), red at bottom (edge)
    var railGradient: LinearGradient {
        LinearGradient(
            colors: [
                Self.rainbowYellow,
                Self.rainbowYellow,
                DesignSystem.green,
                DesignSystem.green,
                DesignSystem.blue,
                DesignSystem.blue,
                DesignSystem.purple,
                DesignSystem.purple,
                Self.rainbowPink,
                Self.rainbowPink,
                DesignSystem.red,
                DesignSystem.red
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    /// Past rail: yellow at bottom (NOW), red at top (edge) - MIRRORED
    var pastRailGradient: LinearGradient {
        LinearGradient(
            colors: [
                DesignSystem.red,
                DesignSystem.red,
                Self.rainbowPink,
                Self.rainbowPink,
                DesignSystem.purple,
                DesignSystem.purple,
                DesignSystem.blue,
                DesignSystem.blue,
                DesignSystem.green,
                DesignSystem.green,
                Self.rainbowYellow,
                Self.rainbowYellow
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
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
                color: DesignSystem.aiAccent,
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
