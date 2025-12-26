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
    var railGradient: LinearGradient { get }
    var pastRailGradient: LinearGradient { get }
    
    // MARK: - Extended Visual
    var cardBackground: Color { get }
    var cardTexture: Image? { get }
    var tabBarTint: Color { get }
    var backgroundPrimary: Color { get }
    var backgroundSecondary: Color { get }
    
    // MARK: - Typography
    var headerFont: String { get }
    var bodyFont: String { get }
    var monoFont: String { get }
    
    // MARK: - Priority Styling
    func priorityTagStyle(for priority: ItemPriority) -> PriorityTagStyle
}
