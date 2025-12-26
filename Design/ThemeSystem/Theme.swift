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
    
    // MARK: - Priority Styling
    func priorityTagStyle(for priority: ItemPriority) -> PriorityTagStyle
}

// MARK: - Theme Default Implementations

extension Theme {
    /// By default, past rail mirrors future rail
    var pastRailGradient: LinearGradient { railGradient }
}
