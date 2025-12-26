import SwiftUI

// MARK: - History View (Placeholder)

/// System Logs view - TO BE IMPLEMENTED
/// Currently shows placeholder while CMD tab is in active development
struct HistoryView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("[LOGS]")
                .font(.custom(DesignSystem.monoFont, size: 24))
                .foregroundColor(DesignSystem.amber)
            
            Text("SYSTEM LOGS")
                .font(.custom(DesignSystem.displayFont, size: 32))
                .foregroundColor(.white)
            
            Text("Coming soon...")
                .font(.custom(DesignSystem.lightFont, size: 16))
                .foregroundColor(DesignSystem.slate500)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            CyberpunkBackground()
                .ignoresSafeArea()
        )
    }
}

#Preview {
    HistoryView()
}
