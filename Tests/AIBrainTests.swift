import XCTest
@testable import NeonTracker

// Mock Service
actor MockAIService: AIServiceProtocol {
    var nextResponse: AIServiceResponse?
    var nextError: Error?
    
    func sendMessage(context: String, userMessage: String, history: [ChatMessage]) async throws -> AIServiceResponse {
        if let error = nextError {
            throw error
        }
        return nextResponse ?? AIServiceResponse(message: "Mock default", actions: [])
    }
    
    func askBrain(prompt: String) async throws -> String {
        return "Mock brain response"
    }
}

@MainActor
final class AIBrainTests: XCTestCase {
    
    var brain: AIBrain!
    var mockService: MockAIService!
    
    override func setUp() {
        super.setUp()
        mockService = MockAIService()
        brain = AIBrain(service: mockService)
    }
    
    func test_processUserInput_returnsResponse() async {
        let expectedResponse = AIServiceResponse(
            message: "Hello world",
            actions: []
        )
        await mockService.setNextResponse(expectedResponse)
        
        let result = await brain.processUserInput("Hi")
        
        XCTAssertEqual(result.message, "Hello world")
        XCTAssertTrue(result.pendingActions.isEmpty)
    }
    
    func test_processUserInput_returnsActions() async {
        let action = AIAction.createTimelineItem(title: "Test", description: nil, priority: "normal", time: "10:00", recurrence: nil)
        let expectedResponse = AIServiceResponse(
            message: "Done",
            actions: [action]
        )
        await mockService.setNextResponse(expectedResponse)
        
        let result = await brain.processUserInput("Create task")
        
        XCTAssertEqual(result.message, "Done")
        XCTAssertEqual(result.pendingActions.count, 1)
        
        if case .createTimelineItem(let title, _, _, _, _) = result.pendingActions.first {
            XCTAssertEqual(title, "Test")
        } else {
            XCTFail("Wrong action")
        }
    }
    
    func test_processUserInput_handlesError() async {
        await mockService.setNextError(AIError.apiError("Network fail"))
        
        let result = await brain.processUserInput("Hi")
        
        XCTAssertTrue(result.message.contains("Network fail"))
        XCTAssertTrue(result.message.contains("SYNC ERROR"))
    }
}

extension MockAIService {
    func setNextResponse(_ response: AIServiceResponse) {
        self.nextResponse = response
    }
    
    func setNextError(_ error: Error) {
        self.nextError = error
    }
}
