import SwiftUI

// MARK: - Home View (Command Center)

/// Main home screen - displays the infinite timeline with tasks
/// Now uses TimelineEngine for the Master-Instance architecture
struct HomeView: View {
    @StateObject private var brain = AIBrain.shared
    @StateObject private var engine = TimelineEngine.shared
    
    @State private var stability: Int = 72
    @State private var selectedItem: TimelineItem?
    @Binding var showingCalendar: Bool
    @Binding var chatContextItem: TimelineItem?  // Item to discuss with AI
    
    private var isLowStability: Bool {
        stability < 50
    }
    
    // MARK: - Computed Items
    
    /// Items for today from the engine
    private var todayItems: [TimelineItem] {
        engine.items(for: Date())
    }
    
    /// Completed items (for past section)
    private var completedItems: [TimelineItem] {
        engine.instances.filter { $0.isCompleted && !$0.isArchived }
            .sorted { ($0.completedAt ?? Date.distantPast) > ($1.completedAt ?? Date.distantPast) }
    }
    
    /// Pending items (non-completed from today's items)
    private var pendingItems: [TimelineItem] {
        todayItems.filter { !$0.isCompleted }
    }
    

    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                StatusHeader(
                    stability: stability,
                    onCalendarTap: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showingCalendar.toggle()
                        }
                    }
                )
                
                TimelineView(
                    selectedItem: $selectedItem,
                    completedItems: completedItems,
                    pendingItems: pendingItems,
                    onCompleteItem: { item in
                        completeItem(item)
                        QuestManager.shared.reportEvent(.taskCompleted)
                    },
                    onDeleteItem: { item in
                        withAnimation {
                            engine.delete(id: item.id)
                        }
                    },
                    onDeferItem: { item in
                        // Defer using saved default time (no popup)
                        let minutes = APISettingsStore.shared.settings.defaultDeferMinutes
                        engine.defer(id: item.id, byMinutes: minutes)
                    },
                    onSkipItem: { item in
                        skipItem(item)
                    },
                    onAIChat: { item in
                        chatContextItem = item
                    }
                )
            }
            .blur(radius: selectedItem != nil ? 5 : 0) // Blur background when overlay active
            
            // Overlay Effects
            // Overlay Effects moved to ContentView for root access
            
            // Edit Overlay
            if let item = selectedItem {
                EditTaskOverlay(
                    item: Binding(
                        get: { item },
                        set: { selectedItem = $0 }
                    ),
                    onSave: { updatedItem in
                        engine.update(updatedItem)
                        selectedItem = nil
                    },
                    onCancel: {
                        selectedItem = nil
                    },
                    onDelete: {
                        engine.delete(id: item.id)
                        selectedItem = nil
                    }
                )
            }
            

            

        }
        .background(
            ZStack {
                CyberpunkBackground(isLowStability: isLowStability)
                
                if isLowStability {
                    GlitchEffect(intensity: Double(50 - stability) / 50.0)
                }
            }
            .ignoresSafeArea()
        )
    }
    
    // MARK: - Actions
    
    private func completeItem(_ item: TimelineItem) {
        // If it's a ghost, materialize it first
        if item.seriesId != nil && !engine.instances.contains(where: { $0.id == item.id }) {
            var materializedItem = item
            materializedItem.isCompleted = true
            materializedItem.completedAt = Date()
            engine.materialize(materializedItem)
        } else {
            engine.complete(id: item.id)
        }
    }
    
    private func skipItem(_ item: TimelineItem) {
        // As with completion, materialize ghosts first
        if item.seriesId != nil && !engine.instances.contains(where: { $0.id == item.id }) {
            var materializedItem = item
            materializedItem.isCompleted = true
            materializedItem.isSkipped = true
            materializedItem.completedAt = Date()
            engine.materialize(materializedItem)
        } else {
            engine.skip(id: item.id)
        }
    }
}
