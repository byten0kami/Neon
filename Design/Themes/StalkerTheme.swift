import SwiftUI

// MARK: - Stalker Theme (Zone Survivor)

/// Gritty, utilitarian, PDA-style - radiation/survival vibes
struct StalkerTheme: Theme {
    // MARK: - Identity
    let id: ThemeID = .stalker
    let name = "Stalker"
    let description = "Zone Survivor PDA"
    
    // MARK: - Theme Colors
    private static let biohazardYellow = Color(hex: "FFD700")
    private static let rustOrange = Color(hex: "B7410E")
    static let oliveDrab = Color(hex: "6B8E23")
    private static let fadedCyan = Color(hex: "4A8C8C")
    
    // MARK: - Core Visual
    var mainAccent: Color { Self.oliveDrab }
    
    var railGradient: LinearGradient {
        LinearGradient(
            colors: [Self.oliveDrab, Self.oliveDrab.opacity(0.5)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    // MARK: - Priority Tag Styles
    func priorityTagStyle(for priority: ItemPriority) -> PriorityTagStyle {
        switch priority {
        case .critical:
            // Biohazard warning: yellow on black
            return PriorityTagStyle(
                text: "FATAL",
                color: Self.biohazardYellow,
                textColor: .black,
                backgroundColor: Self.biohazardYellow,
                borderRadius: 2
            )
        case .ai:
            return PriorityTagStyle(
                text: "SIGNAL",
                color: DesignSystem.aiAccent,
                borderRadius: 2
            )
        case .high:
            return PriorityTagStyle(
                text: "HAZARD",
                color: Self.rustOrange,
                borderRadius: 2
            )
        case .normal:
            return PriorityTagStyle(
                text: "SCAV",
                color: Self.oliveDrab,
                borderRadius: 2
            )
        case .low:
            return PriorityTagStyle(
                text: "STASH",
                color: Self.fadedCyan,
                borderRadius: 2
            )
        }
    }
}
