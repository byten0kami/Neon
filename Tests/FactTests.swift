import XCTest
@testable import NeonTracker

/// Unit tests for Fact model and related types
final class FactTests: XCTestCase {
    
    // MARK: - Initialization Tests
    
    func test_init_categoryIsLowercased() {
        let fact = Fact(content: "Test content", category: "MEDICATION")
        
        XCTAssertEqual(fact.category, "medication")
    }
    
    func test_init_categoryWithMixedCase() {
        let fact = Fact(content: "Test", category: "MyCategory")
        
        XCTAssertEqual(fact.category, "mycategory")
    }
    
    func test_init_defaultsAreCorrect() {
        let fact = Fact(content: "Test", category: "test")
        
        XCTAssertTrue(fact.isActive)
        XCTAssertEqual(fact.source, .conversation)
        XCTAssertNil(fact.aiNote)
    }
    
    func test_init_timestampsAreSet() {
        let beforeInit = Date()
        let fact = Fact(content: "Test", category: "test")
        let afterInit = Date()
        
        XCTAssertGreaterThanOrEqual(fact.createdAt, beforeInit)
        XCTAssertLessThanOrEqual(fact.createdAt, afterInit)
        XCTAssertGreaterThanOrEqual(fact.updatedAt, beforeInit)
        XCTAssertLessThanOrEqual(fact.updatedAt, afterInit)
    }
    
    func test_init_customValues() {
        let id = UUID()
        let fact = Fact(
            id: id,
            content: "Custom content",
            category: "custom",
            source: .userInput,
            aiNote: "A note",
            isActive: false
        )
        
        XCTAssertEqual(fact.id, id)
        XCTAssertEqual(fact.content, "Custom content")
        XCTAssertEqual(fact.category, "custom")
        XCTAssertEqual(fact.source, .userInput)
        XCTAssertEqual(fact.aiNote, "A note")
        XCTAssertFalse(fact.isActive)
    }
    
    // MARK: - Identifiable Tests
    
    func test_identifiable_hasUniqueId() {
        let fact1 = Fact(content: "A", category: "test")
        let fact2 = Fact(content: "A", category: "test")
        
        XCTAssertNotEqual(fact1.id, fact2.id)
    }
    
    // MARK: - Codable Tests
    
    func test_codable_roundTrip() throws {
        let original = Fact(
            content: "Takes medication at 9am",
            category: "medication",
            source: .inferred,
            aiNote: "Important"
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Fact.self, from: data)
        
        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.content, original.content)
        XCTAssertEqual(decoded.category, original.category)
        XCTAssertEqual(decoded.source, original.source)
        XCTAssertEqual(decoded.aiNote, original.aiNote)
        XCTAssertEqual(decoded.isActive, original.isActive)
    }
}

// MARK: - FactSource Tests

final class FactSourceTests: XCTestCase {
    
    func test_allCasesExist() {
        // Verify all expected cases exist
        let _ = FactSource.conversation
        let _ = FactSource.userInput
        let _ = FactSource.inferred
        let _ = FactSource.imported
    }
    
    func test_codable_roundTrip() throws {
        let sources: [FactSource] = [.conversation, .userInput, .inferred, .imported]
        
        for source in sources {
            let encoder = JSONEncoder()
            let data = try encoder.encode(source)
            
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(FactSource.self, from: data)
            
            XCTAssertEqual(source, decoded, "Failed round-trip for \(source)")
        }
    }
    
    func test_rawValues() {
        XCTAssertEqual(FactSource.conversation.rawValue, "conversation")
        XCTAssertEqual(FactSource.userInput.rawValue, "userInput")
        XCTAssertEqual(FactSource.inferred.rawValue, "inferred")
        XCTAssertEqual(FactSource.imported.rawValue, "imported")
    }
}

// MARK: - SuggestedCategory Tests

final class SuggestedCategoryTests: XCTestCase {
    
    func test_icon_returnsValidSFSymbol() {
        // All icons should be valid SF Symbols (just verify they return strings)
        XCTAssertFalse(SuggestedCategory.medication.icon.isEmpty)
        XCTAssertFalse(SuggestedCategory.condition.icon.isEmpty)
        XCTAssertFalse(SuggestedCategory.routine.icon.isEmpty)
        XCTAssertFalse(SuggestedCategory.preference.icon.isEmpty)
        XCTAssertFalse(SuggestedCategory.activity.icon.isEmpty)
        XCTAssertFalse(SuggestedCategory.event.icon.isEmpty)
        XCTAssertFalse(SuggestedCategory.constraint.icon.isEmpty)
    }
    
    func test_rawValues() {
        XCTAssertEqual(SuggestedCategory.medication.rawValue, "medication")
        XCTAssertEqual(SuggestedCategory.condition.rawValue, "condition")
        XCTAssertEqual(SuggestedCategory.routine.rawValue, "routine")
        XCTAssertEqual(SuggestedCategory.preference.rawValue, "preference")
        XCTAssertEqual(SuggestedCategory.activity.rawValue, "activity")
        XCTAssertEqual(SuggestedCategory.event.rawValue, "event")
        XCTAssertEqual(SuggestedCategory.constraint.rawValue, "constraint")
    }
}
