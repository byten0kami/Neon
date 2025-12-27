import SwiftUI

// MARK: - Chat Bubble

/// Chat message bubble for displaying user and AI messages
struct ChatBubble: View {
    let message: ChatMessage
    @ObservedObject private var themeManager = ThemeManager.shared
    
    private var isUser: Bool {
        message.role == .user
    }
    
    var body: some View {
        HStack {
            if isUser { Spacer() }
            
            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                timestampView
                
                contentBubble
            }
            
            if !isUser { Spacer() }
        }
        .padding(.vertical, 4)
    }
    
    private var contentBubble: some View {
        Text(message.content)
            .font(.custom(themeManager.currentTheme.bodyFont, size: 16))
            .foregroundColor(isUser ? .white : DesignSystem.slate300)
            .padding(12)
            .background(
                CardBackground(
                    accentColor: isUser ? DesignSystem.slate400 : themeManager.currentTheme.aiAccent
                )
            )
            // Limit width but allow it to size to content
            .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: isUser ? .trailing : .leading)
    }
    
    private var timestampView: some View {
        Text(message.timestamp)
            .font(.custom(DesignSystem.monoFont, size: 11)) // Increased from 9
            .foregroundColor(DesignSystem.slate500) // Slightly brighter than 600 for visibility
    }
}

// MARK: - Typing Bubble

/// Animated typing indicator for AI responses
struct TypingBubble: View {
    @State private var dotCount = 0
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Text("PROCESSING")
                        .font(.custom(DesignSystem.monoFont, size: 10))
                        .foregroundColor(themeManager.currentTheme.aiAccent)
                        
                    Text(String(repeating: ".", count: dotCount + 1))
                        .font(.custom(DesignSystem.monoFont, size: 10))
                        .foregroundColor(themeManager.currentTheme.aiAccent)
                        .frame(width: 20, alignment: .leading)
                }
            }
            .padding(12)
            .background(CardBackground(accentColor: themeManager.currentTheme.aiAccent))
            
            Spacer()
        }
        .padding(.vertical, 4)
        .task {
            while true {
                try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s
                withAnimation { dotCount = (dotCount + 1) % 4 }
            }
        }
    }
}
