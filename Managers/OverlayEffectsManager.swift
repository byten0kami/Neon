import SwiftUI
import Combine

enum OverlayEffect: Equatable {
    case none
    case nyanCat
    case confetti
}

/// Controls full-screen visual effects overlaid on the app
@MainActor
class OverlayEffectsManager: ObservableObject {
    static let shared = OverlayEffectsManager()
    
    @Published var currentEffect: OverlayEffect = .none
    
    private init() {}
    
    func showEffect(_ effect: OverlayEffect) {
        withAnimation {
            currentEffect = effect
        }
    }
    
    func dismiss() {
        withAnimation {
            currentEffect = .none
        }
    }
}
