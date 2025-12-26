import SwiftUI

// MARK: - Chat Bubble

/// Chat message bubble for displaying user and AI messages
struct ChatBubble: View {
    let message: ChatMessage
    
    private var isUser: Bool {
        message.role == .user
    }
    
    var body: some View {
        VStack(alignment: isUser ? .trailing : .leading, spacing: 2) {
            HStack {
                if isUser { Spacer() }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(message.content)
                        .font(.custom(DesignSystem.lightFont, size: 14))
                        .foregroundColor(isUser ? .white : DesignSystem.slate300)
                        
                    Text(message.timestamp)
                        .font(.custom(DesignSystem.monoFont, size: 9))
                        .foregroundColor(DesignSystem.slate600)
                }
                .padding(12)
                .background(
                    CardBackground(
                        accentColor: isUser ? DesignSystem.slate400 : DesignSystem.purple
                    )
                )
                .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: isUser ? .trailing : .leading)
                
                if !isUser { Spacer() }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Typing Bubble

/// Animated typing indicator for AI responses
struct TypingBubble: View {
    @State private var dotCount = 0
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Text("PROCESSING")
                        .font(.custom(DesignSystem.monoFont, size: 10))
                        .foregroundColor(DesignSystem.purple)
                        
                    Text(String(repeating: ".", count: dotCount + 1))
                        .font(.custom(DesignSystem.monoFont, size: 10))
                        .foregroundColor(DesignSystem.purple)
                        .frame(width: 20, alignment: .leading)
                }
            }
            .padding(12)
            .background(CardBackground(accentColor: DesignSystem.purple))
            
            Spacer()
        }
        .padding(.vertical, 4)
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
                withAnimation { dotCount = (dotCount + 1) % 4 }
            }
        }
    }
}
