import SwiftUI

// MARK: - Protocols View (Placeholder)

/// Bio-Kernel view - TO BE IMPLEMENTED  
/// Currently shows placeholder while CMD tab is in active development
struct ProtocolsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("[PROTO]")
                .font(.custom(DesignSystem.monoFont, size: 24))
                .foregroundColor(DesignSystem.purple)
            
            Text("BIO-KERNEL")
                .font(.custom(DesignSystem.displayFont, size: 32))
                .foregroundColor(.white)
            
            Text("Coming soon...")
                .font(.custom(DesignSystem.lightFont, size: 16))
                .foregroundColor(DesignSystem.slate500)
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
