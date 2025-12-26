import Foundation

// MARK: - User Profile

/// Minimal user profile - just basic preferences
/// All health data is now stored in AIKnowledgeBase
struct UserProfile: Codable, Identifiable {
    let id: UUID
    var name: String
    var preferences: SchedulePreferences
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        name: String = "",
        preferences: SchedulePreferences = SchedulePreferences()
    ) {
        self.id = id
        self.name = name
        self.preferences = preferences
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    /// Convert to JSON for AI context
    func toJSON() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        guard let data = try? encoder.encode(self),
              let json = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return json
    }
}
