import Foundation

/// Reward granted upon quest completion
struct Reward: Codable, Identifiable, Equatable {
    let id: String
    let title: String
    let description: String?
    let icon: String?
    
    init(id: String, title: String, description: String? = nil, icon: String? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.icon = icon
    }
}
