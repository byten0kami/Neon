import Foundation
import Combine

/// Manages the unlocking of rewards based on quest completion
@MainActor
class RewardManager: ObservableObject {
    static let shared = RewardManager()
    
    @Published var unlockedRewardIDs: Set<String> = []
    
    private let rewardsKey = "neon_unlocked_rewards"
    
    private init() {
        loadRewards()
    }
    
    // MARK: - Persistence
    
    private func loadRewards() {
        if let data = UserDefaults.standard.data(forKey: rewardsKey),
           let decoded = try? JSONDecoder().decode(Set<String>.self, from: data) {
            self.unlockedRewardIDs = decoded
        } else {
            self.unlockedRewardIDs = []
        }
    }
    
    private func saveRewards() {
        if let encoded = try? JSONEncoder().encode(unlockedRewardIDs) {
            UserDefaults.standard.set(encoded, forKey: rewardsKey)
        }
    }
    
    // MARK: - Logic
    
    /// Unlocks a reward with a specific ID
    func unlockReward(id: String) {
        if !unlockedRewardIDs.contains(id) {
            unlockedRewardIDs.insert(id)
            saveRewards()
            print("🏆 Reward Unlocked: \(id)")
        }
    }
    
    /// Checks if a reward is unlocked
    func isUnlocked(id: String) -> Bool {
        return unlockedRewardIDs.contains(id)
    }
}
