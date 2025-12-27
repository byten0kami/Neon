import Foundation

// MARK: - Item Priority

/// Unified priority enum for TimelineItem
/// All items are TASKs, styled by priority color
enum ItemPriority: String, Codable, Comparable, Sendable, CaseIterable {
    case critical   // 🔴 Red - Urgent, must-do-now
    case ai         // 🟣 Purple - AI-generated (sorted first)
    case high       // 🟡 Amber - High priority
    case normal     // 🟢 Lime - Standard priority
    case low        // 🔵 Cyan - Low priority
    
    // MARK: - Comparable
    
    static func < (lhs: ItemPriority, rhs: ItemPriority) -> Bool {
        return lhs.sortOrder < rhs.sortOrder
    }
    
    /// Sort order (lower = higher priority)
    var sortOrder: Int {
        switch self {
        case .ai: return 0      // AI first
        case .critical: return 1 // Critical second
        case .high: return 2
        case .normal: return 3
        case .low: return 4
        }
    }
    
    // MARK: - Display
    
    var displayName: String {
        switch self {
        case .critical: return "CRITICAL"
        case .ai: return "AI"
        case .high: return "HIGH"
        case .normal: return "NORMAL"
        case .low: return "LOW"
        }
    }
    
    // MARK: - Badge (all are TASK now)
    
    var badgeText: String {
        return "TASK"
    }
    
    // MARK: - Conversion
    
    /// Convert from strings (for AI parsing)
    init(from string: String) {
        switch string.lowercased() {
        case "critical", "asap", "urgent": self = .critical
        case "ai", "insight", "suggestion": self = .ai
        case "high": self = .high
        case "low": self = .low
        default: self = .normal
        }
    }
}
