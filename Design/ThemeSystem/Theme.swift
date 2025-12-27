import SwiftUI

// MARK: - Theme Protocol

/// Protocol defining a complete visual theme
/// Themes are pure visual configurations with no business logic
protocol Theme: Identifiable, Sendable {
    // MARK: - Identity
    var id: ThemeID { get }
    var name: String { get }
    var description: String { get }
    
    // MARK: - Core Visual
    var mainAccent: Color { get }
    var aiAccent: Color { get }
    var railGradient: LinearGradient { get }
    var pastRailGradient: LinearGradient { get }
    
    // MARK: - Typography
    var timeFont: String { get }    // Technical text, time, data
    var titleFont: String { get }   // Large headings, task titles
    var bodyFont: String { get }    // Body text, descriptions
    var bodyFontSize: CGFloat { get } // Font size for body text
    var tagFont: String { get }     // Tags, buttons, labels
    
    // MARK: - Priority Styling
    func priorityTagStyle(for priority: ItemPriority) -> PriorityTagStyle
    
    // MARK: - Ambient Effects
    /// Optional ambient visual effect for this theme
    var ambientEffect: ThemeAmbientEffect { get }
}

// MARK: - Theme Default Implementations

extension Theme {
    /// By default, past rail mirrors future rail
    var pastRailGradient: LinearGradient { railGradient }
    
    /// Default fonts - themes can override these
    var timeFont: String { DesignSystem.monoFont }
    var titleFont: String { DesignSystem.displayFont }
    var bodyFont: String { DesignSystem.lightFont }
    var bodyFontSize: CGFloat { 16 }
    var tagFont: String { DesignSystem.monoFont }
    
    // Default to no ambient effect
    var ambientEffect: ThemeAmbientEffect { .none }
}

