import SwiftUI

// MARK: - Universal Timeline Card

/// A generic card view that can take any shape based on configuration
/// Acts as the "Base" component for the "Base + Decorator" pattern
struct UniversalTimelineCard: View {
    let config: CardConfig
    var onTap: (() -> Void)? = nil
    var showConnector: Bool = true
    
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var apiSettings = APISettingsStore.shared
    @State private var blinkOpacity: Double = 1.0
    
    // Get fonts from current theme
    private var theme: any Theme { themeManager.currentTheme }
    
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
    
    // Helper to calculate actions excluding AI
    private var separateActions: (main: [TimelineCardAction], ai: TimelineCardAction?) {
        let ai = config.actions.first(where: { $0.icon == "brain" || $0.icon == "brain.head.profile" })
        var main = config.actions.filter { $0.icon != "brain" && $0.icon != "brain.head.profile" }
        
        // Sort Order: SKIP -> DEFER -> DONE
        // We use weights based on action title or common identifiers.
        // Assuming Titles: "Skip", "Defer", "Done" (or icon names if titles vary)
        main.sort { a, b in
            func weight(_ action: TimelineCardAction) -> Int {
                // Check icon names first as they are more stable in code
                if let icon = action.icon {
                    if icon.contains("xmark") { return 0 } // Skip
                    if icon.contains("arrow.clockwise") || icon.contains("clock") { return 1 } // Defer
                    if icon.contains("checkmark") { return 2 } // Done
                }
                // Fallback to title
                let t = action.title.lowercased()
                if t.contains("skip") { return 0 }
                if t.contains("defer") { return 1 }
                if t.contains("done") { return 2 }
                return 10
            }
            return weight(a) < weight(b)
        }
        
        return (main, ai)
    }
    
    private var cardContent: some View {
        HStack(spacing: 0) {
            // MAIN CONTENT AREA
            VStack(alignment: .leading, spacing: 6) {
                // Header, Title, Description
                mainInfoContent
                
                // Bottom/Classic actions rendered in main VStack
                if apiSettings.settings.cardLayoutMode != .side {
                    actionsByStrategy
                }
            }
            .padding(CardStyle.padding)
            
            // Side panel layout (rendered outside main VStack)
            if apiSettings.settings.cardLayoutMode == .side {
                actionsByStrategy
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CardBackground(
            accentColor: displayColor,
            isCompleted: config.isCompleted,
            isSkipped: config.isSkipped
        ))
        .padding(.trailing, showConnector ? 16 : 0)
    }
    
    /// Actions rendered via selected layout strategy
    @ViewBuilder
    private var actionsByStrategy: some View {
        let mode = apiSettings.settings.cardLayoutMode
        let actions = separateActions.main
        let isCompleted = config.isCompleted
        
        switch mode {
        case .classic:
            ClassicTextLayout().actionsView(actions: actions, isCompleted: isCompleted)
        case .side:
            SideIconLayout().actionsView(actions: actions, isCompleted: isCompleted)
        case .bottom:
            BottomIconLayout().actionsView(actions: actions, isCompleted: isCompleted)
        }
    }
    
    // MARK: - Sub-Components
    
    private var mainInfoContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header: Badge + Recurrence Flag + AI Button on left, Time with clock icon on right
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
                        .font(.custom(theme.tagFont, size: 12))
                        .foregroundColor(config.accentColor)
                }
                
                // AI Button (Moved from actions)
                if let aiAction = separateActions.ai {
                     Button(action: aiAction.action) {
                         Image(systemName: aiAction.icon ?? "brain")
                             .font(.system(size: 11, weight: .bold)) // Match Tag Font Size
                             .foregroundColor(aiAction.color)
                             .padding(.horizontal, 8) // Match Tag Padding
                             .padding(.vertical, 4)   // Match Tag Padding
                             // Remove background fill as requested ("neon border and icon inside")
                             .background(Color.clear) 
                             .overlay(
                                RoundedRectangle(cornerRadius: CardStyle.cornerRadius)
                                    .stroke(aiAction.color, lineWidth: 1)
                             )
                             .cornerRadius(CardStyle.cornerRadius)
                     }
                     .buttonStyle(PlainButtonStyle())
                }
                
                Spacer()
                
                // Right side: Time with clock icon
                if let time = config.time {
                    HStack(spacing: 4) {
                        Image(systemName: config.isSkipped ? "xmark" : (config.isCompleted ? "checkmark" : (config.isDeferred ? "arrow.clockwise" : "clock")))
                            .font(.system(size: 14))
                            // User requested white text/icon with colored glow for skipped/completed
                            .foregroundColor(config.isDeferred ? DesignSystem.amber : .white)
                            .shadow(
                                color: config.isSkipped ? DesignSystem.red.opacity(0.8) :
                                    (config.isCompleted ? DesignSystem.green.opacity(0.8) :
                                        config.accentColor.opacity(0.8)),
                                radius: 5
                            )
                        
                        Text(time)
                            .font(.custom(theme.timeFont, size: 16))
                            .fontWeight(.bold)
                            // User requested white text/icon with colored glow for skipped/completed
                            .foregroundColor(config.isDeferred ? DesignSystem.amber : .white)
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
                .font(.custom(theme.titleFont, size: 18))
                //.fontWeight(.bold)
                .foregroundColor(config.isCompleted ? DesignSystem.slate500 : .white)
                .shadow(color: config.isCompleted ? .clear : config.accentColor.opacity(0.6), radius: 6) // Glow for title
                .padding(.top, 4)
            
            // Description (grey text - slate400 to match reference)
            if let description = config.description, !description.isEmpty {
                Text(description)
                    .font(.custom(theme.bodyFont, size: theme.bodyFontSize))
                    .foregroundColor(DesignSystem.slate400)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if !config.isCompleted { onTap?() }
        }
    }
    
    // Layout implementations moved to CardLayoutStrategy.swift

    
    private func startBlinkAnimation() {
        withAnimation(
            .easeInOut(duration: 0.8)
            .repeatForever(autoreverses: true)
        ) {
            blinkOpacity = 0.5
        }
    }
}
