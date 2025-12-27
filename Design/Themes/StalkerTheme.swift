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
    private static let oliveDrab = Color(hex: "6B8E23")
    private static let fadedCyan = Color(hex: "4A8C8C")
    private static let artifactPurple = Color(hex: "9932CC") // Dark orchid - anomaly color
    
    // MARK: - Core Visual
    var mainAccent: Color { Self.oliveDrab }
    
    /// AI accent - Anomaly/artifact purple glow
    var aiAccent: Color { Self.artifactPurple }
    
    var railGradient: LinearGradient {
        LinearGradient(
            colors: [Self.oliveDrab, Self.oliveDrab.opacity(0.5)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    // MARK: - Typography (Rugged Utilitarian)
    var timeFont: String { "Quantico-Regular" }
    var titleFont: String { "Quantico-Bold" }
    var bodyFont: String { "Quantico-Regular" }
    var tagFont: String { "Quantico-Regular" }
    
    // MARK: - Priority Tag Styles
    func priorityTagStyle(for priority: ItemPriority) -> PriorityTagStyle {
        switch priority {
        case .critical:
            // Rust danger warning: orange/red
            return PriorityTagStyle(
                text: "FATAL",
                color: Self.rustOrange,
                textColor: .black,
                backgroundColor: Self.rustOrange,
                borderRadius: 2
            )
        case .ai:
            return PriorityTagStyle(
                text: "SIGNAL",
                color: aiAccent,
                borderRadius: 2
            )
        case .high:
            return PriorityTagStyle(
                text: "HAZARD",
                color: Self.biohazardYellow,
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
