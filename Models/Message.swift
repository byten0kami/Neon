import SwiftUI

/// Role in a chat conversation
enum MessageRole {
    case user
    case assistant
}

/// A single message in the contextual chat
struct ChatMessage: Identifiable {
    let id: UUID
    let role: MessageRole
    let content: String
    let timestamp: String
    
    init(
        id: UUID = UUID(),
        role: MessageRole,
        content: String,
        timestamp: String = ""
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp.isEmpty ? Self.currentTime() : timestamp
    }
    
    private static func currentTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: Date())
    }
}
