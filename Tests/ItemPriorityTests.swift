import XCTest
@testable import NeonTracker

/// Unit tests for ItemPriority enum
final class ItemPriorityTests: XCTestCase {
    
    // MARK: - Comparable Tests
    
    func test_comparable_aiSortsFirst() {
        XCTAssertLessThan(ItemPriority.ai, ItemPriority.high)
        XCTAssertLessThan(ItemPriority.ai, ItemPriority.normal)
        XCTAssertLessThan(ItemPriority.ai, ItemPriority.low)
    }
    
    func test_comparable_highSortsSecond() {
        XCTAssertGreaterThan(ItemPriority.high, ItemPriority.ai)
        XCTAssertLessThan(ItemPriority.high, ItemPriority.normal)
        XCTAssertLessThan(ItemPriority.high, ItemPriority.low)
    }
    
    func test_comparable_sortOrderCorrect() {
        let unsorted: [ItemPriority] = [.low, .normal, .ai, .high]
        let sorted = unsorted.sorted()
        
        XCTAssertEqual(sorted, [.ai, .high, .normal, .low])
    }
    
    func test_sortOrder_values() {
        XCTAssertEqual(ItemPriority.ai.sortOrder, 0)
        XCTAssertEqual(ItemPriority.high.sortOrder, 1)
        XCTAssertEqual(ItemPriority.normal.sortOrder, 2)
        XCTAssertEqual(ItemPriority.low.sortOrder, 3)
    }
    
    // MARK: - String Conversion Tests
    
    func test_initFromString_high() {
        XCTAssertEqual(ItemPriority(from: "high"), .high)
        XCTAssertEqual(ItemPriority(from: "HIGH"), .high)
        XCTAssertEqual(ItemPriority(from: "High"), .high)
        // "critical", "asap", "urgent" now map to .high
        XCTAssertEqual(ItemPriority(from: "critical"), .high)
        XCTAssertEqual(ItemPriority(from: "CRITICAL"), .high)
        XCTAssertEqual(ItemPriority(from: "asap"), .high)
        XCTAssertEqual(ItemPriority(from: "ASAP"), .high)
        XCTAssertEqual(ItemPriority(from: "urgent"), .high)
        XCTAssertEqual(ItemPriority(from: "Urgent"), .high)
    }
    
    func test_initFromString_ai() {
        XCTAssertEqual(ItemPriority(from: "ai"), .ai)
        XCTAssertEqual(ItemPriority(from: "AI"), .ai)
        XCTAssertEqual(ItemPriority(from: "insight"), .ai)
        XCTAssertEqual(ItemPriority(from: "Insight"), .ai)
        XCTAssertEqual(ItemPriority(from: "suggestion"), .ai)
        XCTAssertEqual(ItemPriority(from: "SUGGESTION"), .ai)
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
        XCTAssertEqual(ItemPriority.allCases.count, 4)
        XCTAssertTrue(ItemPriority.allCases.contains(.ai))
        XCTAssertTrue(ItemPriority.allCases.contains(.high))
        XCTAssertTrue(ItemPriority.allCases.contains(.normal))
        XCTAssertTrue(ItemPriority.allCases.contains(.low))
    }
    
    // MARK: - Codable Tests
    
    func test_codable_encodeDecode() throws {
        let original = ItemPriority.high
        
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
