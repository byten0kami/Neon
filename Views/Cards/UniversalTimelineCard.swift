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
        .padding(.vertical, showConnector ? 10 : 0)
        .opacity(config.isOverdue ? blinkOpacity : 1.0)
        .onAppear {
            if config.isOverdue { startBlinkAnimation() }
        }
    }
    
    // Helper to calculate actions
    private var separateActions: [TimelineCardAction] {
        var actions = config.actions
        
        // Sort Order: AI -> SKIP -> DEFER -> DONE
        actions.sort { a, b in
            func weight(_ action: TimelineCardAction) -> Int {
                if let icon = action.icon {
                    if icon.contains("brain") { return -1 } // AI First
                    if icon.contains("xmark") || icon.contains("turn.up.right") { return 0 } // Skip
                    if icon.contains("arrow.clockwise") || icon.contains("clock") { return 1 } // Defer
                    if icon.contains("checkmark") { return 2 } // Done
                }
                let t = action.title.lowercased()
                if t.contains("ai") { return -1 }
                if t.contains("skip") { return 0 }
                if t.contains("defer") { return 1 }
                if t.contains("done") { return 2 }
                return 10
            }
            return weight(a) < weight(b)
        }
        
        return actions
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
            .padding(.horizontal, CardStyle.padding)
            .padding(.top, CardStyle.padding)
            .padding(.bottom, 8)
            
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
        .overlay(
            HStack(spacing: 6) {
                PriorityTag(text: config.badgeText, color: config.accentColor, style: config.priorityTagStyle)
                
                if let recurrence = config.recurrence {
                    Text(recurrence.lowercased())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(config.accentColor.opacity(0.1))
                        .cornerRadius(4)
                        .font(.custom(theme.tagFont, size: 12))
                        .foregroundColor(config.accentColor)
                }
            }
            .offset(y: -5)
            .padding(.leading, 12),
            alignment: .topLeading
        )
        .overlay(
            HStack(spacing: 6) {
                if let duration = config.durationText {
                    Text(duration)
                        .font(.custom(theme.tagFont, size: 12))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(config.accentColor.opacity(0.1))
                        .cornerRadius(4)
                        .foregroundColor(config.accentColor)
                }
                
                if let time = config.time {
                    Text(time)
                        .font(.custom(theme.timeFont, size: 14))
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(DesignSystem.backgroundSecondary)
                        .cornerRadius(CardStyle.cornerRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: CardStyle.cornerRadius)
                                .stroke(config.isDeferred ? DesignSystem.amber : config.accentColor, lineWidth: 1)
                        )
                        .foregroundColor(config.isDeferred ? DesignSystem.amber : .white)
                        .shadow(
                            color: config.isSkipped ? DesignSystem.red.opacity(0.8) :
                                (config.isCompleted ? DesignSystem.green.opacity(0.8) :
                                    config.accentColor.opacity(0.8)),
                            radius: 5
                        )
                }
            }
            .offset(y: -5)
            .padding(.trailing, 12),
            alignment: .topTrailing
        )
        .padding(.trailing, showConnector ? 16 : 0)
    }
    
    /// Actions rendered via selected layout strategy
    @ViewBuilder
    private var actionsByStrategy: some View {
        let mode = apiSettings.settings.cardLayoutMode
        let actions = separateActions
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
        VStack(alignment: .leading, spacing: 2) {
            // Title (white text for active, grey for completed)
            Text(config.title)
                .font(.custom(theme.titleFont, size: 18))
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
