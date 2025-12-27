import SwiftUI

// MARK: - Card Preview Bubble

/// Renders pending AI actions as card previews with Accept/Deny buttons
struct CardPreviewBubble: View {
    let actions: [AIAction]
    let onAccept: (AIAction) -> Void
    let onDeny: (AIAction) -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(actions.enumerated()), id: \.offset) { index, action in
                cardPreview(for: action)
            }
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private func cardPreview(for action: AIAction) -> some View {
        switch action {
        case .createTimelineItem(let title, _, let priority, let time, let recurrence):
            previewCard(
                title: title,
                priority: priority,
                time: time,
                recurrence: recurrence?.frequency.uppercased(),
                action: action
            )
            
        case .addFact(_, _, _):
            // Facts are auto-executed, no preview needed
            EmptyView()
            
        case .updateFact:
            EmptyView()
        }
    }
    
    private func previewCard(
        title: String,
        priority: String,
        time: String?,
        recurrence: String?,
        action: AIAction
    ) -> some View {
        // Convert priority string to ItemPriority and get theme-aware style
        let itemPriority = ItemPriority(from: priority)
        let style = themeManager.priorityTagStyle(for: itemPriority)
        let accentColor = style.color
        
        return VStack(alignment: .leading, spacing: 6) {
            // Header
            HStack(alignment: .center, spacing: 8) {
                PriorityTag(text: style.text, color: accentColor)
                
                if let recurrence = recurrence {
                    Text(recurrence.lowercased())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(accentColor.opacity(0.1))
                        .cornerRadius(4)
                        .font(.custom(DesignSystem.monoFont, size: 12))
                        .foregroundColor(accentColor)
                }
                
                Spacer()
                
                if let time = time {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .shadow(color: accentColor.opacity(0.8), radius: 5)
                        
                        Text(time)
                            .font(.custom(DesignSystem.monoFont, size: 16))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .shadow(color: accentColor.opacity(0.8), radius: 5)
                    }
                }
            }
            
            // Title
            Text(title)
                .font(.custom(DesignSystem.displayFont, size: 18))
                .foregroundColor(.white)
                .shadow(color: accentColor.opacity(0.6), radius: 6)
                .padding(.top, 4)
            
            // Separator
            Rectangle()
                .fill(accentColor.opacity(0.3))
                .frame(height: 1)
                .padding(.vertical, 4)
            
            // Action buttons
            HStack(spacing: 12) {
                CardActionButton(
                    label: "Add",
                    color: accentColor,
                    icon: "checkmark",
                    isFilled: true
                ) {
                    onAccept(action)
                }
                
                CardActionButton(
                    label: "Skip",
                    color: DesignSystem.slate500,
                    icon: "xmark",
                    isFilled: false
                ) {
                    onDeny(action)
                }
            }
        }
        .padding(CardStyle.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CardBackground(accentColor: accentColor))
    }
}
