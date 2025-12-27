import SwiftUI

// MARK: - Timeline Rail (Master-Instance Architecture)

/// The main scrolling timeline view using TimelineEngine
/// Displays Past (Completed) -> NOW -> Future (Pending/Ghosts)
struct TimelineRailView: View {
    @Binding var selectedItem: TimelineItem?
    
    let completedItems: [TimelineItem]
    let pendingItems: [TimelineItem]    // Includes ghosts and debt
    
    // Actions passed from parent
    let onCompleteItem: (TimelineItem) -> Void
    let onDeleteItem: (TimelineItem) -> Void
    let onDeferItem: (TimelineItem) -> Void
    let onSkipItem: (TimelineItem) -> Void
    let onAIChat: (TimelineItem) -> Void
    
    var body: some View {
        ZStack {
            // 1. Background Rails (Fixed)
            TimelineRails()
            
            // 2. Scrolling Content
            ScrollViewReader { proxy in
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
                .onAppear {
                    // Scroll to NOW when view appears
                    // Slight delay to ensure layout is ready
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation {
                            proxy.scrollTo("NOW", anchor: .top)
                        }
                    }
                }
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
                onDelete: { onDeleteItem(item) },
                onSkip: { onSkipItem(item) },
                onAIChat: { onAIChat(item) }
            ),
            onTap: {
                selectedItem = item
            }
        )
    }
}
