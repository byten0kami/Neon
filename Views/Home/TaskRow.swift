import SwiftUI

struct TaskRow: View {
    let item: TimelineItem
    
    var body: some View {
        HStack(spacing: 12) {
            // Priority Indicator / Time
            VStack(alignment: .trailing, spacing: 2) {
                if item.seriesId != nil {
                    // Recurring
                    Image(systemName: "repeat")
                        .font(.system(size: 10))
                        .foregroundColor(DesignSystem.slate500)
                }
                
                Text(timeString(from: item.effectiveTime))
                    .font(.custom(DesignSystem.monoFont, size: 12))
                    .foregroundColor(DesignSystem.slate400)
            }
            .frame(width: 50, alignment: .trailing)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.custom(DesignSystem.displayFont, size: 16))
                    .foregroundColor(item.isCompleted ? DesignSystem.slate500 : .white)
                    .strikethrough(item.isCompleted)
                
                if let description = item.description, !description.isEmpty {
                    Text(description)
                        .font(.custom(DesignSystem.lightFont, size: 14))
                        .foregroundColor(DesignSystem.slate500)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Priority dot
            Circle()
                .fill(priorityColor)
                .frame(width: 8, height: 8)
        }
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    private var priorityColor: Color {
        switch item.priority {
        case .critical: return DesignSystem.red
        case .ai: return DesignSystem.purple
        case .high: return DesignSystem.amber
        case .normal: return DesignSystem.lime
        case .low: return DesignSystem.cyan
        }
    }
}
