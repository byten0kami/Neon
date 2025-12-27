import SwiftUI

struct EditTaskOverlay: View {
    @Binding var item: TimelineItem
    let onSave: (TimelineItem) -> Void
    let onCancel: () -> Void
    let onDelete: () -> Void
    
    @State private var editedTitle: String = ""
    @State private var editedDescription: String = ""
    @State private var editedPriority: ItemPriority = .normal
    
    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    onCancel()
                }
            
            // Card Content
            VStack(spacing: 20) {
                // Header
                HStack {
                    Text("EDIT TASK")
                        .font(.custom(DesignSystem.monoFont, size: 14))
                        .foregroundColor(DesignSystem.slate500)
                        .tracking(2)
                    
                    Spacer()
                    
                    Button(action: onCancel) {
                        Image(systemName: "xmark")
                            .foregroundColor(DesignSystem.slate500)
                    }
                }
                
                // Fields
                VStack(spacing: 16) {
                    // Title Input
                    TextField("", text: $editedTitle)
                        .font(.custom(DesignSystem.displayFont, size: 20))
                        .foregroundColor(.white)
                        .placeholder(when: editedTitle.isEmpty) {
                            Text("Task Title")
                                .foregroundColor(DesignSystem.slate600)
                                .font(.custom(DesignSystem.displayFont, size: 20))
                        }
                        .padding(12)
                        .background(DesignSystem.backgroundSecondary)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(DesignSystem.slate700, lineWidth: 1)
                        )
                    
                    // Description Input
                    TextField("", text: $editedDescription)
                        .font(.custom(DesignSystem.lightFont, size: 16))
                        .foregroundColor(DesignSystem.slate300)
                        .placeholder(when: editedDescription.isEmpty) {
                            Text("Description (optional)")
                                .foregroundColor(DesignSystem.slate600)
                                .font(.custom(DesignSystem.lightFont, size: 16))
                        }
                        .padding(12)
                        .background(DesignSystem.backgroundSecondary)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(DesignSystem.slate700, lineWidth: 1)
                        )
                    
                    // Priority Selector
                    HStack(spacing: 12) {
                        ForEach(ItemPriority.allCases, id: \.self) { priority in
                            if priority != .ai { // Avoid selecting AI priority manually if preferred
                                PriorityButton(
                                    priority: priority,
                                    isSelected: editedPriority == priority,
                                    action: { editedPriority = priority }
                                )
                            }
                        }
                    }
                }
                
                // Actions
                HStack(spacing: 12) {
                    // Delete Button
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 16))
                            .foregroundColor(DesignSystem.red)
                            .padding()
                            .frame(width: 50)
                            .background(DesignSystem.red.opacity(0.1))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(DesignSystem.red.opacity(0.3), lineWidth: 1)
                            )
                    }
                    
                    // Save Button
                    Button(action: save) {
                        Text("SAVE CHANGES")
                            .font(.custom(DesignSystem.monoFont, size: 14))
                            .fontWeight(.bold)
                            .foregroundColor(DesignSystem.backgroundPrimary)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(DesignSystem.lime) // Neon Lime for action
                            .cornerRadius(8)
                            .shadow(color: DesignSystem.lime.opacity(0.5), radius: 10)
                    }
                }
            }
            .padding(24)
            .background(DesignSystem.backgroundPrimary)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(DesignSystem.lime.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: DesignSystem.lime.opacity(0.1), radius: 20)
            .padding(.horizontal, 24)
            .onAppear {
                loadItem()
            }
        }
        .transition(.opacity)
        .zIndex(200) // Ensure it's above everything
    }
    
    private func loadItem() {
        editedTitle = item.title
        editedDescription = item.description ?? ""
        editedPriority = item.priority
    }
    
    private func save() {
        var updatedItem = item
        updatedItem.title = editedTitle
        updatedItem.description = editedDescription.isEmpty ? nil : editedDescription
        updatedItem.priority = editedPriority
        onSave(updatedItem)
    }
}

// Helper: Custom Placeholder
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {

        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

struct PriorityButton: View {
    let priority: ItemPriority
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Circle()
                .fill(color)
                .frame(width: 24, height: 24)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: isSelected ? 2 : 0)
                )
                .shadow(color: color.opacity(0.6), radius: isSelected ? 8 : 0)
        }
    }
    
    private var color: Color {
        switch priority {
        case .critical: return DesignSystem.red
        case .high: return DesignSystem.amber
        case .normal: return DesignSystem.lime
        case .low: return DesignSystem.cyan
        case .ai: return DesignSystem.purple
        }
    }
}
