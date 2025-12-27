import XCTest
@testable import NeonTracker

@MainActor
final class AIServiceTests: XCTestCase {
    
    var service: AIService!
    
    override func setUp() {
        super.setUp()
        service = AIService() as? AIService
    }
    
    func test_extractOutermostJSON_simple() {
        let input = "Here is json: {\"key\": \"value\"}"
        let extracted = service.extractOutermostJSON(from: input)
        XCTAssertEqual(extracted, "{\"key\": \"value\"}")
    }
    
    func test_extractOutermostJSON_nested() {
        let input = "Text { \"outer\": { \"inner\": 1 } } end"
        let extracted = service.extractOutermostJSON(from: input)
        XCTAssertEqual(extracted, "{ \"outer\": { \"inner\": 1 } }")
    }
    
    func test_extractOutermostJSON_markdown() {
        let input = "```json\n{\"a\": 1}\n```"
        let extracted = service.extractOutermostJSON(from: input)
        // Note: extractOutermostJSON doesn't strip markdown, parseResponse does.
        // It just finding the first { and matching }
        XCTAssertEqual(extracted, "{\"a\": 1}")
    }
    
    func test_parseResponse_validJSON_addFact() {
        let json = """
        {
            "message": "Saved fact.",
            "actions": [
                {
                    "type": "add_fact",
                    "category": "medication",
                    "content": "Takes A",
                    "note": "Note"
                }
            ]
        }
        """
        
        let response = service.parseResponse(json)
        XCTAssertEqual(response.message, "Saved fact.")
        XCTAssertEqual(response.actions.count, 1)
        
        if case .addFact(let content, let category, let note) = response.actions.first {
            XCTAssertEqual(content, "Takes A")
            XCTAssertEqual(category, "medication")
            XCTAssertEqual(note, "Note")
        } else {
            XCTFail("Wrong action type")
        }
    }
    
    func test_parseResponse_validJSON_createItem() {
        let json = """
        {
            "message": "Created task.",
            "actions": [
                {
                    "type": "create_timeline_item",
                    "title": "Gym",
                    "time": "18:00",
                    "priority": "high"
                }
            ]
        }
        """
        
        let response = service.parseResponse(json)
        XCTAssertEqual(response.message, "Created task.")
        
        if case .createTimelineItem(let title, _, let priority, let time, let recurrence) = response.actions.first {
            XCTAssertEqual(title, "Gym")
            XCTAssertEqual(priority, "high")
            XCTAssertEqual(time, "18:00")
            XCTAssertNil(recurrence)
        } else {
            XCTFail("Wrong action type")
        }
    }
    
    func test_parseResponse_recurrence() {
        let json = """
        {
            "message": "Recurring.",
            "actions": [
                {
                    "type": "create_timeline_item",
                    "title": "Meds",
                    "recurrence": {
                        "frequency": "daily",
                        "interval": 1,
                        "endCondition": { "type": "count", "value": 5 }
                    }
                }
            ]
        }
        """
        
        let response = service.parseResponse(json)
        if case .createTimelineItem(_, _, _, _, let recurrence) = response.actions.first {
            XCTAssertNotNil(recurrence)
            XCTAssertEqual(recurrence?.frequency, "daily")
            if case .count(let n) = recurrence?.endCondition {
                XCTAssertEqual(n, 5)
            } else {
                XCTFail("Wrong end condition")
            }
        } else {
            XCTFail("Wrong action type")
        }
    }
    
    func test_parseResponse_sanitization() {
        let json = """
        {
            "message": "<b>Created</b> task.",
            "actions": [
                {
                    "type": "create_timeline_item",
                    "title": "**Bold** & <i>Italic</i> Task",
                    "description": "<h1>Header</h1> content.",
                    "priority": "normal"
                }
            ]
        }
        """
        
        let response = service.parseResponse(json)
        
        // Message should be sanitized
        XCTAssertEqual(response.message, "Created task.")
        
        guard let action = response.actions.first else {
            XCTFail("No action found")
            return
        }
        
        if case .createTimelineItem(let title, let description, _, _, _) = action {
            // Check title sanitization
            XCTAssertEqual(title, "Bold & Italic Task")
            // Check description sanitization
            XCTAssertEqual(description, "Header content.")
        } else {
            XCTFail("Wrong action type")
        }
    }
    
    func test_parseResponse_titleLength() {
        let longTitle = String(repeating: "A", count: 300)
        let json = """
        {
            "message": "Long task",
            "actions": [
                {
                    "type": "create_timeline_item",
                    "title": "\(longTitle)",
                    "priority": "normal"
                }
            ]
        }
        """
        
        let response = service.parseResponse(json)
        
        if case .createTimelineItem(let title, _, _, _, _) = response.actions.first {
            XCTAssertEqual(title.count, 200)
            XCTAssertEqual(title, String(repeating: "A", count: 200))
        } else {
            XCTFail("Wrong action type")
        }
    }
    
    func test_parseResponse_recurrence_validation() {
        let json = """
        {
            "message": "Recurring.",
            "actions": [
                {
                    "type": "create_timeline_item",
                    "title": "Invalid Recurrence",
                    "recurrence": {
                        "frequency": "invalid_freq",
                        "interval": -1
                    }
                },
                {
                    "type": "create_timeline_item",
                    "title": "Valid Recurrence",
                    "recurrence": {
                        "frequency": "weekly",
                        "interval": 2,
                        "weekdays": [0, 6]
                    }
                }
            ]
        }
        """
        
        let response = service.parseResponse(json)
        XCTAssertEqual(response.actions.count, 2)
        
        // First item should have NO recurrence because validation failed
        if case .createTimelineItem(let title, _, _, _, let recurrence) = response.actions[0] {
            XCTAssertEqual(title, "Invalid Recurrence")
            XCTAssertNil(recurrence, "Recurrence should be nil for invalid data")
        } else {
            XCTFail("Wrong action type 1")
        }
        
        // Second item should have valid recurrence
        if case .createTimelineItem(let title, _, _, _, let recurrence2) = response.actions[1] {
             XCTAssertEqual(title, "Valid Recurrence")
             XCTAssertNotNil(recurrence2)
             XCTAssertEqual(recurrence2?.frequency, "weekly")
             XCTAssertEqual(recurrence2?.interval, 2)
             XCTAssertEqual(recurrence2?.weekdays, [0, 6])
        } else {
             XCTFail("Wrong action type 2")
        }
    }
    
    func test_parseResponse_malformed() {
        let text = "Not a JSON"
        let response = service.parseResponse(text)
        XCTAssertEqual(response.message, "Not a JSON")
        XCTAssertTrue(response.actions.isEmpty)
    }
}
