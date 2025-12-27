import Foundation

/// Type-safe theme identifiers
/// Add new cases here when creating new themes
enum ThemeID: String, CaseIterable, Sendable, Codable {
    case mercenary
    case corporate
    case terminal
    case stalker
    case nyan
    
    /// Default theme
    static var `default`: ThemeID { .mercenary }
    
    /// Get the theme instance for this ID
    var theme: any Theme {
        switch self {
        case .mercenary: return MercenaryTheme()
        case .corporate: return CorporateTheme()
        case .terminal: return TerminalTheme()
        case .stalker: return StalkerTheme()
        case .nyan: return NyanTheme()
        }
    }
    
    /// All themes in display order
    static var allThemes: [any Theme] {
        allCases.map { $0.theme }
    }
}
