import XCTest
@testable import NeonTracker

/// Unit tests for AIKnowledgeBase service
@MainActor
final class AIKnowledgeBaseTests: XCTestCase {
    
    var knowledgeBase: AIKnowledgeBase!
    
    override func setUp() async throws {
        try await super.setUp()
        knowledgeBase = AIKnowledgeBase.shared
        knowledgeBase.reset() // Clear state for each test
    }
    
    override func tearDown() async throws {
        knowledgeBase.reset()
        knowledgeBase = nil
        try await super.tearDown()
    }
    
    // MARK: - Add Fact Tests
    
    func test_addFact_addsFactToList() {
        XCTAssertTrue(knowledgeBase.facts.isEmpty)
        
        knowledgeBase.addFact("Takes vitamin D daily", category: "supplement")
        
        XCTAssertEqual(knowledgeBase.facts.count, 1)
        XCTAssertEqual(knowledgeBase.facts.first?.content, "Takes vitamin D daily")
    }
    
    func test_addFact_lowercasesCategory() {
        knowledgeBase.addFact("Test fact", category: "MEDICATION")
        
        XCTAssertEqual(knowledgeBase.facts.first?.category, "medication")
    }
    
    func test_addFact_setsSource() {
        knowledgeBase.addFact("Fact from user", category: "test", source: .userInput)
        
        XCTAssertEqual(knowledgeBase.facts.first?.source, .userInput)
    }
    
    func test_addFact_setsAINote() {
        knowledgeBase.addFact("Test", category: "test", aiNote: "Important observation")
        
        XCTAssertEqual(knowledgeBase.facts.first?.aiNote, "Important observation")
    }
    
    func test_addFact_updatesLastUpdated() {
        XCTAssertNil(knowledgeBase.lastUpdated)
        
        knowledgeBase.addFact("Test", category: "test")
        
        XCTAssertNotNil(knowledgeBase.lastUpdated)
    }
    
    // MARK: - Update Fact Tests
    
    func test_updateFact_modifiesContent() {
        knowledgeBase.addFact("Original", category: "test")
        let factId = knowledgeBase.facts.first!.id
        
        knowledgeBase.updateFact(id: factId, newContent: "Updated")
        
        XCTAssertEqual(knowledgeBase.facts.first?.content, "Updated")
    }
    
    func test_updateFact_modifiesAINote() {
        knowledgeBase.addFact("Test", category: "test")
        let factId = knowledgeBase.facts.first!.id
        
        knowledgeBase.updateFact(id: factId, aiNote: "New note")
        
        XCTAssertEqual(knowledgeBase.facts.first?.aiNote, "New note")
    }
    
    func test_updateFact_modifiesIsActive() {
        knowledgeBase.addFact("Test", category: "test")
        let factId = knowledgeBase.facts.first!.id
        
        XCTAssertTrue(knowledgeBase.facts.first!.isActive)
        
        knowledgeBase.updateFact(id: factId, isActive: false)
        
        XCTAssertFalse(knowledgeBase.facts.first!.isActive)
    }
    
    func test_updateFact_updatesTimestamp() {
        knowledgeBase.addFact("Test", category: "test")
        let factId = knowledgeBase.facts.first!.id
        let originalUpdatedAt = knowledgeBase.facts.first!.updatedAt
        
        // Small delay to ensure timestamp difference
        Thread.sleep(forTimeInterval: 0.01)
        
        knowledgeBase.updateFact(id: factId, newContent: "Changed")
        
        XCTAssertGreaterThan(knowledgeBase.facts.first!.updatedAt, originalUpdatedAt)
    }
    
    func test_updateFact_invalidIdDoesNothing() {
        knowledgeBase.addFact("Test", category: "test")
        let invalidId = UUID()
        
        knowledgeBase.updateFact(id: invalidId, newContent: "Should not apply")
        
        XCTAssertEqual(knowledgeBase.facts.first?.content, "Test")
    }
    
    // MARK: - Deactivate Fact Tests
    
    func test_deactivateFact_setsIsActiveFalse() {
        knowledgeBase.addFact("Test", category: "test")
        let factId = knowledgeBase.facts.first!.id
        
        knowledgeBase.deactivateFact(id: factId)
        
        XCTAssertFalse(knowledgeBase.facts.first!.isActive)
    }
    
    // MARK: - Reset Tests
    
    func test_reset_clearsAllFacts() {
        knowledgeBase.addFact("Fact 1", category: "a")
        knowledgeBase.addFact("Fact 2", category: "b")
        knowledgeBase.addFact("Fact 3", category: "c")
        
        XCTAssertEqual(knowledgeBase.facts.count, 3)
        
        knowledgeBase.reset()
        
        XCTAssertTrue(knowledgeBase.facts.isEmpty)
    }
    
    func test_reset_clearsLastUpdated() {
        knowledgeBase.addFact("Test", category: "test")
        XCTAssertNotNil(knowledgeBase.lastUpdated)
        
        knowledgeBase.reset()
        
        XCTAssertNil(knowledgeBase.lastUpdated)
    }
    
    // MARK: - Search Tests
    
    func test_search_findsByKeyword() {
        knowledgeBase.addFact("Takes vitamin D every morning", category: "supplement")
        knowledgeBase.addFact("Allergic to peanuts", category: "allergy")
        
        let results = knowledgeBase.search(query: "vitamin")
        
        XCTAssertEqual(results.count, 1)
        XCTAssertTrue(results.first?.content.contains("vitamin") ?? false)
    }
    
    func test_search_caseInsensitive() {
        knowledgeBase.addFact("Takes VITAMIN D", category: "supplement")
        
        let results = knowledgeBase.search(query: "vitamin")
        
        XCTAssertEqual(results.count, 1)
    }
    
    func test_search_excludesInactiveFacts() {
        knowledgeBase.addFact("Active fact with keyword", category: "test")
        knowledgeBase.addFact("Inactive fact with keyword", category: "test")
        let inactiveId = knowledgeBase.facts.last!.id
        knowledgeBase.deactivateFact(id: inactiveId)
        
        let results = knowledgeBase.search(query: "keyword")
        
        XCTAssertEqual(results.count, 1)
    }
    
    func test_search_returnsEmptyForNoMatch() {
        knowledgeBase.addFact("Test fact", category: "test")
        
        let results = knowledgeBase.search(query: "nonexistent")
        
        XCTAssertTrue(results.isEmpty)
    }
    
    // MARK: - Facts By Category Tests
    
    func test_factsInCategory_returnsCorrectFacts() {
        knowledgeBase.addFact("Medication 1", category: "medication")
        knowledgeBase.addFact("Medication 2", category: "medication")
        knowledgeBase.addFact("Routine 1", category: "routine")
        
        let medicationFacts = knowledgeBase.facts(in: "medication")
        
        XCTAssertEqual(medicationFacts.count, 2)
    }
    
    func test_factsInCategory_caseInsensitive() {
        knowledgeBase.addFact("Test", category: "medication")
        
        let results = knowledgeBase.facts(in: "MEDICATION")
        
        XCTAssertEqual(results.count, 1)
    }
    
    func test_factsInCategory_excludesInactive() {
        knowledgeBase.addFact("Active", category: "test")
        knowledgeBase.addFact("Inactive", category: "test")
        let inactiveId = knowledgeBase.facts.last!.id
        knowledgeBase.deactivateFact(id: inactiveId)
        
        let results = knowledgeBase.facts(in: "test")
        
        XCTAssertEqual(results.count, 1)
    }
    
    // MARK: - All Categories Tests
    
    func test_allCategories_returnsUniqueCategories() {
        knowledgeBase.addFact("A", category: "medication")
        knowledgeBase.addFact("B", category: "medication")
        knowledgeBase.addFact("C", category: "routine")
        knowledgeBase.addFact("D", category: "allergy")
        
        let categories = knowledgeBase.allCategories
        
        XCTAssertEqual(categories.count, 3)
        XCTAssertTrue(categories.contains("medication"))
        XCTAssertTrue(categories.contains("routine"))
        XCTAssertTrue(categories.contains("allergy"))
    }
    
    func test_allCategories_isSorted() {
        knowledgeBase.addFact("A", category: "zebra")
        knowledgeBase.addFact("B", category: "alpha")
        knowledgeBase.addFact("C", category: "middle")
        
        let categories = knowledgeBase.allCategories
        
        XCTAssertEqual(categories, ["alpha", "middle", "zebra"])
    }
    
    func test_allCategories_excludesInactive() {
        knowledgeBase.addFact("Active", category: "active_category")
        knowledgeBase.addFact("Inactive", category: "inactive_category")
        let inactiveId = knowledgeBase.facts.last!.id
        knowledgeBase.deactivateFact(id: inactiveId)
        
        let categories = knowledgeBase.allCategories
        
        XCTAssertTrue(categories.contains("active_category"))
        XCTAssertFalse(categories.contains("inactive_category"))
    }
    
    // MARK: - Context Generation Tests
    
    func test_toPromptContext_emptyMessage() {
        let context = knowledgeBase.toPromptContext()
        
        XCTAssertTrue(context.contains("No facts"))
    }
    
    func test_toPromptContext_groupsByCategory() {
        knowledgeBase.addFact("Fact A", category: "medication")
        knowledgeBase.addFact("Fact B", category: "routine")
        
        let context = knowledgeBase.toPromptContext()
        
        XCTAssertTrue(context.contains("[MEDICATION]"))
        XCTAssertTrue(context.contains("[ROUTINE]"))
        XCTAssertTrue(context.contains("Fact A"))
        XCTAssertTrue(context.contains("Fact B"))
    }
    
    func test_toPromptContext_includesAINotes() {
        knowledgeBase.addFact("Test fact", category: "test", aiNote: "Important note")
        
        let context = knowledgeBase.toPromptContext()
        
        XCTAssertTrue(context.contains("Important note"))
    }
    
    func test_toPromptContext_excludesInactiveFacts() {
        knowledgeBase.addFact("Active fact", category: "test")
        knowledgeBase.addFact("Inactive fact", category: "test")
        let inactiveId = knowledgeBase.facts.last!.id
        knowledgeBase.deactivateFact(id: inactiveId)
        
        let context = knowledgeBase.toPromptContext()
        
        XCTAssertTrue(context.contains("Active fact"))
        XCTAssertFalse(context.contains("Inactive fact"))
    }
}
