import Foundation

/// Service for communicating with AI via OpenRouter (Claude, GPT, etc.)
/// The AI uses AIKnowledgeBase to store and retrieve facts about the user
@MainActor
class AIService {
    static let shared = AIService()
    
    // OpenRouter API (supports Claude, GPT, Gemini via one API)
    // Priority: 1) User's custom key, 2) Environment variable, 3) Bundled key
    private var apiKey: String {
        // 1. Check user's custom API key (from Settings)
        if let userKey = APISettingsStore.shared.getEffectiveAPIKey(), !userKey.isEmpty {
            return userKey.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        // 2. Try environment variable (local development)
        if let envKey = ProcessInfo.processInfo.environment["OPENROUTER_API_KEY"], !envKey.isEmpty {
            return envKey.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        // 3. Fall back to bundled key (Info.plist for TestFlight/App Store)
        if let bundleKey = Bundle.main.infoDictionary?["OPENROUTER_API_KEY"] as? String, 
           !bundleKey.isEmpty,
           bundleKey != "$(OPENROUTER_API_KEY)" { // Ignore if substitution failed
            return bundleKey.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return ""
    }
    
    private let baseURL = "https://openrouter.ai/api/v1/chat/completions"
    
    /// Selected AI model - reads from user settings
    private var model: String {
        APISettingsStore.shared.settings.selectedModel
    }
    
    /// NeuroSync OS System Prompt - defines AI personality and capabilities
    private let systemPrompt = """
    # NEUROSYNC OS — SYSTEM PROTOCOL v1.0
    
    You are NeuroSync OS, a cyberpunk health & life assistant inspired by JARVIS.
    
    ## YOUR IDENTITY
    - Name: NeuroSync (or just "Sync")
    - Personality: Concise, slightly sarcastic, hyper-protective about user's health
    - Tone: Use sci-fi terminology (bio-protocols, neural stability, system sync)
    - Always SHORT responses (2-3 sentences max)
    
    ## YOUR MEMORY SYSTEM
    You have a Knowledge Base where you store FACTS about the user.
    - You LEARN by listening to the user
    - Every conversation, you receive your current memory
    - When you learn something NEW, you ADD it as a fact
    
    Fact categories (you can use ANY string, these are suggestions):
    - "medication" - drugs, supplements, dosages, schedules
    - "condition" - health conditions, diagnoses
    - "routine" - daily habits (coffee, gym, sleep time)
    - "preference" - likes/dislikes, preferred times
    - "event" - planned activities (theater, travel, meetings)
    - "constraint" - rules (no alcohol with meds, empty stomach, etc.)
    - "allergy" - food/drug allergies
    
    ## HOW YOU LEARN RULES
    You DON'T have hardcoded rules. Instead:
    1. User tells you: "I take Euthyrox every morning"
    2. You ADD a fact: {category: "medication", content: "Euthyrox every morning"}
    3. You do a research - Euthyrox is taken on empty stomach
    4. So, you SUGGEST a constraint: {category: "constraint", content: "No food for 30min after Euthyrox"}
    5. Next time user says "I want coffee", you CHECK your memory and WARN if conflict
    5a. It's just a lousy example. User will not actually communicate with the assistant that he wants coffee, 
    but when suggesting the card to create, you should also ask if the user wants to create a timer for coffee,
    or the like.
    5b. Another example: user goes to gym, you should suggest a timer card to eat before or after gym.
    
    ## YOUR FUNCTIONS
    You can perform these ACTIONS in your response:
    
    1. **add_fact** - Remember something about user
       {"type": "add_fact", "category": "medication", "content": "Takes Euthyrox 50mcg at 7am"}
    
    2. **create_timeline_item** - Create a timeline item (one-off or recurring)
       This is the ONLY way to add items to the user's timeline.
       
       One-time reminder (e.g., "remind me to eat in 30 min"):
       {"type": "create_timeline_item", "title": "Eat lunch", "priority": "normal",
        "time": "14:30"}
       
       Daily medication course (5 days):
       {"type": "create_timeline_item", "title": "Antibiotics", "priority": "critical", 
        "time": "09:00",
        "recurrence": {"frequency": "daily", "interval": 1, "endCondition": {"type": "count", "value": 5}}}
       
       Forever habit:
       {"type": "create_timeline_item", "title": "Morning Yoga", "priority": "normal",
        "time": "07:00",
        "recurrence": {"frequency": "daily", "interval": 1, "endCondition": {"type": "forever"}}}
       
       Weekly on specific days:
       {"type": "create_timeline_item", "title": "Gym", "time": "18:00",
        "recurrence": {"frequency": "weekly", "interval": 1, "weekdays": [1, 3, 5]}}
    
    ## SMART SCHEDULING RULES
    - For timers/countdowns: create a one-off item at current_time + minutes
    - For "remind me at X" → create one-off at time X
    - For "every morning" → create recurring with daily frequency
    - For "for X days" or "course" → use recurrence.endCondition.count
    - For medication/pills/critical → set priority: "critical"
    - ALWAYS include specific times when scheduling
    
    ## RESPONSE FORMAT
    Always respond with valid JSON:
    ```json
    {
        "message": "[STATUS] Your response here",
        "actions": []
    }
    ```
    
    Status tags:
    - [SYNC] - Information acknowledged, saved
    - [OK] - Confirmed, no issues
    - [WARNING] - Potential conflict or risk
    - [ALERT] - Critical health warning
    
    ## EXAMPLES
    
    User: "I take Euthyrox every morning"
    Response:
    {
        "message": "[SYNC] Euthyrox protocol registered. Morning administration noted. Reminder: take on empty stomach, wait 30-60min before food or coffee.",
        "actions": [
            {"type": "add_fact", "category": "medication", "content": "Takes Euthyrox daily in the morning"},
            {"type": "add_fact", "category": "constraint", "content": "Euthyrox requires empty stomach, no food/coffee for 30-60min after"}
        ]
    }
    
    User: "I want coffee" (when user has Euthyrox in memory)
    Response:
    {
        "message": "[WARNING] Coffee conflicts with Euthyrox absorption. Wait at least 60min after taking medication. Want me to start a timer?",
        "actions": []
    }
    
    User: "I'm going to theater tonight"
    Response:
    {
        "message": "[SYNC] Evening theater event logged. Adjusting medication schedule if needed. Enjoy the show.",
        "actions": [
            {"type": "add_fact", "category": "event", "content": "Theater visit tonight"}
        ]
    }
    
    ## CRITICAL RULES
    1. NEVER make up medical facts - only use what user told you
    2. If unsure about drug interactions, RECOMMEND consulting a doctor
    3. Be PROACTIVE about potential conflicts
    4. Keep responses SHORT but informative
    """
    
    private init() {}
    
    /// Main method: sends message with full context from AIKnowledgeBase
    func sendMessage(context: String, userMessage: String, history: [ChatMessage] = []) async throws -> AIServiceResponse {
        let knowledgeContext = await MainActor.run {
            AIKnowledgeBase.shared.toPromptContext()
        }
        
        // Format history
        let historyPrompt = history.suffix(10).map { msg in
            let role = msg.role == .user ? "Right now User said" : "You said" // Simplified for prompt
            return "\(role): \(msg.content)"
        }.joined(separator: "\n")
        
        let currentTime = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short)
        
        let userPrompt = """
        CURRENT TIME: \(currentTime)
        
        YOUR MEMORY:
        \(knowledgeContext)
        
        RECENT CHAT HISTORY:
        \(historyPrompt)
        
        CONTEXT: \(context)
        
        USER: \(userMessage)
        
        Remember: Respond ONLY with valid JSON.
        """
        
        let responseText = try await makeRequest(systemPrompt: systemPrompt, userPrompt: userPrompt)
        return parseResponse(responseText)
    }
    
    /// Direct prompt to AI brain for schedule analysis
    func askBrain(prompt: String) async throws -> String {
        let knowledgeContext = await MainActor.run {
            AIKnowledgeBase.shared.toPromptContext()
        }
        
        let userPrompt = """
        YOUR MEMORY: \(knowledgeContext)
        
        REQUEST: \(prompt)
        """
        
        return try await makeRequest(systemPrompt: systemPrompt, userPrompt: userPrompt)
    }
    
    private func makeRequest(systemPrompt: String, userPrompt: String) async throws -> String {
        guard let url = URL(string: baseURL) else {
            throw AIError.apiError("Invalid URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("NeuroSync/1.0", forHTTPHeaderField: "HTTP-Referer")
        request.setValue("NeuroSync Health Assistant", forHTTPHeaderField: "X-Title")
        request.timeoutInterval = 30
        
        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userPrompt]
            ],
            "max_tokens": 500,
            "temperature": 0.7
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.apiError("No HTTP response")
        }
        
        if httpResponse.statusCode != 200 {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown"
            print("[AIService] Error \(httpResponse.statusCode): \(errorBody)")
            
            if httpResponse.statusCode == 401 {
                throw AIError.apiError("Unauthorized (401). Please check your API Key in Settings.")
            }
            
            throw AIError.apiError("API returned \(httpResponse.statusCode)")
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw AIError.parseError("Could not parse response")
        }
        
        return content
    }
    
    private func parseResponse(_ text: String) -> AIServiceResponse {
        // Remove markdown code block if present
        var jsonText = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Find the outermost JSON object by matching braces
        jsonText = extractOutermostJSON(from: jsonText)
        
        // Try parsing as JSON
        if let data = jsonText.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let message = json["message"] as? String {
            
            var actions: [AIAction] = []
            
            if let actionsArray = json["actions"] as? [[String: Any]] {
                for actionDict in actionsArray {
                    guard let typeStr = actionDict["type"] as? String else { continue }
                    
                    switch typeStr {
                    case "add_fact":
                        if let content = actionDict["content"] as? String,
                           let category = actionDict["category"] as? String {
                            actions.append(.addFact(
                                content: content,
                                category: category,
                                note: actionDict["note"] as? String
                            ))
                        }
                        
                    case "start_timer", "schedule_event", "create_task", "schedule_reminder":
                        // Legacy action types - ignore
                        break
                    
                    case "create_timeline_item":
                        if let title = actionDict["title"] as? String {
                            // Parse recurrence if present
                            var recurrence: AIRecurrence? = nil
                            if let recurrenceDict = actionDict["recurrence"] as? [String: Any],
                               let frequency = recurrenceDict["frequency"] as? String {
                                let interval = recurrenceDict["interval"] as? Int ?? 1
                                let weekdays = recurrenceDict["weekdays"] as? [Int]
                                
                                // Parse end condition
                                var endCondition: AIEndCondition = .forever
                                if let endDict = recurrenceDict["endCondition"] as? [String: Any],
                                   let endType = endDict["type"] as? String {
                                    switch endType {
                                    case "count":
                                        if let count = endDict["value"] as? Int {
                                            endCondition = .count(count)
                                        }
                                    case "until":
                                        if let dateStr = endDict["value"] as? String {
                                            endCondition = .until(dateStr)
                                        }
                                    default:
                                        endCondition = .forever
                                    }
                                }
                                
                                recurrence = AIRecurrence(
                                    frequency: frequency,
                                    interval: interval,
                                    endCondition: endCondition,
                                    weekdays: weekdays
                                )
                            }
                            
                            actions.append(.createTimelineItem(
                                title: title,
                                description: actionDict["description"] as? String,
                                priority: actionDict["priority"] as? String ?? "normal",
                                time: actionDict["time"] as? String,
                                recurrence: recurrence
                            ))
                        }
                        
                    default:
                        break
                    }
                }
            }
            
            return AIServiceResponse(message: message, actions: actions)
        }
        
        // Fallback: if JSON parsing fails, return raw text
        print("[AIService] JSON parse failed, raw text: \(text.prefix(200))")
        return AIServiceResponse(message: text, actions: [])
    }
    
    /// Extract the outermost JSON object from text, handling nested braces
    private func extractOutermostJSON(from text: String) -> String {
        guard let firstBrace = text.firstIndex(of: "{") else {
            return text
        }
        
        var depth = 0
        var endIndex: String.Index?
        
        for i in text.indices[firstBrace...] {
            let char = text[i]
            if char == "{" {
                depth += 1
            } else if char == "}" {
                depth -= 1
                if depth == 0 {
                    endIndex = i
                    break
                }
            }
        }
        
        guard let end = endIndex else {
            return text
        }
        
        return String(text[firstBrace...end])
    }
}

/// Response from AI service
struct AIServiceResponse {
    let message: String
    let actions: [AIAction]
}

/// Actions AI can request
enum AIAction {
    case addFact(content: String, category: String, note: String?)
    case updateFact(id: UUID, content: String)
    case createTimelineItem(
        title: String,
        description: String?,
        priority: String,
        time: String?,
        recurrence: AIRecurrence?
    )
}

/// Recurrence data from AI response
struct AIRecurrence {
    let frequency: String      // "daily", "weekly", "monthly", "yearly"
    let interval: Int
    let endCondition: AIEndCondition
    let weekdays: [Int]?       // For weekly: [0, 1, 2, 3, 4, 5, 6] (Sun-Sat)
}

enum AIEndCondition {
    case forever
    case until(String)         // Date string
    case count(Int)
}

enum AIError: Error, LocalizedError {
    case apiError(String)
    case parseError(String)
    
    var errorDescription: String? {
        switch self {
        case .apiError(let msg): return "API Error: \(msg)"
        case .parseError(let msg): return "Parse Error: \(msg)"
        }
    }
}
