import SwiftUI
import Combine

/// Manages the application's visual theme
@MainActor
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentTheme: ThemeConfig
    
    // Available themes based on unlock status
    @Published var availableThemes: [ThemeConfig] = []
    
    private let selectedThemeKey = "neon_selected_theme_id"
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Initialize with default
        self.currentTheme = ThemeConfig.cyberpunk
        self.availableThemes = [ThemeConfig.cyberpunk]
        
        // Load saved theme
        loadTheme()
        
        // Listen to RewardManager to update available themes
        RewardManager.shared.$unlockedRewardIDs
            .sink { [weak self] _ in
                self?.refreshAvailableThemes()
            }
            .store(in: &cancellables)
            
        refreshAvailableThemes()
    }
    
    // MARK: - Logic
    
    func setTheme(_ themeID: String) {
        if let theme = availableThemes.first(where: { $0.id == themeID }) {
            currentTheme = theme
            UserDefaults.standard.set(themeID, forKey: selectedThemeKey)
        }
    }
    
    private func loadTheme() {
        _ = UserDefaults.standard.string(forKey: selectedThemeKey) ?? "default"
        
        // We can only load it if it's available (or default)
        // Since availability depends on rewards, we might need to defer until after refresh
        // For now, if savedID is nyan but not unlocked, we fall back to default
        // checks happen in refreshAvailableThemes
    }
    
    private func refreshAvailableThemes() {
        var themes = [ThemeConfig.cyberpunk]
        
        if RewardManager.shared.isUnlocked(id: "theme_nyan") {
            themes.append(ThemeConfig.nyan)
        }
        
        self.availableThemes = themes
        
        // Restore saved theme if valid
        let savedID = UserDefaults.standard.string(forKey: selectedThemeKey) ?? "default"
        if let matchedTheme = themes.first(where: { $0.id == savedID }) {
            self.currentTheme = matchedTheme
        } else {
            // Fallback if saved theme is no longer valid (shouldn't happen strictly)
            self.currentTheme = ThemeConfig.cyberpunk
        }
    }
}
