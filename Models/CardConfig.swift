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
    
    // Priority Theme Style (for themed badges)
    let priorityTagStyle: PriorityTagStyle?
    
    // Time & Status
    let time: String?
    let isCompleted: Bool
    let isOverdue: Bool
    let isDeferred: Bool
    let isSkipped: Bool
    
    // Optional Features
    let recurrence: String?
    let actions: [TimelineCardAction]
    
    // MARK: - Initializer
    
    init(
        title: String,
        description: String? = nil,
        badgeText: String,
        accentColor: Color,
        priorityTagStyle: PriorityTagStyle? = nil,
        time: String? = nil,
        isCompleted: Bool = false,
        isOverdue: Bool = false,
        isDeferred: Bool = false,
        isSkipped: Bool = false,
        recurrence: String? = nil,
        actions: [TimelineCardAction] = []
    ) {
        self.title = title
        self.description = description
        self.badgeText = badgeText
        self.accentColor = accentColor
        self.priorityTagStyle = priorityTagStyle
        self.time = time
        self.isCompleted = isCompleted
        self.isOverdue = isOverdue
        self.isDeferred = isDeferred
        self.isSkipped = isSkipped
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
                color: DesignSystem.lime,
                icon: "checkmark",
                isFilled: true,
                action: onAccept
            ),
            TimelineCardAction(
                title: "N",
                color: DesignSystem.slate500,
                icon: "xmark",
                isFilled: false,
                action: onDeny
            )
        ]
        
        return CardConfig(
            title: title,
            description: description,
            badgeText: "CMD",
            accentColor: DesignSystem.purple,
            time: dailyTime,
            recurrence: dailyTime != nil ? "DAILY" : nil,
            actions: actions
        )
    }
    
    // MARK: - Factory for TimelineItem (Master-Instance Architecture)
    
    /// Create a card config for a TimelineItem (new Master-Instance architecture)
    /// Uses active priority theme from ThemeManager
    @MainActor
    static func forTimelineItem(
        _ item: TimelineItem,
        isGhost: Bool = false,
        onComplete: @escaping () -> Void,
        onDefer: @escaping () -> Void,
        onDelete: @escaping () -> Void,
        onSkip: @escaping () -> Void
    ) -> CardConfig {
        // Get theme-aware priority style from current theme
        let style = ThemeManager.shared.priorityTagStyle(for: item.priority)
        
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
            // ACTION 1: DONE (Always available)
            let doneAction = TimelineCardAction(
                title: "Done",
                color: style.color,
                icon: "checkmark",
                isFilled: true,
                action: onComplete
            )
            
            // ACTION 2: SKIP (Always available now)
            let skipAction = TimelineCardAction(
                title: "Skip",
                color: DesignSystem.slate500,
                icon: "arrow.turn.up.right",
                isFilled: false,
                action: onSkip
            )
            
            // ACTION 3: DEFER (Only if Overdue)
            if item.isOverdue {
                let deferAction = TimelineCardAction(
                    title: "Defer",
                    color: DesignSystem.amber,
                    icon: "clock.arrow.circlepath",
                    isFilled: false,
                    action: onDefer
                )
                
                // Order: [Defer] [Skip] [Done] (Right aligned)
                actions = [deferAction, skipAction, doneAction]
            } else {
                // Order: [Skip] [Done] (Right aligned)
                actions = [skipAction, doneAction]
            }
        }
        
        return CardConfig(
            title: item.title,
            description: item.description,
            badgeText: style.text,
            accentColor: style.color,
            priorityTagStyle: style,
            time: timeString,
            isCompleted: item.isCompleted,
            isOverdue: item.isOverdue,
            isDeferred: item.isDeferred,
            isSkipped: item.isSkipped,
            recurrence: item.recurrenceText?.uppercased(),
            actions: actions
        )
    }
    
    // MARK: - Helper Methods
    
    private static func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }
}
