import SwiftUI

// MARK: - Priority Tag Style

/// Visual styling for priority tags on cards
/// Defines how each priority level appears within a theme
struct PriorityTagStyle: Sendable {
    let text: String
    let color: Color
    let textColor: Color?           // nil = use color
    let backgroundColor: Color?     // For inverted styles (e.g., Terminal CRIT)
    let useSystemFont: Bool         // true = SF Pro, false = monoFont
    let borderRadius: CGFloat       // 0 for hard edges
    let hasGlow: Bool               // Neon glow effect
    let glowRadius: CGFloat
    
    init(
        text: String,
        color: Color,
        textColor: Color? = nil,
        backgroundColor: Color? = nil,
        useSystemFont: Bool = false,
        borderRadius: CGFloat = CardStyle.cornerRadius,
        hasGlow: Bool = false,
        glowRadius: CGFloat = 0
    ) {
        self.text = text
        self.color = color
        self.textColor = textColor
        self.backgroundColor = backgroundColor
        self.useSystemFont = useSystemFont
        self.borderRadius = borderRadius
        self.hasGlow = hasGlow
        self.glowRadius = glowRadius
    }
}
