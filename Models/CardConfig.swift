import SwiftUI

// MARK: - Card Configuration

/// Configuration object for UniversalTimelineCard
/// Defines all visual and behavioral properties for a card
struct CardConfig {
    // Core Properties
    let title: String
    let description: String?
    let badgeText: String
    let accentColor: Color
    
    // Time & Status
    let time: String?
    let isCompleted: Bool
    let isOverdue: Bool
    let isDeferred: Bool
    
    // Optional Features
    let recurrence: String?
    let actions: [TimelineCardAction]
    
    // MARK: - Initializer
    
    init(
        title: String,
        description: String? = nil,
        badgeText: String,
        accentColor: Color,
        time: String? = nil,
        isCompleted: Bool = false,
        isOverdue: Bool = false,
        isDeferred: Bool = false,
        recurrence: String? = nil,
        actions: [TimelineCardAction] = []
    ) {
        self.title = title
        self.description = description
        self.badgeText = badgeText
        self.accentColor = accentColor
        self.time = time
        self.isCompleted = isCompleted
        self.isOverdue = isOverdue
        self.isDeferred = isDeferred
        self.recurrence = recurrence
        self.actions = actions
    }
    
    // MARK: - Factory Methods
    
    /// Create a card config for an AI suggestion
    static func forSuggestion(
        title: String,
        description: String,
        dailyTime: String?,
        onAccept: @escaping () -> Void,
        onDeny: @escaping () -> Void
    ) -> CardConfig {
        let actions = [
            TimelineCardAction(
                title: "Y",
                color: Theme.lime,
                icon: "checkmark",
                isFilled: true,
                action: onAccept
            ),
            TimelineCardAction(
                title: "N",
                color: Theme.slate500,
                icon: "xmark",
                isFilled: false,
                action: onDeny
            )
        ]
        
        return CardConfig(
            title: title,
            description: description,
            badgeText: "CMD",
            accentColor: Theme.purple,
            time: dailyTime,
            recurrence: dailyTime != nil ? "DAILY" : nil,
            actions: actions
        )
    }
    
    /// Create a card config for a user task
    static func forTask(
        _ task: UserTask,
        onComplete: @escaping () -> Void,
        onDefer: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) -> CardConfig {
        let cardType = TimelineCardType.from(category: task.category)
        
        // Determine time display
        let timeString: String?
        if task.isCompleted, let completedAt = task.completedAt {
            timeString = formatTime(completedAt)
        } else if let scheduledTime = task.scheduledTime {
            timeString = formatTime(scheduledTime)
        } else {
            timeString = nil
        }
        
        // Build actions based on Card Type
        var actions: [TimelineCardAction] = []
        if !task.isCompleted {
            switch cardType {
            case .task:
                // TASK: DONE, SKIP
                actions = [
                    TimelineCardAction(
                        title: "Done",
                        color: cardType.color,
                        icon: "checkmark",
                        isFilled: true,
                        action: onComplete
                    ),
                    TimelineCardAction(
                        title: "Skip",
                        color: Theme.slate500,
                        icon: "arrow.turn.up.right",
                        isFilled: false,
                        action: onDelete
                    )
                ]
                
            case .reminder:
                // RMD: DONE, DEFER
                actions = [
                    TimelineCardAction(
                        title: "Done",
                        color: cardType.color,
                        icon: "checkmark",
                        isFilled: true,
                        action: onComplete
                    ),
                    TimelineCardAction(
                        title: "Defer",
                        color: Theme.slate500,
                        icon: "clock.arrow.circlepath",
                        isFilled: false,
                        action: onDefer
                    )
                ]
                
            case .info:
                // INFO: ACK
                actions = [
                    TimelineCardAction(
                        title: "Ack",
                        color: cardType.color,
                        icon: "hand.thumbsup",
                        isFilled: false,
                        action: onComplete // Ack usually treats as done/dismissed
                    )
                ]
                
            case .insight:
                // INSIGHT: ACCEPT, KILL
                actions = [
                    TimelineCardAction(
                        title: "Accept",
                        color: cardType.color,
                        icon: "star.fill",
                        isFilled: true,
                        action: onComplete
                    ),
                    TimelineCardAction(
                        title: "Kill",
                        color: Theme.slate500,
                        icon: "xmark",
                        isFilled: false,
                        action: onDelete
                    )
                ]
                
            case .asap:
                // ASAP: EXECUTE
                actions = [
                    TimelineCardAction(
                        title: "EXECUTE",
                        color: cardType.color,
                        icon: "exclamationmark.triangle.fill",
                        isFilled: true,
                        action: onComplete
                    )
                ]
            }
        }
        
        return CardConfig(
            title: task.title,
            description: task.taskDescription,
            badgeText: cardType.label,
            accentColor: cardType.color,
            time: timeString,
            isCompleted: task.isCompleted,
            isOverdue: task.isOverdue,
            isDeferred: task.isDeferred,
            recurrence: task.recurrence?.uppercased(),
            actions: actions
        )
    }
    
    // MARK: - Factory for TimelineItem (Master-Instance Architecture)
    
    /// Create a card config for a TimelineItem (new Master-Instance architecture)
    /// Priority-driven badge/colors:
    /// - .critical → ASAP (red)
    /// - .high → TASK (amber)
    /// - .normal → TASK (lime)
    /// - .low → INFO (cyan)
    static func forTimelineItem(
        _ item: TimelineItem,
        isGhost: Bool = false,
        onComplete: @escaping () -> Void,
        onDefer: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) -> CardConfig {
        // Priority-based styling
        let (badgeText, accentColor) = priorityStyle(for: item.priority, category: item.category)
        
        // Determine time display
        let timeString: String?
        if item.isCompleted, let completedAt = item.completedAt {
            timeString = formatTime(completedAt)
        } else {
            timeString = formatTime(item.effectiveTime)
        }
        
        // Build actions based on priority/category
        var actions: [TimelineCardAction] = []
        if !item.isCompleted {
            switch item.priority {
            case .critical:
                // ASAP: EXECUTE only
                actions = [
                    TimelineCardAction(
                        title: "EXECUTE",
                        color: accentColor,
                        icon: "exclamationmark.triangle.fill",
                        isFilled: true,
                        action: onComplete
                    )
                ]
                
            case .high, .normal:
                // Standard: DONE, DEFER/SKIP
                actions = [
                    TimelineCardAction(
                        title: "Done",
                        color: accentColor,
                        icon: "checkmark",
                        isFilled: true,
                        action: onComplete
                    ),
                    TimelineCardAction(
                        title: item.mustBeCompleted ? "Defer" : "Skip",
                        color: Theme.slate500,
                        icon: item.mustBeCompleted ? "clock.arrow.circlepath" : "arrow.turn.up.right",
                        isFilled: false,
                        action: item.mustBeCompleted ? onDefer : onDelete
                    )
                ]
                
            case .low:
                // INFO: ACK only
                actions = [
                    TimelineCardAction(
                        title: "Ack",
                        color: accentColor,
                        icon: "hand.thumbsup",
                        isFilled: false,
                        action: onComplete
                    )
                ]
            }
        }
        
        return CardConfig(
            title: item.title,
            description: item.description,
            badgeText: badgeText,
            accentColor: accentColor,
            time: timeString,
            isCompleted: item.isCompleted,
            isOverdue: item.isOverdue,
            isDeferred: item.isDeferred,
            recurrence: item.recurrenceText?.uppercased(),
            actions: actions
        )
    }
    
    /// Get badge text and accent color based on priority and category
    private static func priorityStyle(for priority: ItemPriority, category: String) -> (String, Color) {
        // Check if category overrides (insight, info, reminder)
        let lowerCategory = category.lowercased()
        
        switch lowerCategory {
        case "insight", "suggestion":
            return ("INSIGHT", Theme.purple)
        case "reminder", "remind":
            return ("RMD", Theme.amber)
        case "info", "log", "config":
            return ("INFO", Theme.cyan)
        default:
            break
        }
        
        // Use priority-based styling
        switch priority {
        case .critical:
            return ("ASAP", Theme.red)
        case .high:
            return ("TASK", Theme.amber)
        case .normal:
            return ("TASK", Theme.lime)
        case .low:
            return ("INFO", Theme.cyan)
        }
    }
    
    // MARK: - Helper Methods
    
    private static func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }
}
