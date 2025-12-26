import SwiftUI

/// Reusable view modifiers for cyberpunk aesthetic

// MARK: - Glow Modifier

struct GlowModifier: ViewModifier {
    var color: Color
    var radius: CGFloat = 8
    
    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.5), radius: radius, x: 0, y: 0)
    }
}

// MARK: - View Extensions

extension View {
    func glow(color: Color, radius: CGFloat = 8) -> some View {
        modifier(GlowModifier(color: color, radius: radius))
    }
}
