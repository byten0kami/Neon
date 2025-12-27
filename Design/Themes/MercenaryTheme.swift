import SwiftUI

// MARK: - Mercenary Theme (Edgerunner)

/// Flashy, aggressive, "Style over Substance" - high contrast neons with glow
struct MercenaryTheme: Theme {
    // MARK: - Identity
    let id: ThemeID = .mercenary
    let name = "Mercenary"
    let description = "Edgerunner Neon Style"
    
    // MARK: - Theme Colors
    private static let hotPink = Color(hex: "FF0099")
    private static let neonOrange = Color(hex: "FF5F1F")
    private static let laserBlue = Color(hex: "00D4FF")
    private static let midnight = Color(hex: "191970")
    private static let cyan = Color(hex: "00FFFF")
    private static let magenta = Color(hex: "FF00FF")
    private static let artifactPurple = Color(hex: "9932CC")
    private static let dataBlue = Color(hex: "3C5AA0") // Muted dark blue
    
    // MARK: - Core Visual
    var mainAccent: Color { Self.cyan }
    
    /// AI accent - Cyberpunk artifact purple
    var aiAccent: Color { Self.artifactPurple }
    
    var railGradient: LinearGradient {
        LinearGradient(
            colors: [Self.cyan, Self.cyan.opacity(0.5)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    // MARK: - Typography (Flashy Neon Style)
    var timeFont: String { "Audiowide-Regular" }
    var titleFont: String { "Audiowide-Regular" }
    var bodyFont: String { "TurretRoad-Bold" }
    var tagFont: String { "Audiowide-Regular" }
    
    // MARK: - Priority Tag Styles
    func priorityTagStyle(for priority: ItemPriority) -> PriorityTagStyle {
        switch priority {
        case .ai:
            return PriorityTagStyle(
                text: "CMD",
                color: aiAccent,
                hasGlow: true,
                glowRadius: 4
            )
        case .high:
            return PriorityTagStyle(
                text: "URGENT",
                color: Self.neonOrange,
                hasGlow: true,
                glowRadius: 4
            )
        case .normal:
            return PriorityTagStyle(
                text: "GIG",
                color: Self.laserBlue,
                hasGlow: true,
                glowRadius: 4
            )
        case .low:
            return PriorityTagStyle(
                text: "DATA",
                color: Self.dataBlue,
                hasGlow: true,
                glowRadius: 4
            )
        }
    }
    
    // MARK: - Ambient Effects
    var ambientEffect: ThemeAmbientEffect {
        // Occasional HUD glitches (5-10 mins) - usually when low stability but here random
        .periodic(effect: .staticInterference, minInterval: 300, maxInterval: 600)
    }
}
