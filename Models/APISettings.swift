import Foundation

// MARK: - API Settings

/// User's API configuration settings
/// Stores preferences for AI model and custom API key usage
struct APISettings: Codable {
    /// Whether user wants to use their own API key
    var useCustomKey: Bool
    
    /// Selected AI model identifier
    var selectedModel: String
    
    /// Default defer/snooze time in minutes
    var defaultDeferMinutes: Int
    
    /// Available AI models with tooltip information
    static let availableModels: [(id: String, name: String, description: String, tooltip: String)] = [
        ("google/gemini-2.0-flash-001", "Gemini 2.0 Flash", "Fast & efficient",
         "Free tier: 50 req/day (free account) or 1000 req/day ($10+ balance). Rate: 20 req/min"),
        ("google/gemini-2.0-flash-thinking-exp-01-21", "Gemini 2.0 Thinking", "Best reasoning",
         "Free tier: 50 req/day (free account) or 1000 req/day ($10+ balance). Rate: 20 req/min"),
        ("openai/gpt-4o-mini", "GPT-4o Mini", "OpenAI compact",
         "Pay-as-you-go: $0.15/1M input tokens. No request limits while balance lasts."),
        ("anthropic/claude-3.5-sonnet", "Claude 3.5 Sonnet", "Balanced & creative",
         "Pay-as-you-go: $3.00/1M input tokens (~20x more than GPT-4o Mini). No request limits while balance lasts.")
    ]
    
    /// Default settings
    static var `default`: APISettings {
        APISettings(
            useCustomKey: false,
            selectedModel: "google/gemini-2.0-flash-001",
            defaultDeferMinutes: 60
        )
    }
}
