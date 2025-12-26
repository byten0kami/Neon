import Foundation

/// Unique identifiers for all quests
enum QuestID: String, Codable, CaseIterable {
    case nyanCat = "quest_nyan_cat"
    // Future quests...
}

/// Represents a quest in the system
struct Quest: Codable, Identifiable {
    let id: QuestID
    let title: String
    let description: String
    let image: String // System image or asset name
    
    // Scheduling
    let startDate: Date?
    let endDate: Date?
    
    // State
    var isCompleted: Bool = false
    var progress: Double = 0.0 // 0.0 to 1.0
    var completedAt: Date? = nil
    
    var isActive: Bool {
        let now = Date()
        if let start = startDate, now < start { return false }
        if let end = endDate, now > end { return false }
        return true
    }
}

/// Factory to generate standard quests
class QuestFactory {
    static func defaultQuests() -> [Quest] {
        return [
            Quest(
                id: .nyanCat,
                title: "Neural Glitch",
                description: "A strange creature has been spotted in the network...",
                image: "cat.fill",
                startDate: nil, // Always active
                endDate: nil
            )
        ]
    }
}

/// Triggers used to evaluate quest progression
enum QuestTriggerEvent {
    case taskCompleted
    case appLaunched
    case chatMessageSent
}
