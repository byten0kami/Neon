import SwiftUI

// MARK: - Timeline View (Master-Instance Architecture)

/// The main scrolling timeline view using the new TimelineEngine
/// Displays Past (Completed) -> NOW -> Future (Pending/Ghosts)
struct NeonTimelineView: View {
    @Binding var selectedItem: TimelineItem?
    
    let completedItems: [TimelineItem]
    let pendingItems: [TimelineItem]    // Includes ghosts and debt
    
    // Actions passed from parent
    let onCompleteItem: (TimelineItem) -> Void
    let onDeleteItem: (TimelineItem) -> Void
    let onDeferItem: (TimelineItem) -> Void
    
    var body: some View {
        ZStack {
            // 1. Background Rails (Fixed)
            TimelineRails()
            
            // 2. Scrolling Content
            ScrollView {
                VStack(spacing: 0) {
                    
                    // --- PAST (Completed) ---
                    ForEach(completedItems.reversed(), id: \.id) { item in
                        itemView(for: item)
                    }
                    
                    // --- NOW ---
                    NowCard()
                        .padding(.vertical, 0)
                        .id("NOW")
                    
                    // --- FUTURE (Pending/Ghosts + Debt at top) ---
                    ForEach(pendingItems, id: \.id) { item in
                        itemView(for: item)
                    }
                    
                    // Bottom padding
                    Color.clear.frame(height: 100)
                }
                .padding(.vertical, 20)
            }
        }
    }
    
    private func itemView(for item: TimelineItem) -> some View {
        let isGhost = item.isInstance && !TimelineEngine.shared.instances.contains { $0.id == item.id }
        
        return UniversalTimelineCard(
            config: CardConfig.forTimelineItem(
                item,
                isGhost: isGhost,
                onComplete: { onCompleteItem(item) },
                onDefer: { onDeferItem(item) },
                onDelete: { onDeleteItem(item) }
            ),
            onTap: {
                selectedItem = item
            }
        )
    }
}

// MARK: - Legacy Support

/// Wrapper to support legacy UserTask-based timeline
/// Used during migration period
struct LegacyNeonTimelineView: View {
    @Binding var selectedTask: UserTask?
    
    let completedTasks: [UserTask]
    let pendingTasks: [UserTask]
    
    // Actions passed from parent
    let onCompleteTask: (UserTask) -> Void
    let onDeleteTask: (UserTask) -> Void
    let onDeferTask: (UserTask) -> Void
    
    var body: some View {
        ZStack {
            TimelineRails()
            
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(completedTasks.reversed(), id: \.id) { task in
                        taskView(for: task)
                    }
                    
                    NowCard()
                        .padding(.vertical, 0)
                        .id("NOW")
                    
                    ForEach(pendingTasks, id: \.id) { task in
                        taskView(for: task)
                    }
                    
                    Color.clear.frame(height: 100)
                }
                .padding(.vertical, 20)
            }
        }
    }
    
    private func taskView(for task: UserTask) -> some View {
        UniversalTimelineCard(
            config: CardConfig.forTask(
                task,
                onComplete: { onCompleteTask(task) },
                onDefer: { onDeferTask(task) },
                onDelete: { onDeleteTask(task) }
            ),
            onTap: {
                selectedTask = task
            }
        )
    }
}
