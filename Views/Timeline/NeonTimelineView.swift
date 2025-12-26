import SwiftUI

// MARK: - Timeline View

/// The main scrolling timeline view
/// Displays Past (Completed) -> NOW -> Future (Pending)
struct NeonTimelineView: View {
    @Binding var selectedTask: UserTask?
    
    let completedTasks: [UserTask]
    let pendingTasks: [UserTask]
    
    // Actions passed from parent
    let onCompleteTask: (UserTask) -> Void
    let onDeleteTask: (UserTask) -> Void
    let onDeferTask: (UserTask) -> Void
    
    var body: some View {
        ZStack {
            // 1. Background Rails (Fixed)
            TimelineRails()
            
            // 2. Scrolling Content
            ScrollView {
                VStack(spacing: 0) {
                    
                    // --- PAST (Completed) ---
                    // We want Oldest -> Newest (Top to Bottom) so Newest is closest to NOW.
                    // HomeView passes reversed() which is likely [Newest, ..., Oldest].
                    // So we should reverse it back to get [Oldest, ..., Newest]?
                    // Or maybe HomeView passes it correctly. 
                    // Let's assume user wants "Past" section to stack upwards away from Now?
                    // But ScrollView stacks downwards.
                    // If we want "Top of Screen" to be "Deep Past", we list Oldest first.
                    
                    // If HomeView passes [Newest, ..., Oldest], we reverse it to [Oldest, ..., Newest]
                    // So Oldest is at top (Line 0).
                    ForEach(completedTasks.reversed(), id: \.id) { task in
                        taskView(for: task)
                    }
                    
                    // --- NOW ---
                    NowCard()
                        .padding(.vertical, 0)
                        .id("NOW")
                    
                    // --- FUTURE (Pending) ---
                    // Ordered by priority/time (Next -> Later)
                    ForEach(pendingTasks, id: \.id) { task in
                        taskView(for: task)
                    }
                    
                    // Bottom padding
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
