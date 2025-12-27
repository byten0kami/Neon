import SwiftUI

// MARK: - Universal Timeline Card

/// A generic card view that can take any shape based on configuration
/// Acts as the "Base" component for the "Base + Decorator" pattern
struct UniversalTimelineCard: View {
    let config: CardConfig
    var onTap: (() -> Void)? = nil
    var showConnector: Bool = true
    
    @State private var blinkOpacity: Double = 1.0
    
    // Computed property to determine the display color
    // Completed tasks are usually grayed out (Slate)
    private var displayColor: Color {
        config.isCompleted ? DesignSystem.slate600 : config.accentColor
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            // 1. Timeline Connector (optional)
            if showConnector {
                TimelineConnector(
                    color: displayColor,
                    isCompleted: config.isCompleted,
                    isSkipped: config.isSkipped
                )
            }
            
            // 2. Card Content
            cardContent
        }
        .padding(.vertical, showConnector ? 4 : 0)
        .opacity(config.isOverdue ? blinkOpacity : 1.0)
        .onAppear {
            if config.isOverdue { startBlinkAnimation() }
        }
    }
    
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            
            // Content Area (Tappable)
            VStack(alignment: .leading, spacing: 6) {
                // Header: Badge + Recurrence Flag on left, Time with clock icon on right
            HStack(alignment: .center, spacing: 8) {
                // Left side: Badge and recurrence flag
                PriorityTag(text: config.badgeText, color: config.accentColor, style: config.priorityTagStyle)
                
                // Recurrence flag next to badge (styled as grey text)
                if let recurrence = config.recurrence {
                    Text(recurrence.lowercased())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(config.accentColor.opacity(0.1))
                        .cornerRadius(4)
                        .font(.custom(DesignSystem.monoFont, size: 12))
                        .foregroundColor(config.accentColor)
                }
                
                Spacer()
                
                // Right side: Time with clock icon
                if let time = config.time {
                    HStack(spacing: 4) {
                        Image(systemName: config.isSkipped ? "xmark" : (config.isCompleted ? "checkmark" : (config.isDeferred ? "arrow.clockwise" : "clock")))
                            .font(.system(size: 14))
                            .foregroundColor(
                                config.isSkipped ? DesignSystem.red :
                                (config.isCompleted ? DesignSystem.green :
                                (config.isDeferred ? DesignSystem.amber : .white))
                            )
                            .shadow(
                                color: config.isSkipped ? DesignSystem.red.opacity(0.8) :
                                (config.isCompleted ? DesignSystem.green.opacity(0.8) :
                                config.accentColor.opacity(0.8)),
                                radius: 5
                            )
                        
                        Text(time)
                            .font(.custom(DesignSystem.monoFont, size: 16))
                            .fontWeight(.bold)
                            .foregroundColor(
                                config.isSkipped ? DesignSystem.red :
                                (config.isCompleted ? DesignSystem.green :
                                (config.isDeferred ? DesignSystem.amber : .white))
                            )
                            .shadow(
                                color: config.isSkipped ? DesignSystem.red.opacity(0.8) :
                                (config.isCompleted ? DesignSystem.green.opacity(0.8) :
                                config.accentColor.opacity(0.8)),
                                radius: 5
                            )
                    }
                }
            }
            
            // Title (white text for active, grey for completed)
            Text(config.title)
                .font(.custom(DesignSystem.displayFont, size: 18))
                //.fontWeight(.bold)
                .foregroundColor(config.isCompleted ? DesignSystem.slate500 : .white)
                .shadow(color: config.isCompleted ? .clear : config.accentColor.opacity(0.6), radius: 6) // Glow for title
                .padding(.top, 4)
            
            // Description (grey text - slate400 to match reference)
            if let description = config.description, !description.isEmpty {
                Text(description)
                    .font(.custom(DesignSystem.lightFont, size: 14))
                    .foregroundColor(DesignSystem.slate400)
            }
            
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if !config.isCompleted { onTap?() }
            }
            
            // Action Buttons (Decorators)
            // Only show if actions exist and task is not completed
            if !config.actions.isEmpty && !config.isCompleted {
                // Delimiter
                Rectangle()
                    .fill(displayColor.opacity(0.3))
                    .frame(height: 1)
                    .padding(.vertical, 4) // Less margin on underline
                    
                HStack(spacing: 12) {
                    Spacer()
                    ForEach(config.actions.indices, id: \.self) { index in
                        let action = config.actions[index]
                        CardActionButton(
                            label: action.title,
                            color: action.color,
                            icon: action.icon,
                            isFilled: action.isFilled,
                            action: action.action
                        )
                    }
                }
            }
        }
        .padding(CardStyle.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CardBackground(
            accentColor: displayColor,
            isCompleted: config.isCompleted,
            isSkipped: config.isSkipped
        ))
        .padding(.trailing, showConnector ? 16 : 0)
    }
    
    private func startBlinkAnimation() {
        withAnimation(
            .easeInOut(duration: 0.8)
            .repeatForever(autoreverses: true)
        ) {
            blinkOpacity = 0.5
        }
    }
}
