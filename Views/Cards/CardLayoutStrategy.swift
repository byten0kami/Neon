import SwiftUI

// MARK: - Card Layout Strategy Protocol

/// Strategy pattern for card action button layouts
/// Enables adding new layouts without modifying UniversalTimelineCard (OCP)
@MainActor
protocol CardLayoutStrategy {
    associatedtype Body: View
    
    @ViewBuilder
    func actionsView(
        actions: [TimelineCardAction],
        isCompleted: Bool
    ) -> Body
}

// MARK: - Classic Text Layout

/// Legacy layout - text buttons in a horizontal row at the bottom
@MainActor
struct ClassicTextLayout: CardLayoutStrategy {
    private var tagFont: String { ThemeManager.shared.currentTheme.tagFont }
    
    func actionsView(actions: [TimelineCardAction], isCompleted: Bool) -> some View {
        Group {
            if !actions.isEmpty && !isCompleted {
                HStack(spacing: 12) {
                    ForEach(actions.indices, id: \.self) { index in
                        let action = actions[index]
                        CardActionButton(
                            label: action.title,
                            color: action.color,
                            isFilled: action.isFilled,
                            stretch: true,
                            action: action.action
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Side Icon Layout

/// Icon-only buttons in a vertical panel on the right side
@MainActor
struct SideIconLayout: CardLayoutStrategy {
    func actionsView(actions: [TimelineCardAction], isCompleted: Bool) -> some View {
        Group {
            if !actions.isEmpty && !isCompleted {
                VStack(spacing: 0) {
                    ForEach(actions.indices, id: \.self) { index in
                        let action = actions[index]
                        let isLast = index == actions.count - 1
                        
                        CardActionIconButton(
                            color: action.color,
                            icon: action.icon,
                            isFilled: action.isFilled,
                            stretchAxis: nil,
                            isPanelMode: true,
                            action: action.action
                        )
                        .frame(height: Constants.buttonHeight)
                        
                        if !isLast {
                            divider(horizontal: true)
                        }
                    }
                }
                .frame(width: Constants.panelWidth)
                .frame(minHeight: CGFloat(actions.count) * Constants.buttonHeight)
                .background(Color.black.opacity(0.2))
                .overlay(
                    Rectangle()
                        .fill(DesignSystem.slate700.opacity(0.3))
                        .frame(width: 1),
                    alignment: .leading
                )
            }
        }
    }
    
    private func divider(horizontal: Bool) -> some View {
        Rectangle()
            .fill(DesignSystem.slate700.opacity(0.3))
            .frame(width: horizontal ? nil : 1, height: horizontal ? 1 : nil)
            .padding(horizontal ? .horizontal : .vertical, 8)
    }
    
    private enum Constants {
        static let buttonHeight: CGFloat = 50
        static let panelWidth: CGFloat = 50
    }
}

// MARK: - Bottom Icon Layout

/// Icon-only buttons in a horizontal panel at the bottom
@MainActor
struct BottomIconLayout: CardLayoutStrategy {
    func actionsView(actions: [TimelineCardAction], isCompleted: Bool) -> some View {
        Group {
            if !actions.isEmpty && !isCompleted {
                HStack(spacing: 0) {
                    ForEach(actions.indices, id: \.self) { index in
                        let action = actions[index]
                        let isLast = index == actions.count - 1
                        
                        CardActionIconButton(
                            color: action.color,
                            icon: action.icon,
                            isFilled: action.isFilled,
                            stretchAxis: .horizontal,
                            isPanelMode: true,
                            action: action.action
                        )
                        
                        if !isLast {
                            Rectangle()
                                .fill(DesignSystem.slate700.opacity(0.3))
                                .frame(width: 1)
                                .padding(.vertical, 8)
                        }
                    }
                }
                .frame(height: 36)
                .background(Color.black.opacity(0.2))
                .cornerRadius(CardStyle.cornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: CardStyle.cornerRadius)
                        .stroke(DesignSystem.slate700.opacity(0.3), lineWidth: 1)
                )
            }
        }
    }
}

// MARK: - Layout Factory

/// Factory to get the appropriate layout strategy based on settings
enum CardLayoutFactory {
    @MainActor
    static func strategy(for mode: APISettings.CardLayoutMode) -> any CardLayoutStrategy {
        switch mode {
        case .classic:
            return ClassicTextLayout()
        case .side:
            return SideIconLayout()
        case .bottom:
            return BottomIconLayout()
        }
    }
}

