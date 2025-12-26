import Foundation

/// Quest lifecycle phases
enum QuestPhase: String, Codable {
    case dormant     // Conditions not yet met (e.g., not alpha release)
    case available   // Waiting for trigger event
    case triggered   // Challenge active (user must complete action)
    case completed   // Challenge done, reward granted
}

/// Events that can trigger quests
enum TriggerEvent {
    case taskCompleted
    case appLaunched
    case chatMessageSent
    case dayStreak(days: Int)
    case subscriptionPurchased
}

/// Protocol for all quest handlers
@MainActor
protocol QuestHandler: AnyObject {
    var id: String { get }
    var phase: QuestPhase { get set }
    var reward: Reward? { get }
    
    /// Check if quest should transition from dormant to available
    func checkAvailability() -> Bool
    
    /// Check if trigger conditions are met (when in .available phase)
    /// Returns true if quest was triggered
    func shouldTrigger(on event: TriggerEvent) -> Bool
    
    /// Called when challenge is completed by user action
    func complete()
}

// MARK: - Default Implementations

extension QuestHandler {
    /// Convenience: update phase to available if conditions are met
    func updateAvailability() {
        if phase == .dormant && checkAvailability() {
            phase = .available
        }
    }
}
