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
    @State private var showingCalendar = false
    
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
    
    @State private var deferItem: TimelineItem? // Item pending deferral confirmation
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                StatusHeader(
                    stability: stability,
                    onCalendarTap: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showingCalendar = true
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
                        withAnimation {
                            deferItem = item
                        }
                    },
                    onSkipItem: { item in
                        skipItem(item)
                    }
                )
            }
            .blur(radius: (selectedItem != nil || deferItem != nil) ? 5 : 0) // Blur background when overlay active
            
            // Overlay Effects
            if overlayManager.currentEffect == .nyanCat {
                NyanCatView()
                    .transition(.opacity)
            }
            
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
            
            // Defer Confirmation Modal
            if let item = deferItem {
                ZStack {
                    Color.black.opacity(0.5).ignoresSafeArea()
                        .onTapGesture { deferItem = nil }
                    
                    VStack(spacing: 16) {
                        Text("Defer Task?")
                            .font(.custom(DesignSystem.monoFont, size: 14))
                            .foregroundColor(DesignSystem.slate500)
                        
                        Text(item.title)
                            .font(.custom(DesignSystem.displayFont, size: 18))
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                        
                        Text("Defer 'In 1 Hour'?")
                            .font(.custom(DesignSystem.lightFont, size: 16))
                            .foregroundColor(DesignSystem.slate300)
                        
                        HStack(spacing: 12) {
                            Button(action: {
                                // No - Open Edit Task
                                deferItem = nil
                                selectedItem = item
                            }) {
                                Text("No, Edit")
                                    .font(.custom(DesignSystem.monoFont, size: 14))
                                    .foregroundColor(DesignSystem.slate400)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(DesignSystem.backgroundSecondary)
                                    .cornerRadius(8)
                            }
                            
                            Button(action: {
                                // Yes - Defer 1 Hour
                                withAnimation {
                                    engine.defer(id: item.id, byHours: 1)
                                    deferItem = nil
                                }
                            }) {
                                Text("Yes (1h)")
                                    .font(.custom(DesignSystem.monoFont, size: 14))
                                    .fontWeight(.bold)
                                    .foregroundColor(DesignSystem.backgroundPrimary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(DesignSystem.amber)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(24)
                    .background(DesignSystem.backgroundPrimary)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(DesignSystem.amber.opacity(0.5), lineWidth: 1)
                    )
                    .shadow(color: DesignSystem.amber.opacity(0.2), radius: 20)
                    .padding(.horizontal, 40)
                }
                .transition(.opacity)
                .zIndex(300)
            }
            
            if showingCalendar {
                MonthCalendarView(isPresented: $showingCalendar)
                    .transition(.move(edge: .top))
                    .zIndex(100)
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
