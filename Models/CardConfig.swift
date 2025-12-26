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
        
        // Build actions - all tasks get Done + Defer/Skip based on isRecurring
        var actions: [TimelineCardAction] = []
        if !task.isCompleted {
            actions = [
                TimelineCardAction(
                    title: "Done",
                    color: cardType.color,
                    icon: "checkmark",
                    isFilled: true,
                    action: onComplete
                ),
                TimelineCardAction(
                    title: task.isRecurring ? "Defer" : "Skip",
                    color: Theme.slate500,
                    icon: task.isRecurring ? "clock.arrow.circlepath" : "arrow.turn.up.right",
                    isFilled: false,
                    action: task.isRecurring ? onDefer : onDelete
                )
            ]
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
        
        // Build actions based on mustBeCompleted flag
        var actions: [TimelineCardAction] = []
        if !item.isCompleted {
            // All priorities get the same actions: Done + Defer/Skip
            // Second button depends on mustBeCompleted, not recurrence
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
    
    /// Get badge text and accent color based on priority only
    private static func priorityStyle(for priority: ItemPriority, category: String) -> (String, Color) {
        // All cards are TASK, colored by priority
        switch priority {
        case .critical:
            return ("TASK", Theme.red)
        case .ai:
            return ("TASK", Theme.purple)
        case .high:
            return ("TASK", Theme.amber)
        case .normal:
            return ("TASK", Theme.lime)
        case .low:
            return ("TASK", Theme.cyan)
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
