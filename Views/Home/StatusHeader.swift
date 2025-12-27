import SwiftUI

/// Status header showing neural stability only
/// Date/time displays on NOW indicator in timeline
struct StatusHeader: View {
    let stability: Int
    let onCalendarTap: () -> Void
    
    private var isLowStability: Bool {
        stability < 50
    }
    
    var body: some View {
        HStack {
            // Neural Stability (main content)
            HStack(spacing: 8) {
                Text("NEURAL STABILITY")
                    .font(.custom(DesignSystem.monoFont, size: 18))
                    .foregroundColor(DesignSystem.purple)
                    .tracking(2)
                
                stabilityBars
                
                Text("\(stability)%")
                    .font(.custom(DesignSystem.displayFont, size: 14))
                    .foregroundColor(isLowStability ? DesignSystem.red : DesignSystem.cyan)
                    .shadow(color: (isLowStability ? DesignSystem.red : DesignSystem.cyan).opacity(0.5), radius: 3)
                
                if isLowStability {
                    Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(DesignSystem.red)
                    .font(.system(size: 10))
                }
            }
            
            Spacer()
            
            // Effect Demo Button (Debug Only)
            #if DEBUG
            Button(action: {
                OverlayEffectsManager.shared.forceTriggerEffect()
            }) {
                Image(systemName: "wand.and.stars")
                    .foregroundColor(DesignSystem.purple)
                    .font(.system(size: 20))
                    .shadow(color: DesignSystem.purple.opacity(0.5), radius: 2)
            }
            .padding(.trailing, 8)
            #endif

            // Calendar Button
            Button(action: onCalendarTap) {
                Image(systemName: "calendar")
                    .foregroundColor(DesignSystem.red)
                    .font(.system(size: 20))
                    .shadow(color: DesignSystem.red.opacity(0.5), radius: 2)
            }
        }
        .font(.custom(DesignSystem.monoFont, size: 10))
        .padding(.horizontal, 16)
        .padding(16)
        .background(DesignSystem.backgroundSecondary.opacity(0.95))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(isLowStability ? DesignSystem.red.opacity(0.5) : DesignSystem.cyan.opacity(0.3)),
            alignment: .bottom
        )
    }
    
    private var stabilityBars: some View {
        HStack(spacing: 2) {
            ForEach(0..<10, id: \.self) { index in
                let isFilled = index < stability / 10
                
                Rectangle()
                    .fill(
                        isFilled
                        ? (isLowStability ? AnyShapeStyle(DesignSystem.red) : AnyShapeStyle(LinearGradient(colors: [DesignSystem.cyan, DesignSystem.purple], startPoint: .top, endPoint: .bottom)))
                        : AnyShapeStyle(DesignSystem.slate800)
                    )
                    .frame(width: 4, height: 12)
                    .transformEffect(CGAffineTransform(a: 1, b: 0, c: -0.2, d: 1, tx: 0, ty: 0))
                    .shadow(
                        color: isFilled ? (isLowStability ? DesignSystem.red : DesignSystem.cyan).opacity(0.5) : .clear,
                        radius: 2
                    )
                    .opacity(isLowStability && isFilled ? 0.8 : 1)
                    .animation(
                        isLowStability ? Animation.easeInOut(duration: 0.5).repeatForever().delay(Double(index) * 0.1) : .default,
                        value: isLowStability
                    )
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        StatusHeader(stability: 72, onCalendarTap: {})
        StatusHeader(stability: 35, onCalendarTap: {})
    }
    .background(DesignSystem.backgroundPrimary)
}
