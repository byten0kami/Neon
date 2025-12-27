import Foundation
import Combine

/// Central AI brain that processes ALL user actions.
/// This is the "JARVIS" of NeuroSync - learns through conversation, no hardcoded rules.
@MainActor
class AIBrain: ObservableObject {
    static let shared = AIBrain()
    
    @Published var isThinking: Bool = false
    @Published var lastResponse: String?
    @Published var lastError: String?
    
    private let aiService: AIServiceProtocol
    private let knowledge = AIKnowledgeBase.shared
    
    internal init(service: AIServiceProtocol = AIService.shared) {
        self.aiService = service
    }
    
    /// Main entry point: user says something, AI figures out what to do
    /// Returns message + pending actions for UI to preview before executing
    @MainActor
    func processUserInput(_ input: String, context: String = "General conversation", history: [ChatMessage] = []) async -> AIProcessResult {
        isThinking = true
        lastError = nil
        defer { isThinking = false }
        
        do {
            let response = try await aiService.sendMessage(context: context, userMessage: input, history: history)
            
            // Return pending actions for UI to preview instead of executing immediately
            lastResponse = response.message
            return AIProcessResult(message: response.message, pendingActions: response.actions)
        } catch let error as AIError {
            lastError = error.localizedDescription
            print("[AIBrain] Error: \(error.localizedDescription)")
            return AIProcessResult(message: "[SYNC ERROR] \(error.localizedDescription)", pendingActions: [])
        } catch {
            lastError = error.localizedDescription
            print("[AIBrain] Unknown error: \(error)")
            return AIProcessResult(message: "[SYNC ERROR] Connection failed. Check network.", pendingActions: [])
        }
    }
    
    /// Execute a single action from AI (called from UI after user confirms)
    func executeAction(_ action: AIAction) {
        switch action {
        case .addFact(let content, let category, let note):
            knowledge.addFact(content, category: category, aiNote: note)
            print("[AIBrain] Added fact: \(content)")
            
        case .updateFact(let id, let content):
            knowledge.updateFact(id: id, newContent: content)
            
        case .createTimelineItem(let title, let description, let priority, let time, let aiRecurrence):
            createTimelineItem(
                title: title,
                description: description,
                priority: priority,
                timeString: time,
                aiRecurrence: aiRecurrence
            )
            
        case .deleteTimelineItem(let title):
            deleteTimelineItem(title: title)
        }
    }
    
    /// Create a TimelineItem (Master or One-off) using the new TimelineEngine
    private func createTimelineItem(
        title: String,
        description: String?,
        priority: String,
        timeString: String?,
        aiRecurrence: AIRecurrence?
    ) {
        let itemPriority = ItemPriority(from: priority)
        let scheduledTime: Date
        
        // Parse time string or default to now + 1 hour
        if let timeStr = timeString, let parsedTime = parseTime(timeStr) {
            scheduledTime = parsedTime
        } else {
            scheduledTime = Date().addingTimeInterval(3600) // Default 1 hour from now
        }
        
        // Check if this is a recurring item (Master) or one-off
        if let aiRecurrence = aiRecurrence {
            // Convert AIRecurrence to RecurrenceRule
            let frequency: RecurrenceRule.Frequency
            switch aiRecurrence.frequency.lowercased() {
            case "minutely": frequency = .minutely
            case "hourly": frequency = .hourly
            case "weekly": frequency = .weekly
            case "monthly": frequency = .monthly
            case "yearly": frequency = .yearly
            default: frequency = .daily
            }
            
            let endCondition: RecurrenceRule.EndCondition
            switch aiRecurrence.endCondition {
            case .forever:
                endCondition = .forever
            case .count(let n):
                endCondition = .count(n)
            case .until(let dateStr):
                if let date = parseDateString(dateStr) {
                    endCondition = .until(date)
                } else {
                    endCondition = .forever
                }
            }
            
            let weekdaysSet: Set<Int>? = aiRecurrence.weekdays.map { Set($0) }
            
            let recurrence = RecurrenceRule(
                frequency: frequency,
                interval: aiRecurrence.interval,
                endCondition: endCondition,
                weekdays: weekdaysSet
            )
            
            // Create Master
            let master = TimelineItem.master(
                title: title,
                description: description,
                priority: itemPriority,
                startTime: scheduledTime,
                duration: TimeInterval(APISettingsStore.shared.settings.defaultDurationMinutes * 60),
                recurrence: recurrence
            )
            
            TimelineEngine.shared.addMaster(master)
            print("[AIBrain] Created recurring master: \(title) with duration \(APISettingsStore.shared.settings.defaultDurationMinutes)m")
        } else {
            // Create One-off
            let item = TimelineItem.oneOff(
                title: title,
                description: description,
                priority: itemPriority,
                scheduledTime: scheduledTime,
                duration: TimeInterval(APISettingsStore.shared.settings.defaultDurationMinutes * 60)
            )
            
            TimelineEngine.shared.addOneOff(item)
            print("[AIBrain] Created one-off item: \(title) with duration \(APISettingsStore.shared.settings.defaultDurationMinutes)m")
        }
    }
    
    /// Delete a TimelineItem by title (searches both masters and instances)
    private func deleteTimelineItem(title: String) {
        let engine = TimelineEngine.shared
        let searchTitle = title.lowercased()
        
        // Search instances first
        if let instance = engine.instances.first(where: { $0.title.lowercased().contains(searchTitle) }) {
            engine.delete(id: instance.id)
            print("[AIBrain] Deleted instance: \(instance.title)")
            return
        }
        
        // Search masters (recurring tasks)
        if let master = engine.masters.first(where: { $0.title.lowercased().contains(searchTitle) && !$0.isArchived }) {
            engine.delete(id: master.id) // This archives the master
            print("[AIBrain] Archived master: \(master.title)")
            return
        }
        
        print("[AIBrain] No item found matching: \(title)")
    }
    
    /// Parse date string (ISO format or simple YYYY-MM-DD)
    private func parseDateString(_ dateStr: String) -> Date? {
        let formatters = [
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd"
        ]
        for format in formatters {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.locale = Locale(identifier: "en_US_POSIX")
            if let date = formatter.date(from: dateStr) {
                return date
            }
        }
        return nil
    }
    

    
    /// Quick safety check for an activity
    @MainActor
    func checkActivitySafety(_ activity: String) async -> SafetyCheckResult {
        isThinking = true
        defer { isThinking = false }
        
        let prompt = "Is \"\(activity)\" safe for user based on what you know? Reply with JSON: {\"message\": \"...\", \"safe\": true/false}"
        
        do {
            let response = try await aiService.askBrain(prompt: prompt)
            return parseSafetyResponse(response)
        } catch {
            return SafetyCheckResult(allowed: true, warnings: [], message: "[OK] Unable to verify.")
        }
    }
    
    private func parseSafetyResponse(_ text: String) -> SafetyCheckResult {
        var jsonText = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let jsonStart = jsonText.range(of: "{"),
           let jsonEnd = jsonText.range(of: "}", options: .backwards) {
            jsonText = String(jsonText[jsonStart.lowerBound...jsonEnd.upperBound])
        }
        
        guard let data = jsonText.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return SafetyCheckResult(allowed: true, warnings: [], message: text)
        }
        
        let safe = json["safe"] as? Bool ?? true
        let warnings = json["warnings"] as? [String] ?? []
        let message = json["message"] as? String ?? text
        
        return SafetyCheckResult(allowed: safe, warnings: warnings, message: message)
    }
    
    // Helper to parse time string
    private func parseTime(_ timeString: String) -> Date? {
        let parts = timeString.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return nil }
        
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = parts[0]
        components.minute = parts[1]
        
        guard let date = Calendar.current.date(from: components) else { return nil }
        
        // If time is in the past today, schedule for tomorrow
        if date < Date() {
            return Calendar.current.date(byAdding: .day, value: 1, to: date)
        }
        return date
    }
}

/// Result of safety check
struct SafetyCheckResult {
    let allowed: Bool
    let warnings: [String]
    let message: String
}

/// Result of processing user input - contains message and pending actions for preview
struct AIProcessResult {
    let message: String
    let pendingActions: [AIAction]
}
