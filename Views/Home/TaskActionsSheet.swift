import SwiftUI

// MARK: - Task Actions Sheet

/// Modal sheet for task actions (edit, delete, discuss with AI)
struct TaskActionsSheet: View {
    let task: UserTask
    var onDismiss: () -> Void
    
    @StateObject private var taskStore = TaskStore.shared
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Task Details")
                    .font(.custom(DesignSystem.displayFont, size: 20))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("Done") {
                    onDismiss()
                }
                .font(.custom(DesignSystem.headlineFont, size: 16))
                .foregroundColor(DesignSystem.cyan)
            }
            .padding()
            
            // Task info
            VStack(alignment: .leading, spacing: 12) {
                Text("[TASK]")
                    .font(.custom(DesignSystem.monoFont, size: 11))
                    .foregroundColor(DesignSystem.cyan)
                
                Text(task.title)
                    .font(.custom(DesignSystem.displayFont, size: 18))
                    .foregroundColor(.white)
                
                HStack(spacing: 12) {
                    Label(task.category, systemImage: "folder")
                    Label(task.priority.rawValue, systemImage: "flag")
                }
                .font(.custom(DesignSystem.lightFont, size: 14))
                .foregroundColor(DesignSystem.slate500)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(DesignSystem.backgroundCard)
            .cornerRadius(8)
            .padding(.horizontal)
            
            // Actions
            VStack(spacing: 12) {
                Button {
                    // Discuss with AI
                } label: {
                    Label("DISCUSS WITH AI", systemImage: "bubble.left.and.bubble.right")
                        .font(.custom(DesignSystem.headlineFont, size: 14))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(DesignSystem.cyan)
                        .cornerRadius(8)
                }
                
                HStack(spacing: 12) {
                    Button {
                        // Edit
                    } label: {
                        Label("Edit", systemImage: "pencil")
                            .font(.custom(DesignSystem.headlineFont, size: 14))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(DesignSystem.slate700)
                            .cornerRadius(8)
                    }
                    
                    Button {
                        taskStore.deleteTask(id: task.id)
                        onDismiss()
                    } label: {
                        Label("Delete", systemImage: "trash")
                            .font(.custom(DesignSystem.headlineFont, size: 14))
                            .foregroundColor(DesignSystem.red)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(DesignSystem.backgroundCard)
                            .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .background(DesignSystem.backgroundPrimary)
        .presentationDetents([.medium])
    }
}
