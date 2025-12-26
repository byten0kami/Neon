import Foundation

// MARK: - Event Types

enum EventType: Codable, Equatable {
    case medication(name: String, dosage: String)
    case meal(MealType)
    case activity(ActivityKind)
    case reminder(message: String)
    case timer(name: String, durationMinutes: Int)
    case custom(category: String)
    
    var displayName: String {
        switch self {
        case .medication(let name, _): return name
        case .meal(let type): return type.rawValue.capitalized
        case .activity(let kind): return kind.rawValue.capitalized
        case .reminder(let msg): return msg
        case .timer(let name, _): return name
        case .custom(let cat): return cat
        }
    }
    
    var icon: String {
        switch self {
        case .medication: return "pill.fill"
        case .meal: return "fork.knife"
        case .activity: return "figure.walk"
        case .reminder: return "bell.fill"
        case .timer: return "timer"
        case .custom: return "square.grid.2x2"
        }
    }
}

enum MealType: String, Codable, CaseIterable {
    case breakfast, lunch, dinner, snack
}

enum ActivityKind: String, Codable, CaseIterable {
    case coffee, exercise, sauna, work, sleep, rest, other
}
