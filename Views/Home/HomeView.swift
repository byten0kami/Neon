import SwiftUI

// MARK: - Home View (Command Center)

/// Main home screen - displays the infinite timeline with tasks
/// Now uses TimelineEngine for the Master-Instance architecture
struct HomeView: View {
    @StateObject private var brain = AIBrain.shared
    @StateObject private var engine = TimelineEngine.shared
    @StateObject private var overlayManager = OverlayEffectsManager.shared
    
    @State private var stability: Int = 72
    @State private var selectedItem: TimelineItem?
    
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
                StatusHeader(stability: stability)
                
                NeonTimelineView(
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
                        withAnimation {
                            engine.defer(id: item.id, byHours: 1)
                        }
                    }
                )
            }
            
            // Overlay Effects
            if overlayManager.currentEffect == .nyanCat {
                NyanCatView()
                    .transition(.opacity)
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
        .sheet(item: $selectedItem) { item in
            TimelineItemActionsSheet(item: item, onDismiss: {
                selectedItem = nil
            })
        }
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
}

// MARK: - Timeline Item Actions Sheet

/// Actions sheet for TimelineItem (replacing TaskActionsSheet)
struct TimelineItemActionsSheet: View {
    let item: TimelineItem
    let onDismiss: () -> Void
    
    @StateObject private var engine = TimelineEngine.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Item Info
                VStack(alignment: .leading, spacing: 8) {
                    Text(item.title)
                        .font(.custom(Theme.displayFont, size: 24))
                        .foregroundColor(.white)
                    
                    if let description = item.description {
                        Text(description)
                            .font(.custom(Theme.lightFont, size: 16))
                            .foregroundColor(Theme.slate400)
                    }
                    
                    HStack {
                        Text(item.priority.displayName)
                            .font(.custom(Theme.monoFont, size: 12))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(priorityColor.opacity(0.2))
                            .cornerRadius(4)
                        
                        if let recurrence = item.recurrenceText {
                            Text(recurrence)
                                .font(.custom(Theme.monoFont, size: 12))
                                .foregroundColor(Theme.slate500)
                        }
                        
                        if item.mustBeCompleted {
                            Text("REQUIRED")
                                .font(.custom(Theme.monoFont, size: 10))
                                .foregroundColor(Theme.red)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Theme.backgroundSecondary)
                .cornerRadius(8)
                
                Spacer()
                
                // Actions
                VStack(spacing: 12) {
                    if !item.isCompleted {
                        Button(action: {
                            engine.complete(id: item.id)
                            onDismiss()
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Mark Complete")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Theme.lime.opacity(0.2))
                            .foregroundColor(Theme.lime)
                            .cornerRadius(8)
                        }
                        
                        Button(action: {
                            engine.defer(id: item.id, byHours: 1)
                            onDismiss()
                        }) {
                            HStack {
                                Image(systemName: "clock.arrow.circlepath")
                                Text("Defer 1 Hour")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Theme.amber.opacity(0.2))
                            .foregroundColor(Theme.amber)
                            .cornerRadius(8)
                        }
                    }
                    
                    Button(action: {
                        engine.delete(id: item.id)
                        onDismiss()
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.red.opacity(0.2))
                        .foregroundColor(Theme.red)
                        .cornerRadius(8)
                    }
                }
            }
            .padding()
            .background(Theme.backgroundPrimary.ignoresSafeArea())
            .navigationTitle("Item Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        onDismiss()
                    }
                }
            }
        }
    }
    
    private var priorityColor: Color {
        switch item.priority {
        case .critical: return Theme.red
        case .high: return Theme.amber
        case .normal: return Theme.lime
        case .low: return Theme.cyan
        }
    }
}
