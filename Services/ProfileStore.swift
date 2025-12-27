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
        self.profile = UserProfile()
        load()
    }
    
    // Extracted load logic to support migration
    private func load() {
        guard let data = UserDefaults.standard.data(forKey: profileKey) else {
            self.profile = UserProfile()
            return
        }
        
        // 1. Try decrypting
        if let decrypted = try? CryptoManager.shared.decrypt(data),
           let decoded = try? JSONDecoder().decode(UserProfile.self, from: decrypted) {
            self.profile = decoded
            return
        }
        
        // 2. Fallback: Legacy cleartext
        if let decoded = try? JSONDecoder().decode(UserProfile.self, from: data) {
            print("[ProfileStore] Migrating legacy profile to encrypted storage")
            self.profile = decoded
            // Re-save implementation will handle encryption called by the next save()
            // To be safe, we force a save now
            forceSave()
        } else {
            self.profile = UserProfile()
        }
    }
    
    private func forceSave() {
        save()
    }
    
    func save() {
        profile.updatedAt = Date()
        if let encoded = try? JSONEncoder().encode(profile) {
            if let encrypted = try? CryptoManager.shared.encrypt(encoded) {
                UserDefaults.standard.set(encrypted, forKey: profileKey)
            }
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
