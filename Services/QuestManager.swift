import Foundation
import Combine

/// Manages the state and progression of quests via handlers
@MainActor
class QuestManager: ObservableObject {
    static let shared = QuestManager()
    
    /// All registered quest handlers
    @Published private(set) var handlers: [QuestHandler] = []
    
    private let persistenceKey = "neon_quest_phases"
    
    // Publishes events when quests are completed
    let questCompletedPublisher = PassthroughSubject<String, Never>()
    
    private init() {
        registerHandlers()
        loadState()
        updateAvailability()
    }
    
    // MARK: - Registration
    
    private func registerHandlers() {
        handlers = [
            NyanCatQuest()
            // Future: add more quests here
        ]
    }
    
    // MARK: - Event Routing
    
    /// Routes events to all available quest handlers
    func reportEvent(_ event: TriggerEvent) {
        for handler in handlers where handler.phase == .available {
            if handler.shouldTrigger(on: event) {
                saveState()
            }
        }
    }
    
    // MARK: - Completion
    
    /// Completes a quest by ID (called from UI, e.g., tapping Nyan Cat)
    func completeQuest(id: String) {
        guard let handler = handlers.first(where: { $0.id == id }) else { return }
        guard handler.phase == .triggered else { return }
        
        handler.complete()
        saveState()
        questCompletedPublisher.send(id)
    }
    
    // MARK: - Availability
    
    /// Updates availability for all dormant quests
    func updateAvailability() {
        for handler in handlers {
            handler.updateAvailability()
        }
        saveState()
    }
    
    // MARK: - Query
    
    /// Returns handler for a specific quest ID
    func handler(for id: String) -> QuestHandler? {
        handlers.first { $0.id == id }
    }
    
    /// Returns all completed quest IDs
    var completedQuestIDs: [String] {
        handlers.filter { $0.phase == .completed }.map { $0.id }
    }
    
    // MARK: - Persistence
    
    private func loadState() {
        guard let data = UserDefaults.standard.data(forKey: persistenceKey),
              let phases = try? JSONDecoder().decode([String: QuestPhase].self, from: data)
        else { return }
        
        for handler in handlers {
            if let savedPhase = phases[handler.id] {
                handler.phase = savedPhase
            }
        }
    }
    
    private func saveState() {
        var phases: [String: QuestPhase] = [:]
        for handler in handlers {
            phases[handler.id] = handler.phase
        }
        
        if let encoded = try? JSONEncoder().encode(phases) {
            UserDefaults.standard.set(encoded, forKey: persistenceKey)
        }
    }
}
