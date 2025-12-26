import SwiftUI

// MARK: - Theme Default Implementations

extension Theme {
    // MARK: - Rails
    
    /// By default, past rail mirrors future rail
    var pastRailGradient: LinearGradient { railGradient }
    
    // MARK: - Extended Visuals
    
    /// Default card background from global design system
    var cardBackground: Color { DesignSystem.backgroundCard }
    
    /// No texture by default
    var cardTexture: Image? { nil }
    
    /// Tab bar uses main accent by default
    var tabBarTint: Color { mainAccent }
    
    /// Primary background from global design system
    var backgroundPrimary: Color { DesignSystem.backgroundPrimary }
    
    /// Secondary background from global design system
    var backgroundSecondary: Color { DesignSystem.backgroundSecondary }
    
    // MARK: - Typography
    
    /// Header font from global design system
    var headerFont: String { DesignSystem.displayFont }
    
    /// Body font from global design system
    var bodyFont: String { DesignSystem.bodyFont }
    
    /// Mono font from global design system
    var monoFont: String { DesignSystem.monoFont }
}
