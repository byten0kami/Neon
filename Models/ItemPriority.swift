import Foundation

// MARK: - Item Priority

/// Unified priority enum for TimelineItem
/// Replaces the old TaskPriority with added .critical level for ASAP-style items
enum ItemPriority: String, Codable, Comparable, Sendable, CaseIterable {
    case low
    case normal
    case high
    case critical       // ASAP-style urgent items (red UI)
    
    // MARK: - Comparable
    
    static func < (lhs: ItemPriority, rhs: ItemPriority) -> Bool {
        let order: [ItemPriority] = [.low, .normal, .high, .critical]
        guard let lhsIndex = order.firstIndex(of: lhs),
              let rhsIndex = order.firstIndex(of: rhs) else { return false }
        return lhsIndex < rhsIndex
    }
    
    // MARK: - Display
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .normal: return "Normal"
        case .high: return "High"
        case .critical: return "Critical"
        }
    }
    
    // MARK: - Badge
    
    /// Returns the badge text for UI display
    var badgeText: String {
        switch self {
        case .critical: return "ASAP"
        case .high: return "TASK"
        case .normal: return "TASK"
        case .low: return "INFO"
        }
    }
    
    // MARK: - Conversion
    
    /// Convert from old TaskPriority strings (for migration/AI parsing)
    init(from string: String) {
        switch string.lowercased() {
        case "critical", "asap", "urgent": self = .critical
        case "high": self = .high
        case "low": self = .low
        default: self = .normal
        }
    }
}
