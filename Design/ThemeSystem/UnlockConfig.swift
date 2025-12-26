import Foundation

// MARK: - Unlock Configuration

/// Configuration for theme unlock requirements
/// Themes themselves don't know if they're locked - this config does
/// 
/// To add an unlockable theme:
/// 1. Add the ThemeID and reward ID to `themeUnlockRequirements`
/// 2. Ensure RewardManager can grant the reward ID
enum UnlockConfig {
    
    /// Themes that require unlock and their reward IDs
    /// If a theme isn't in this dictionary, it's available by default
    static let themeUnlockRequirements: [ThemeID: String] = [
        .nyan: "theme_nyan"
        // Add more unlockable themes here
    ]
    
    /// Check if a theme requires unlock
    static func requiresUnlock(_ themeID: ThemeID) -> Bool {
        themeUnlockRequirements[themeID] != nil
    }
    
    /// Get the reward ID needed to unlock a theme (nil if no unlock needed)
    static func unlockRewardID(for themeID: ThemeID) -> String? {
        themeUnlockRequirements[themeID]
    }
}
