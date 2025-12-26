import SwiftUI

// MARK: - Home View (Command Center)

/// Main home screen - displays the infinite timeline with tasks
/// Uses components from Views/Timeline/ for SOLID architecture
struct HomeView: View {
    @StateObject private var brain = AIBrain.shared
    @StateObject private var taskStore = TaskStore.shared
    @StateObject private var overlayManager = OverlayEffectsManager.shared
    
    @State private var stability: Int = 72
    @State private var selectedTask: UserTask?
    
    private var isLowStability: Bool {
        stability < 50
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                StatusHeader(stability: stability)
                
                NeonTimelineView(
                    selectedTask: $selectedTask,
                    completedTasks: taskStore.completedTasks().reversed(),
                    pendingTasks: taskStore.pendingTasks(),
                    onCompleteTask: { task in
                        taskStore.completeTask(id: task.id)
                        QuestManager.shared.reportEvent(.taskCompleted)
                    },
                    onDeleteTask: { task in
                        withAnimation {
                            taskStore.deleteTask(id: task.id)
                        }
                    },
                    onDeferTask: { task in
                        withAnimation {
                            taskStore.deferTask(id: task.id, by: 1) // Default +1 hour
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
        .sheet(item: $selectedTask) { task in
            TaskActionsSheet(task: task, onDismiss: {
                selectedTask = nil
            })
        }
    }
}
