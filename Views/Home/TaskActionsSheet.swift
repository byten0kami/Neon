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
                    .font(.custom(Theme.displayFont, size: 20))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("Done") {
                    onDismiss()
                }
                .font(.custom(Theme.headlineFont, size: 16))
                .foregroundColor(Theme.cyan)
            }
            .padding()
            
            // Task info
            VStack(alignment: .leading, spacing: 12) {
                Text("[TASK]")
                    .font(.custom(Theme.monoFont, size: 11))
                    .foregroundColor(Theme.cyan)
                
                Text(task.title)
                    .font(.custom(Theme.displayFont, size: 18))
                    .foregroundColor(.white)
                
                HStack(spacing: 12) {
                    Label(task.category, systemImage: "folder")
                    Label(task.priority.rawValue, systemImage: "flag")
                }
                .font(.custom(Theme.lightFont, size: 14))
                .foregroundColor(Theme.slate500)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Theme.backgroundCard)
            .cornerRadius(8)
            .padding(.horizontal)
            
            // Actions
            VStack(spacing: 12) {
                Button {
                    // Discuss with AI
                } label: {
                    Label("DISCUSS WITH AI", systemImage: "bubble.left.and.bubble.right")
                        .font(.custom(Theme.headlineFont, size: 14))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.cyan)
                        .cornerRadius(8)
                }
                
                HStack(spacing: 12) {
                    Button {
                        // Edit
                    } label: {
                        Label("Edit", systemImage: "pencil")
                            .font(.custom(Theme.headlineFont, size: 14))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Theme.slate700)
                            .cornerRadius(8)
                    }
                    
                    Button {
                        taskStore.deleteTask(id: task.id)
                        onDismiss()
                    } label: {
                        Label("Delete", systemImage: "trash")
                            .font(.custom(Theme.headlineFont, size: 14))
                            .foregroundColor(Theme.red)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Theme.backgroundCard)
                            .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .background(Theme.backgroundPrimary)
        .presentationDetents([.medium])
    }
}
