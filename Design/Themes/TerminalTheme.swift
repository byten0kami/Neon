import SwiftUI

// MARK: - Terminal Theme (Netrunner/Sysadmin)

/// Raw data, no GUI fluff, boot sequence aesthetic, hard edges, monospace
struct TerminalTheme: Theme {
    // MARK: - Identity
    let id: ThemeID = .terminal
    let name = "Terminal"
    let description = "Netrunner Console"
    
    // MARK: - Theme Colors
    static let consoleGreen = Color(hex: "00FF00")
    private static let amberMonitor = Color(hex: "FFB000")
    private static let dimGrey = Color(hex: "666666")
    
    // MARK: - Core Visual
    var mainAccent: Color { Self.consoleGreen }
    
    var railGradient: LinearGradient {
        LinearGradient(
            colors: [Self.consoleGreen, Self.consoleGreen.opacity(0.5)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    // MARK: - Priority Tag Styles
    func priorityTagStyle(for priority: ItemPriority) -> PriorityTagStyle {
        switch priority {
        case .critical:
            // Inverted: red bg, black text
            return PriorityTagStyle(
                text: "CRIT",
                color: DesignSystem.red,
                textColor: .black,
                backgroundColor: DesignSystem.red,
                borderRadius: 0
            )
        case .ai:
            return PriorityTagStyle(
                text: "SYS",
                color: DesignSystem.aiAccent,
                borderRadius: 0
            )
        case .high:
            return PriorityTagStyle(
                text: "WARN",
                color: Self.amberMonitor,
                borderRadius: 0
            )
        case .normal:
            return PriorityTagStyle(
                text: "EXEC",
                color: Self.consoleGreen,
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
}
