import SwiftUI

/// Defines the visual configuration for a specific theme
struct ThemeConfig: Identifiable, Equatable {
    let id: String
    let name: String
    let description: String
    
    // Core visual elements
    let railGradient: LinearGradient
    let mainAccent: Color
    
    static func == (lhs: ThemeConfig, rhs: ThemeConfig) -> Bool {
        return lhs.id == rhs.id
    }
    
    // Default Configuration
    static let cyberpunk = ThemeConfig(
        id: "default",
        name: "Cyberpunk",
        description: "Default System Interface",
        railGradient: LinearGradient(
            colors: [Theme.cyan, Theme.cyan.opacity(0.5)],
            startPoint: .top,
            endPoint: .bottom
        ),
        mainAccent: Theme.cyan
    )
    
    // Nyan Configuration
    static let nyan = ThemeConfig(
        id: "nyan",
        name: "Nyan",
        description: "Rainbow Neural Link",
        railGradient: LinearGradient(
            colors: [Theme.red, Theme.orange, Theme.yellow, Theme.green, Theme.blue, Theme.purple],
            startPoint: .top,
            endPoint: .bottom
        ),
        mainAccent: Theme.purple
    )
}
