import SwiftUI

/// Status header showing neural stability only
/// Date/time displays on NOW indicator in timeline
struct StatusHeader: View {
    let stability: Int
    
    private var isLowStability: Bool {
        stability < 50
    }
    
    var body: some View {
        HStack {
            // Neural Stability (main content)
            HStack(spacing: 8) {
                Text("NEURAL STABILITY")
                    .font(.custom(Theme.monoFont, size: 18))
                    .foregroundColor(Theme.purple)
                    .tracking(2)
                
                stabilityBars
                
                Text("\(stability)%")
                    .font(.custom(Theme.displayFont, size: 14))
                    .foregroundColor(isLowStability ? Theme.red : Theme.cyan)
                    .shadow(color: (isLowStability ? Theme.red : Theme.cyan).opacity(0.5), radius: 3)
                
                if isLowStability {
                    Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(Theme.red)
                    .font(.system(size: 10))
                }
            }
            
            Spacer()
            
            // Status Icons
            HStack(spacing: 12) {
                Image(systemName: "lock.fill")
                    .foregroundColor(Theme.green)
                    .shadow(color: Theme.green.opacity(0.5), radius: 2)
                
                Image(systemName: "wifi")
                    .foregroundColor(Theme.cyan)
                    .shadow(color: Theme.cyan.opacity(0.5), radius: 2)
            }
        }
        .font(.custom(Theme.monoFont, size: 10))
        .padding(.horizontal, 16)
        .padding(16)
        .background(Theme.backgroundSecondary.opacity(0.95))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(isLowStability ? Theme.red.opacity(0.5) : Theme.cyan.opacity(0.3)),
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
                        ? (isLowStability ? AnyShapeStyle(Theme.red) : AnyShapeStyle(LinearGradient(colors: [Theme.cyan, Theme.purple], startPoint: .top, endPoint: .bottom)))
                        : AnyShapeStyle(Theme.slate800)
                    )
                    .frame(width: 4, height: 12)
                    .transformEffect(CGAffineTransform(a: 1, b: 0, c: -0.2, d: 1, tx: 0, ty: 0))
                    .shadow(
                        color: isFilled ? (isLowStability ? Theme.red : Theme.cyan).opacity(0.5) : .clear,
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
        StatusHeader(stability: 72)
        StatusHeader(stability: 35)
    }
    .background(Theme.backgroundPrimary)
}
