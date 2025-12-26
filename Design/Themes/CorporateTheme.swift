import SwiftUI

// MARK: - Corporate Theme (Arasaka Standard)

/// Clean, sterile, corporate UI - matte colors, no glow, rounded corners, sans-serif
struct CorporateTheme: Theme {
    // MARK: - Identity
    let id: ThemeID = .corporate
    let name = "Corporate"
    let description = "Arasaka Standard UI"
    
    // MARK: - Theme Colors
    private static let crimson = Color(hex: "DC143C")
    private static let burntOrange = Color(hex: "CC5500")
    private static let steelBlue = Color(hex: "4682B4")
    private static let coolGrey = Color(hex: "8E9AAF")
    private static let aiPurple = Color(hex: "7B1FA2")
    private static let artifactPurple = Color(hex: "9932CC")
    
    // MARK: - Core Visual
    var mainAccent: Color { Self.steelBlue }
    
    /// AI accent - Artifact purple for AI distinction
    var aiAccent: Color { Self.artifactPurple }
    
    var railGradient: LinearGradient {
        LinearGradient(
            colors: [Self.steelBlue, Self.steelBlue.opacity(0.5)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    // MARK: - Priority Tag Styles
    func priorityTagStyle(for priority: ItemPriority) -> PriorityTagStyle {
        switch priority {
        case .critical:
            return PriorityTagStyle(
                text: "ASAP",
                color: Self.crimson,
                useSystemFont: true,
                borderRadius: 6
            )
        case .ai:
            return PriorityTagStyle(
                text: "AI",
                color: aiAccent,
                useSystemFont: true,
                borderRadius: 6
            )
        case .high:
            return PriorityTagStyle(
                text: "PRIO",
                color: Self.burntOrange,
                useSystemFont: true,
                borderRadius: 6
            )
        case .normal:
            return PriorityTagStyle(
                text: "TASK",
                color: Self.steelBlue,
                useSystemFont: true,
                borderRadius: 6
            )
        case .low:
            return PriorityTagStyle(
                text: "INFO",
                color: Self.coolGrey,
                useSystemFont: true,
                borderRadius: 6
            )
        }
    }
}
