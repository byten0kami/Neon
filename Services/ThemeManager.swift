import SwiftUI
import Combine

// MARK: - Theme Manager

/// Manages the application's visual theme
/// Single source of truth for current theme and available themes
@MainActor
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentTheme: any Theme
    @Published var availableThemes: [any Theme] = []
    
    private let selectedThemeKey = "neon_selected_theme_id"
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        self.currentTheme = ThemeRegistry.defaultTheme
        self.availableThemes = []
        
        // Load saved theme and available themes
        refreshAvailableThemes()
        loadTheme()
        
        // Listen to RewardManager to update available themes when unlocks change
        RewardManager.shared.$unlockedRewardIDs
            .sink { [weak self] _ in
                self?.refreshAvailableThemes()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Theme Selection
    
    func setTheme(_ themeID: ThemeID) {
        // Refresh first to pick up any newly unlocked themes
        refreshAvailableThemes()
        
        if availableThemes.contains(where: { $0.id == themeID }) {
            currentTheme = ThemeRegistry.theme(for: themeID)
            UserDefaults.standard.set(themeID.rawValue, forKey: selectedThemeKey)
        }
    }
    
    // MARK: - Priority Style (delegates to current theme)
    
    func priorityTagStyle(for priority: ItemPriority) -> PriorityTagStyle {
        currentTheme.priorityTagStyle(for: priority)
    }
    
    // MARK: - Private
    
    private func loadTheme() {
        let savedRaw = UserDefaults.standard.string(forKey: selectedThemeKey) ?? ThemeID.mercenary.rawValue
        
        if let savedID = ThemeID(rawValue: savedRaw),
           availableThemes.contains(where: { $0.id == savedID }) {
            currentTheme = ThemeRegistry.theme(for: savedID)
        } else {
            currentTheme = ThemeRegistry.defaultTheme
        }
    }
    
    private func refreshAvailableThemes() {
        var themes: [any Theme] = []
        
        for theme in ThemeRegistry.all {
            if UnlockConfig.requiresUnlock(theme.id) {
                // Check if unlocked via RewardManager
                if let rewardID = UnlockConfig.unlockRewardID(for: theme.id),
                   RewardManager.shared.isUnlocked(id: rewardID) {
                    themes.append(theme)
                }
            } else {
                // Always available
                themes.append(theme)
            }
        }
        
        self.availableThemes = themes
        
        // Validate current theme is still available
        if !themes.contains(where: { $0.id == currentTheme.id }) {
            currentTheme = ThemeRegistry.defaultTheme
        }
    }
}
