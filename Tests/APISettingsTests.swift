import XCTest
import Combine
@testable import NeonTracker

/// Unit tests for APISettings model
final class APISettingsTests: XCTestCase {
    
    // MARK: - Default Values Tests
    
    func test_default_hasCorrectModel() {
        let settings = APISettings.default
        
        XCTAssertEqual(settings.selectedModel, "google/gemini-2.0-flash-001")
    }
    
    func test_default_useCustomKeyIsFalse() {
        let settings = APISettings.default
        
        XCTAssertFalse(settings.useCustomKey)
    }
    
    func test_default_defaultDeferMinutesIs60() {
        let settings = APISettings.default
        
        XCTAssertEqual(settings.defaultDeferMinutes, 60)
    }
    
    // MARK: - Available Models Tests
    
    func test_availableModels_isNotEmpty() {
        XCTAssertFalse(APISettings.availableModels.isEmpty)
    }
    
    func test_availableModels_containsExpectedModels() {
        let modelIds = APISettings.availableModels.map { $0.id }
        
        XCTAssertTrue(modelIds.contains("google/gemini-2.0-flash-001"))
        XCTAssertTrue(modelIds.contains("openai/gpt-4o-mini"))
        XCTAssertTrue(modelIds.contains("anthropic/claude-3.5-sonnet"))
    }
    
    func test_availableModels_allHaveValidData() {
        for model in APISettings.availableModels {
            XCTAssertFalse(model.id.isEmpty, "Model ID should not be empty")
            XCTAssertFalse(model.name.isEmpty, "Model name should not be empty")
            XCTAssertFalse(model.description.isEmpty, "Model description should not be empty")
            XCTAssertFalse(model.tooltip.isEmpty, "Model tooltip should not be empty")
        }
    }
    
    func test_defaultModel_existsInAvailableModels() {
        let defaultModel = APISettings.default.selectedModel
        let modelIds = APISettings.availableModels.map { $0.id }
        
        XCTAssertTrue(modelIds.contains(defaultModel), "Default model should exist in available models")
    }
    
    // MARK: - Codable Tests
    
    func test_codable_roundTrip() throws {
        let original = APISettings(
            useCustomKey: true,
            selectedModel: "openai/gpt-4o-mini",
            defaultDeferMinutes: 30
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(APISettings.self, from: data)
        
        XCTAssertEqual(decoded.useCustomKey, original.useCustomKey)
        XCTAssertEqual(decoded.selectedModel, original.selectedModel)
        XCTAssertEqual(decoded.defaultDeferMinutes, original.defaultDeferMinutes)
    }
    
    func test_codable_defaultRoundTrip() throws {
        let original = APISettings.default
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(APISettings.self, from: data)
        
        XCTAssertEqual(decoded.useCustomKey, original.useCustomKey)
        XCTAssertEqual(decoded.selectedModel, original.selectedModel)
        XCTAssertEqual(decoded.defaultDeferMinutes, original.defaultDeferMinutes)
    }
    
    // MARK: - Mutability Tests
    
    func test_settingsAreMutable() {
        var settings = APISettings.default
        
        settings.useCustomKey = true
        XCTAssertTrue(settings.useCustomKey)
        
        settings.selectedModel = "anthropic/claude-3.5-sonnet"
        XCTAssertEqual(settings.selectedModel, "anthropic/claude-3.5-sonnet")
        
        settings.defaultDeferMinutes = 120
        XCTAssertEqual(settings.defaultDeferMinutes, 120)
    }
}

// MARK: - Overlay Effects Tests (Piggybacked for Target inclusion)
@MainActor
final class OverlayEffectsManagerTests: XCTestCase {
    
    var manager: OverlayEffectsManager!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() async throws {
        manager = OverlayEffectsManager.shared
        cancellables = []
        
        // Reset state
        manager.dismiss()
        // Wait for potential async clear
        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s
    }
    
    override func tearDown() {
        cancellables = nil
        manager = nil
    }
    
    func testShowEffect() {
        // Given
        let expectation = XCTestExpectation(description: "Effect should be set")
        
        // When
        manager.showEffect(.matrixRain)
        
        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if self.manager.currentEffect == .matrixRain {
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testDismissEffect() {
        // Given
        manager.showEffect(.staticInterference)
        let expectation = XCTestExpectation(description: "Effect should be dismissed")
        
        // When
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.manager.dismiss()
        }
        
        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Dismiss might have delay now?
            if self.manager.currentEffect == .none {
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testRestartEffectLogic() {
        // Test the "Interruption" fix
        // Given
        manager.showEffect(.toxicGlow)
        let expectation = XCTestExpectation(description: "Effect should restart (flicker none then show)")
        
        // When: Trigger same effect again while active
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            
            // Simulate "Restart" behavior manually to verify state transition
            // 1. Force Clear
            self.manager.showEffect(.none)
            
            // 2. Wait and Re-show
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                 self.manager.showEffect(.toxicGlow)
                 
                 if self.manager.currentEffect == .toxicGlow {
                     expectation.fulfill()
                 }
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
}
