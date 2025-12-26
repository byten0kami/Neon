import SwiftUI

// MARK: - Suggestion Card

/// AI Suggestion card displayed inline in chat
/// Uses UniversalTimelineCard with custom configuration
/// User can ACCEPT to create the task or DENY to dismiss
struct SuggestionCard: View {
    let title: String
    let description: String
    var dailyTime: String? = nil
    var onAccept: () -> Void
    var onDeny: () -> Void
    
    var body: some View {
        let config = CardConfig.forSuggestion(
            title: title,
            description: description,
            dailyTime: dailyTime,
            onAccept: onAccept,
            onDeny: onDeny
        )
        
        UniversalTimelineCard(config: config, showConnector: false)
    }
}

#Preview {
    ZStack {
        DesignSystem.backgroundPrimary.ignoresSafeArea()
        
        VStack(spacing: 16) {
            SuggestionCard(
                title: "Antidepressant 20mg",
                description: "Daily medication reminder",
                dailyTime: "10:00",
                onAccept: { print("Accepted") },
                onDeny: { print("Denied") }
            )
            .padding()
        }
    }
}
