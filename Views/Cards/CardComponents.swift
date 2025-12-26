import SwiftUI

// MARK: - Shared Card Components
// Shared styling and sub-views used by UniversalTimelineCard

// MARK: - Timeline Card Type Enum

/// Formalized card types for the timeline
/// Formalized card types for the timeline
enum TimelineCardType {
    case task       // Standard Task (Blue/Cyan)
    case reminder   // Reminder (Amber)
    case info       // Info (Slate/Gray)
    case insight    // Insight (Purple)
    case asap       // Urgent / ASAP (Red)
    
    var color: Color {
        switch self {
        case .task: return Theme.lime
        case .reminder: return Theme.amber
        case .info: return Theme.cyan
        case .insight: return Theme.purple
        case .asap: return Theme.red
        }
    }
    
    var label: String {
        switch self {
        case .task: return "TASK"
        case .reminder: return "RMD"
        case .info: return "INFO"
        case .insight: return "INSIGHT"
        case .asap: return "ASAP"
        }
    }
    
    /// Map categories to new formal types
    static func from(category: String) -> TimelineCardType {
        switch category.lowercased() {
        case "reminder", "remind": return .reminder
        case "insight", "suggestion", "proto": return .insight
        case "info", "log", "config": return .info
        case "asap", "urgent": return .asap
        default: return .task
        }
    }
}

// MARK: - Card Styling

/// Shared card styling constants
enum CardStyle {
    static let borderWidth: CGFloat = 3
    static let cornerRadius: CGFloat = 2 // Less rounded
    static let padding: CGFloat = 16
    static let dotSize: CGFloat = 12
    static let connectorWidth: CGFloat = 24
    static let buttonHeight: CGFloat = 26 // Reduced to 2/3 of original
    static let buttonPaddingH: CGFloat = 16 // Adjusted padding
    static let buttonPaddingV: CGFloat = 4
}

// MARK: - Card Grid Pattern



// MARK: - Card Scanline Effect (for completed cards only)
struct CardScanlineEffect: View {
    let color: Color
    
    var body: some View {
        Canvas { context, size in
            let lineSpacing: CGFloat = 3
            var y: CGFloat = 0
            
            while y < size.height {
                let rect = CGRect(x: 0, y: y + (lineSpacing / 2), width: size.width, height: lineSpacing / 2)
                context.fill(Path(rect), with: .color(color.opacity(0.15)))
                y += lineSpacing
            }
        }
    }
}

// MARK: - Card Background

/// Reusable card background with colored left border and color-tinted interior
struct CardBackground: View {
    let accentColor: Color
    var isCompleted: Bool = false
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Background matches tab background - outlined by glow/grid, not color
            Rectangle()
                .fill(Theme.backgroundSecondary)
            

            
            // Scanline overlay - ONLY for completed cards (archived look)
            if isCompleted {
                CardScanlineEffect(color: accentColor)
                    .clipped()
            }
            
            // Left accent border
            Rectangle()
                .fill(accentColor)
                .frame(width: CardStyle.borderWidth)
        }
        .cornerRadius(CardStyle.cornerRadius)
        // Card has a small glow + border glow (less for completed)
        .overlay(
            RoundedRectangle(cornerRadius: CardStyle.cornerRadius)
                .stroke(accentColor.opacity(isCompleted ? 0.2 : 0.3), lineWidth: 1)
        )
        .shadow(color: accentColor.opacity(isCompleted ? 0.1 : 0.2), radius: 10, x: 0, y: 0)
    }
}

// MARK: - Card Action Button

/// Reusable action button for cards - FILLED style matching card accent color
/// Styled badge with frame (matching button style)
struct CardBadge: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.custom(Theme.monoFont, size: 11))
            .fontWeight(.bold)
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .overlay(
                RoundedRectangle(cornerRadius: CardStyle.cornerRadius)
                    .stroke(color, lineWidth: 1)
            )
    }
}

// MARK: - Card Action Button

/// Reusable action button for cards
struct CardActionButton: View {
    let label: String
    var color: Color = Theme.cyan
    var icon: String? = nil  // SF Symbol name
    var isFilled: Bool = false
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let iconName = icon {
                    Image(systemName: iconName)
                        .font(.system(size: 12, weight: .bold))
                }
                Text(label)
                    .font(.custom(Theme.monoFont, size: 12))
                    .fontWeight(.bold)
            }
            .foregroundColor(color)
            .padding(.horizontal, CardStyle.buttonPaddingH)
            .padding(.vertical, CardStyle.buttonPaddingV)
            .frame(height: CardStyle.buttonHeight)
            .background(isFilled ? color.opacity(0.15) : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: CardStyle.cornerRadius)
                    .stroke(color, lineWidth: 1)
            )
            .cornerRadius(CardStyle.cornerRadius)
        }
        .buttonStyle(.borderless)
    }
}

// MARK: - Timeline Connector

/// Dot and horizontal line connecting card to timeline
/// Dot is positioned at x=35 in the parent ZStack coordinate system
struct TimelineConnector: View {
    let color: Color
    var isCompleted: Bool = false
    
    var body: some View {
        ZStack(alignment: .center) {
            // Horizontal branch line - from center (35) to right
            HStack(spacing: 0) {
                Spacer().frame(width: 35)
                Rectangle()
                    .fill(color.opacity(isCompleted ? 0.3 : 0.5))
                    .frame(height: 2)
            }
            
            // Dot (centered at x=35)
            Circle()
                .fill(isCompleted ? Theme.slate600 : color)
                .frame(width: CardStyle.dotSize, height: CardStyle.dotSize)
                .shadow(color: isCompleted ? .clear : color.opacity(0.6), radius: 4)
        }
        .frame(width: 70)
    }
}
