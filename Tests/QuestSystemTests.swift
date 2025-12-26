import XCTest
@testable import NeonTracker

/// Unit tests for the Quest System
@MainActor
final class QuestSystemTests: XCTestCase {
    
    // MARK: - QuestPhase Tests
    
    func test_questPhase_initialStateIsDormant() {
        let quest = NyanCatQuest()
        // New quests without loaded state start dormant
        XCTAssertEqual(quest.phase, .dormant)
    }
    
    func test_questPhase_transitionsDormantToAvailable() {
        let quest = NyanCatQuest()
        quest.phase = .dormant
        
        // When availability check passes
        XCTAssertTrue(quest.checkAvailability())
        
        // And we call updateAvailability
        quest.updateAvailability()
        
        // Then phase should transition to available
        XCTAssertEqual(quest.phase, .available)
    }
    
    func test_questPhase_dormantQuestDoesNotTrigger() {
        let quest = NyanCatQuest()
        quest.phase = .dormant
        
        // When we send a trigger event while dormant
        let triggered = quest.shouldTrigger(on: .taskCompleted)
        
        // Then it should NOT trigger
        XCTAssertFalse(triggered)
        XCTAssertEqual(quest.phase, .dormant)
    }
    
    func test_questPhase_availableQuestTriggers() {
        let quest = NyanCatQuest()
        quest.phase = .available
        
        // When we send a matching trigger event
        let triggered = quest.shouldTrigger(on: .taskCompleted)
        
        // Then it should trigger
        XCTAssertTrue(triggered)
        XCTAssertEqual(quest.phase, .triggered)
    }
    
    func test_questPhase_completedQuestDoesNotTrigger() {
        let quest = NyanCatQuest()
        quest.phase = .completed
        
        // When we try to trigger a completed quest
        let triggered = quest.shouldTrigger(on: .taskCompleted)
        
        // Then it should NOT trigger again
        XCTAssertFalse(triggered)
        XCTAssertEqual(quest.phase, .completed)
    }
    
    // MARK: - Event Handling Tests
    
    func test_trigger_wrongEventDoesNotTrigger() {
        let quest = NyanCatQuest()
        quest.phase = .available
        
        // Nyan Cat triggers on taskCompleted, not appLaunched
        let triggered = quest.shouldTrigger(on: .appLaunched)
        
        XCTAssertFalse(triggered)
        XCTAssertEqual(quest.phase, .available)
    }
    
    func test_trigger_correctEventTriggers() {
        let quest = NyanCatQuest()
        quest.phase = .available
        
        let triggered = quest.shouldTrigger(on: .taskCompleted)
        
        XCTAssertTrue(triggered)
        XCTAssertEqual(quest.phase, .triggered)
    }
    
    // MARK: - Completion Tests
    
    func test_complete_transitionsToCompletedPhase() {
        let quest = NyanCatQuest()
        quest.phase = .triggered
        
        quest.complete()
        
        XCTAssertEqual(quest.phase, .completed)
    }
    
    func test_complete_doesNotCompleteIfNotTriggered() {
        let quest = NyanCatQuest()
        quest.phase = .available
        
        quest.complete()
        
        // Should NOT change phase
        XCTAssertEqual(quest.phase, .available)
    }
    
    // MARK: - Reward Tests
    
    func test_nyanCatQuest_hasReward() {
        let quest = NyanCatQuest()
        
        XCTAssertNotNil(quest.reward)
        XCTAssertEqual(quest.reward?.id, "theme_nyan")
        XCTAssertEqual(quest.reward?.title, "Nyan Theme")
    }
    
    func test_reward_modelProperties() {
        let reward = Reward(
            id: "test_reward",
            title: "Test Title",
            description: "Test Description",
            icon: "star.fill"
        )
        
        XCTAssertEqual(reward.id, "test_reward")
        XCTAssertEqual(reward.title, "Test Title")
        XCTAssertEqual(reward.description, "Test Description")
        XCTAssertEqual(reward.icon, "star.fill")
    }
    
    func test_reward_optionalFieldsCanBeNil() {
        let reward = Reward(id: "minimal", title: "Minimal")
        
        XCTAssertNil(reward.description)
        XCTAssertNil(reward.icon)
    }
}

// MARK: - NyanCatQuest Specific Tests

@MainActor
final class NyanCatQuestTests: XCTestCase {
    
    func test_nyanCat_id() {
        let quest = NyanCatQuest()
        XCTAssertEqual(quest.id, "nyan_cat")
    }
    
    func test_nyanCat_isAlwaysAvailableInAlpha() {
        let quest = NyanCatQuest()
        
        // Nyan Cat is available in alpha (returns true)
        XCTAssertTrue(quest.checkAvailability())
    }
    
    func test_nyanCat_fullLifecycle() {
        let quest = NyanCatQuest()
        
        // 1. Start dormant
        XCTAssertEqual(quest.phase, .dormant)
        
        // 2. Become available
        quest.updateAvailability()
        XCTAssertEqual(quest.phase, .available)
        
        // 3. Trigger on task completion
        let triggered = quest.shouldTrigger(on: .taskCompleted)
        XCTAssertTrue(triggered)
        XCTAssertEqual(quest.phase, .triggered)
        
        // 4. Complete the quest
        quest.complete()
        XCTAssertEqual(quest.phase, .completed)
    }
    
    func test_nyanCat_onlyTriggersOnce() {
        let quest = NyanCatQuest()
        quest.phase = .available
        
        // First trigger succeeds
        let first = quest.shouldTrigger(on: .taskCompleted)
        XCTAssertTrue(first)
        XCTAssertEqual(quest.phase, .triggered)
        
        // Second trigger fails (already triggered)
        let second = quest.shouldTrigger(on: .taskCompleted)
        XCTAssertFalse(second)
        XCTAssertEqual(quest.phase, .triggered)
    }
}

// MARK: - TriggerEvent Tests

final class TriggerEventTests: XCTestCase {
    
    func test_triggerEvent_taskCompleted() {
        let event = TriggerEvent.taskCompleted
        
        if case .taskCompleted = event {
            // Pass
        } else {
            XCTFail("Expected taskCompleted event")
        }
    }
    
    func test_triggerEvent_dayStreak() {
        let event = TriggerEvent.dayStreak(days: 7)
        
        if case .dayStreak(let days) = event {
            XCTAssertEqual(days, 7)
        } else {
            XCTFail("Expected dayStreak event")
        }
    }
}
