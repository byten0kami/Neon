
import SwiftUI

// MARK: - Overlay Effects

/// Visual effects that can be overlaid on the screen
enum OverlayEffect: Equatable, Sendable {
    case none
    case nyanCat
    case confetti
    case matrixRain
    case toxicGlow
    case securityScan
    case staticInterference
    
    /// Duration in seconds before effect auto-dismisses
    var duration: TimeInterval {
        switch self {
        case .none: return 0
        case .nyanCat: return 3.0
        case .confetti: return 2.5
        case .matrixRain: return 1.5
        case .toxicGlow: return 1.2
        case .securityScan: return 2.0
        case .staticInterference: return 1.2
        }
    }
}

// MARK: - Ambient Effects

/// Defines how a theme interacts with the overlay system
enum ThemeAmbientEffect: Equatable, Sendable {
    /// No ambient effect
    case none
    
    /// Effect occurs periodically at random intervals (e.g. Nyan Cat flying by)
    case periodic(effect: OverlayEffect, minInterval: TimeInterval, maxInterval: TimeInterval)
    
    /// Effect is always active while theme is selected (e.g. Toxic Glow)
    case constant(effect: OverlayEffect)
}

