import SwiftUI

// MARK: - Timeline Card Action

/// Represents an action button that can be attached to a card
struct TimelineCardAction {
    let title: String
    let color: Color
    var icon: String? = nil  // SF Symbol name
    var isFilled: Bool = false
    let action: () -> Void
}
