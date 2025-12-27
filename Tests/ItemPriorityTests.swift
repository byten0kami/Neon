import XCTest
@testable import NeonTracker

/// Unit tests for ItemPriority enum
final class ItemPriorityTests: XCTestCase {
    
    // MARK: - Comparable Tests
    
    func test_comparable_aiSortsFirst() {
        XCTAssertLessThan(ItemPriority.ai, ItemPriority.critical)
        XCTAssertLessThan(ItemPriority.ai, ItemPriority.high)
        XCTAssertLessThan(ItemPriority.ai, ItemPriority.normal)
        XCTAssertLessThan(ItemPriority.ai, ItemPriority.low)
    }
    
    func test_comparable_criticalSortsSecond() {
        XCTAssertGreaterThan(ItemPriority.critical, ItemPriority.ai)
        XCTAssertLessThan(ItemPriority.critical, ItemPriority.high)
        XCTAssertLessThan(ItemPriority.critical, ItemPriority.normal)
        XCTAssertLessThan(ItemPriority.critical, ItemPriority.low)
    }
    
    func test_comparable_sortOrderCorrect() {
        let unsorted: [ItemPriority] = [.low, .normal, .critical, .ai, .high]
        let sorted = unsorted.sorted()
        
        XCTAssertEqual(sorted, [.ai, .critical, .high, .normal, .low])
    }
    
    func test_sortOrder_values() {
        XCTAssertEqual(ItemPriority.ai.sortOrder, 0)
        XCTAssertEqual(ItemPriority.critical.sortOrder, 1)
        XCTAssertEqual(ItemPriority.high.sortOrder, 2)
        XCTAssertEqual(ItemPriority.normal.sortOrder, 3)
        XCTAssertEqual(ItemPriority.low.sortOrder, 4)
    }
    
    // MARK: - String Conversion Tests
    
    func test_initFromString_critical() {
        XCTAssertEqual(ItemPriority(from: "critical"), .critical)
        XCTAssertEqual(ItemPriority(from: "CRITICAL"), .critical)
        XCTAssertEqual(ItemPriority(from: "asap"), .critical)
        XCTAssertEqual(ItemPriority(from: "ASAP"), .critical)
        XCTAssertEqual(ItemPriority(from: "urgent"), .critical)
        XCTAssertEqual(ItemPriority(from: "Urgent"), .critical)
    }
    
    func test_initFromString_ai() {
        XCTAssertEqual(ItemPriority(from: "ai"), .ai)
        XCTAssertEqual(ItemPriority(from: "AI"), .ai)
        XCTAssertEqual(ItemPriority(from: "insight"), .ai)
        XCTAssertEqual(ItemPriority(from: "Insight"), .ai)
        XCTAssertEqual(ItemPriority(from: "suggestion"), .ai)
        XCTAssertEqual(ItemPriority(from: "SUGGESTION"), .ai)
    }
    
    func test_initFromString_high() {
        XCTAssertEqual(ItemPriority(from: "high"), .high)
        XCTAssertEqual(ItemPriority(from: "HIGH"), .high)
        XCTAssertEqual(ItemPriority(from: "High"), .high)
    }
    
    func test_initFromString_low() {
        XCTAssertEqual(ItemPriority(from: "low"), .low)
        XCTAssertEqual(ItemPriority(from: "LOW"), .low)
        XCTAssertEqual(ItemPriority(from: "Low"), .low)
    }
    
    func test_initFromString_defaultsToNormal() {
        XCTAssertEqual(ItemPriority(from: "unknown"), .normal)
        XCTAssertEqual(ItemPriority(from: ""), .normal)
        XCTAssertEqual(ItemPriority(from: "medium"), .normal)
        XCTAssertEqual(ItemPriority(from: "regular"), .normal)
    }
    
    // MARK: - Display Tests
    
    func test_displayName_correctStrings() {
        XCTAssertEqual(ItemPriority.critical.displayName, "CRITICAL")
        XCTAssertEqual(ItemPriority.ai.displayName, "AI")
        XCTAssertEqual(ItemPriority.high.displayName, "HIGH")
        XCTAssertEqual(ItemPriority.normal.displayName, "NORMAL")
        XCTAssertEqual(ItemPriority.low.displayName, "LOW")
    }
    
    func test_badgeText_alwaysReturnsTask() {
        for priority in ItemPriority.allCases {
            XCTAssertEqual(priority.badgeText, "TASK", "Badge text should be TASK for \(priority)")
        }
    }
    
    // MARK: - CaseIterable Tests
    
    func test_allCases_containsAllPriorities() {
        XCTAssertEqual(ItemPriority.allCases.count, 5)
        XCTAssertTrue(ItemPriority.allCases.contains(.critical))
        XCTAssertTrue(ItemPriority.allCases.contains(.ai))
        XCTAssertTrue(ItemPriority.allCases.contains(.high))
        XCTAssertTrue(ItemPriority.allCases.contains(.normal))
        XCTAssertTrue(ItemPriority.allCases.contains(.low))
    }
    
    // MARK: - Codable Tests
    
    func test_codable_encodeDecode() throws {
        let original = ItemPriority.critical
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ItemPriority.self, from: data)
        
        XCTAssertEqual(original, decoded)
    }
    
    func test_codable_allCasesRoundTrip() throws {
        for priority in ItemPriority.allCases {
            let encoder = JSONEncoder()
            let data = try encoder.encode(priority)
            
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(ItemPriority.self, from: data)
            
            XCTAssertEqual(priority, decoded, "Failed round-trip for \(priority)")
        }
    }
}
