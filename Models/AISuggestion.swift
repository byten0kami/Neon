import Foundation

// MARK: - AI Suggestion Model

/// Model for AI-generated suggestion data
struct AISuggestion: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let category: String
    var dailyTime: String? = nil
    var priority: TaskPriority = .normal
}
