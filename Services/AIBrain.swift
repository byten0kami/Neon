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
    
    private let aiService = AIService.shared
    private let knowledge = AIKnowledgeBase.shared
    
    private init() {}
    
    /// Main entry point: user says something, AI figures out what to do
    @MainActor
    func processUserInput(_ input: String, context: String = "General conversation", history: [ChatMessage] = []) async -> String {
        isThinking = true
        lastError = nil
        defer { isThinking = false }
        
        do {
            let response = try await aiService.sendMessage(context: context, userMessage: input, history: history)
            
            // Execute all actions AI requested
            for action in response.actions {
                executeAction(action)
            }
            
            lastResponse = response.message
            return response.message
        } catch let error as AIError {
            lastError = error.localizedDescription
            print("[AIBrain] Error: \(error.localizedDescription)")
            return "[SYNC ERROR] \(error.localizedDescription)"
        } catch {
            lastError = error.localizedDescription
            print("[AIBrain] Unknown error: \(error)")
            return "[SYNC ERROR] Connection failed. Check network."
        }
    }
    
    /// Execute a single action from AI
    private func executeAction(_ action: AIAction) {
        switch action {
        case .addFact(let content, let category, let note):
            knowledge.addFact(content, category: category, aiNote: note)
            print("[AIBrain] Added fact: \(content)")
            
        case .updateFact(let id, let content):
            knowledge.updateFact(id: id, newContent: content)
            
        case .scheduleEvent(let title, let time, let priority):
            scheduleNewEvent(title: title, timeString: time, priority: priority)
            
        case .startTimer(let name, let minutes):
            ScheduleStore.shared.startTimer(name: name, durationMinutes: minutes)
            print("[AIBrain] Started timer: \(name) for \(minutes) min")
            
        case .createTask(let title, let priority, let category, let time, let dailyTime, let intervalMinutes):
             // Create using full Task parameters
             let task = UserTask(
                 title: title,
                 status: (intervalMinutes != nil || dailyTime != nil) ? .recurring : .pending,
                 priority: TaskPriority(rawValue: priority) ?? .normal,
                 scheduledTime: time != nil ? parseTime(time!) : nil,
                 dailyTime: dailyTime,
                 intervalMinutes: intervalMinutes,
                 category: category
             )
             TaskStore.shared.addTask(task)
             print("[AIBrain] Created task: \(title)")
            
        case .scheduleReminder(let title, let time, let dailyTime, let intervalMinutes):
            if let time = time {
                TaskStore.shared.addScheduledReminder(title: title, time: time)
            } else if let daily = dailyTime {
                TaskStore.shared.addDailyReminder(title: title, dailyTime: daily)
            } else if let interval = intervalMinutes {
                TaskStore.shared.addIntervalReminder(title: title, intervalMinutes: interval)
            }
            print("[AIBrain] Scheduled reminder: \(title)")
        }
    }
    
    /// Parse time string and create event
    private func scheduleNewEvent(title: String, timeString: String, priority: String) {
        let components = timeString.split(separator: ":").compactMap { Int($0) }
        guard components.count == 2 else { return }
        
        let hour = components[0]
        let minute = components[1]
        
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        guard let scheduledTime = Calendar.current.date(from: dateComponents) else { return }
        
        let eventPriority: EventPriority
        switch priority {
        case "critical": eventPriority = .critical
        case "high": eventPriority = .high
        case "low": eventPriority = .low
        default: eventPriority = .normal
        }
        
        let event = ScheduledEvent(
            type: .reminder(message: title),
            title: title,
            scheduledTime: scheduledTime,
            priority: eventPriority
        )
        
        ScheduleStore.shared.addEvent(event)
        print("[AIBrain] Scheduled: \(title) at \(timeString)")
    }
    
    func onEventCompleted(_ event: ScheduledEvent) async {
        let prompt = "Event completed: \"\(event.title)\". Any follow-up needed?"
        _ = await processUserInput(prompt, context: "Event completion")
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
