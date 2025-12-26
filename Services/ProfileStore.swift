import Foundation
import Combine
import SwiftUI

/// Manages user profile persistence and updates
/// Profile is now minimal - AI learns everything through conversation
@MainActor
class ProfileStore: ObservableObject {
    static let shared = ProfileStore()
    
    @Published var profile: UserProfile
    
    private let profileKey = "neurosync_user_profile"
    
    private init() {
        if let data = UserDefaults.standard.data(forKey: profileKey),
           let decoded = try? JSONDecoder().decode(UserProfile.self, from: data) {
            self.profile = decoded
        } else {
            self.profile = UserProfile()
        }
    }
    
    func save() {
        profile.updatedAt = Date()
        if let encoded = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(encoded, forKey: profileKey)
        }
    }
    
    func updateName(_ name: String) {
        profile.name = name
        save()
    }
    
    func updatePreferences(_ preferences: SchedulePreferences) {
        profile.preferences = preferences
        save()
    }
    
    func reset() {
        profile = UserProfile()
        AIKnowledgeBase.shared.reset()
        save()
    }
}
