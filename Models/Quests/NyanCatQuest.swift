import Foundation

/// Nyan Cat Quest - First quest implementation
/// Available in Alpha, triggers on task completion, reward: Nyan theme
@MainActor
class NyanCatQuest: QuestHandler {
    let id = "nyan_cat"
    var phase: QuestPhase = .dormant
    
    let reward: Reward? = Reward(
        id: "theme_nyan",
        title: "Nyan Theme",
        description: "Rainbow timeline unlocked!",
        icon: "cat.fill"
    )
    
    // MARK: - Availability
    
    func checkAvailability() -> Bool {
        // Always available in Alpha
        return true
    }
    
    // MARK: - Trigger
    
    func shouldTrigger(on event: TriggerEvent) -> Bool {
        guard phase == .available else { return false }
        
        if case .taskCompleted = event {
            phase = .triggered
            OverlayEffectsManager.shared.showEffect(.nyanCat)
            return true
        }
        return false
    }
    
    // MARK: - Completion
    
    func complete() {
        guard phase == .triggered else { return }
        phase = .completed
        
        // Grant reward
        if let rewardId = reward?.id {
            RewardManager.shared.unlockReward(id: rewardId)
        }
        
        // Quest-specific: auto-equip Nyan theme
        ThemeManager.shared.setTheme("nyan")
    }
}
