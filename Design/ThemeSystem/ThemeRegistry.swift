import Foundation

// MARK: - Theme Registry

/// Central registry for all available themes
/// Single source of truth for theme registration and lookup
///
/// To add a new theme:
/// 1. Add case to ThemeID
/// 2. Create struct in Design/Themes/ conforming to Theme
/// 3. Add to `all` array below
/// 4. (Optional) Add to UnlockConfig if unlockable
enum ThemeRegistry {
    
    // MARK: - All Themes
    
    /// All themes in display order
    static let all: [any Theme] = [
        MercenaryTheme(),
        CorporateTheme(),
        TerminalTheme(),
        StalkerTheme(),
        NyanTheme()
    ]
    
    // MARK: - Lookup
    
    /// Get theme by ID
    static func theme(for id: ThemeID) -> any Theme {
        all.first { $0.id == id } ?? defaultTheme
    }
    
    /// Default theme when nothing else is selected
    static var defaultTheme: any Theme { MercenaryTheme() }
    
    // MARK: - Convenience Accessors
    
    static var mercenary: any Theme { MercenaryTheme() }
    static var corporate: any Theme { CorporateTheme() }
    static var terminal: any Theme { TerminalTheme() }
    static var stalker: any Theme { StalkerTheme() }
    static var nyan: any Theme { NyanTheme() }
}
