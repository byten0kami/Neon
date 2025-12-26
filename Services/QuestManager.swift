import Foundation
import Combine

/// Manages the state and progression of quests
@MainActor
class QuestManager: ObservableObject {
    static let shared = QuestManager()
    
    @Published var quests: [Quest] = []
    
    private let questsPersistenceKey = "neon_quests_progress"
    
    // Publishes events when quests are completed
    let questCompletedPublisher = PassthroughSubject<Quest, Never>()
    
    private init() {
        loadQuests()
    }
    
    // MARK: - Event Handling
    
    /// Reports an event to the quest system to check for triggers associated with it
    func reportEvent(_ event: QuestTriggerEvent) {
        switch event {
        case .taskCompleted:
            checkNyanTrigger()
        default:
            break
        }
    }
    
    // MARK: - Specific Quest Logic
    
    private func checkNyanTrigger() {
        guard let index = quests.firstIndex(where: { $0.id == .nyanCat }) else { return }
        let quest = quests[index]
        
        // Only trigger if active and not completed
        guard quest.isActive, !quest.isCompleted else { return }
        
        // Alpha Testing Logic: Always trigger on task completion
        // In the future this might be random chance
        OverlayEffectsManager.shared.showEffect(.nyanCat)
    }
    
    // MARK: - Completion
    
    /// Marks a quest as complete, usually called from UI interaction (tapping the cat)
    func completeQuest(id: QuestID) {
        guard let index = quests.firstIndex(where: { $0.id == id }) else { return }
        
        if !quests[index].isCompleted {
            quests[index].isCompleted = true
            quests[index].completedAt = Date()
            quests[index].progress = 1.0
            
            saveQuests()
            
            // Notify system
            questCompletedPublisher.send(quests[index])
            
            // Distribute Rewards
            RewardManager.shared.processQuestCompletion(questID: id)
            
            // If Nyan Cat, auto-switch theme (per user request: "enabled as soon as collected")
            if id == .nyanCat {
                ThemeManager.shared.setTheme("nyan")
            }
        }
    }
    
    // MARK: - Persistence
    
    private func loadQuests() {
        let defaults = QuestFactory.defaultQuests()
        
        if let data = UserDefaults.standard.data(forKey: questsPersistenceKey),
           let savedQuests = try? JSONDecoder().decode([Quest].self, from: data) {
            
            // Merge saved state with default definitions
            // This ensures code updates (new titles/logic) apply, but progress is kept
            self.quests = defaults.map { defaultQuest in
                if let saved = savedQuests.first(where: { $0.id == defaultQuest.id }) {
                    var merged = defaultQuest
                    merged.isCompleted = saved.isCompleted
                    merged.progress = saved.progress
                    merged.completedAt = saved.completedAt
                    return merged
                }
                return defaultQuest
            }
        } else {
            self.quests = defaults
        }
    }
    
    private func saveQuests() {
        if let encoded = try? JSONEncoder().encode(quests) {
            UserDefaults.standard.set(encoded, forKey: questsPersistenceKey)
        }
    }
}
