import SwiftUI

// MARK: - Terminal Theme (Netrunner/Sysadmin)

/// Raw data, no GUI fluff, boot sequence aesthetic, hard edges, monospace
struct TerminalTheme: Theme {
    // MARK: - Identity
    let id: ThemeID = .terminal
    let name = "Terminal"
    let description = "Netrunner Console"
    
    // MARK: - Theme Colors
    private static let consoleGreen = Color(hex: "00FF41") // Matrix Green
    private static let amberMonitor = Color(hex: "FFB000")
    private static let dimGrey = Color(hex: "666666")
    private static let criticalRed = Color(hex: "DE2312")
    private static let phosphorWhite = Color(hex: "E6E6E6") // White Phosphor
    private static let artifactPurple = Color(hex: "9932CC")
    
    // MARK: - Core Visual
    var mainAccent: Color { Self.consoleGreen }
    
    /// AI accent - Artifact purple for AI commands
    var aiAccent: Color { Self.artifactPurple }
    
    var railGradient: LinearGradient {
        LinearGradient(
            colors: [Self.consoleGreen, Self.consoleGreen.opacity(0.5)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    // MARK: - Typography (All Monospace for Terminal)
    var timeFont: String { "ShareTechMono-Regular" }
    var titleFont: String { "ShareTechMono-Regular" }
    var bodyFont: String { "ShareTechMono-Regular" }
    var tagFont: String { "ShareTechMono-Regular" }
    
    // MARK: - Priority Tag Styles
    func priorityTagStyle(for priority: ItemPriority) -> PriorityTagStyle {
        switch priority {
        case .ai:
            return PriorityTagStyle(
                text: "CMD",
                color: aiAccent,
                borderRadius: 0
            )
        case .high:
            // Inverted: red bg, black text
            return PriorityTagStyle(
                text: "CRIT",
                color: Self.criticalRed,
                textColor: .black,
                backgroundColor: Self.criticalRed,
                borderRadius: 0
            )
        case .normal:
            return PriorityTagStyle(
                text: "WARN",
                color: Self.amberMonitor,
                borderRadius: 0
            )
        case .low:
            return PriorityTagStyle(
                text: "LOG",
                color: Self.dimGrey,
                borderRadius: 0
            )
        }
    }
    
    // MARK: - Ambient Effects
    var ambientEffect: ThemeAmbientEffect {
        // Random matrix rain every 2-5 minutes
        .periodic(effect: .matrixRain, minInterval: 120, maxInterval: 300)
    }
}
