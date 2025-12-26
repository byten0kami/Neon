import SwiftUI

// MARK: - Protocols View (Placeholder)

/// Bio-Kernel view - TO BE IMPLEMENTED  
/// Currently shows placeholder while CMD tab is in active development
struct ProtocolsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("[PROTO]")
                .font(.custom(Theme.monoFont, size: 24))
                .foregroundColor(Theme.purple)
            
            Text("BIO-KERNEL")
                .font(.custom(Theme.displayFont, size: 32))
                .foregroundColor(.white)
            
            Text("Coming soon...")
                .font(.custom(Theme.lightFont, size: 16))
                .foregroundColor(Theme.slate500)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            CyberpunkBackground()
                .ignoresSafeArea()
        )
    }
}

#Preview {
    ProtocolsView()
}
