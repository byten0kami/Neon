import SwiftUI

/// Cyberpunk grid background with optional effects
struct CyberpunkBackground: View {
    var showGrid: Bool = false
    var showVignette: Bool = true
    var isLowStability: Bool = false
    var showScanlines: Bool = true  // Scanlines on content background
    
    var body: some View {
        ZStack {
            DesignSystem.backgroundSecondary
            
            if showGrid {
                GridPattern()
                    .opacity(0.05)
            }
            
            // Scanline effect on background only (not bars)
            if showScanlines {
                BackgroundScanlineEffect()
            }
            
            if isLowStability {
                lowStabilityOverlay
            }
            
            if showVignette {
                vignetteOverlay
            }
        }
        .ignoresSafeArea()
    }
    
    private var lowStabilityOverlay: some View {
        DesignSystem.red.opacity(0.2)
            .ignoresSafeArea()
            .opacity(0.3)
            .animation(
                Animation.easeInOut(duration: 2).repeatForever(autoreverses: true),
                value: isLowStability
            )
    }
    
    private var vignetteOverlay: some View {
        RadialGradient(
            colors: [.clear, DesignSystem.backgroundSecondary],
            center: .center,
            startRadius: 100,
            endRadius: 400
        )
        .ignoresSafeArea()
    }
}

/// Scanline effect for background - subtle CRT lines
struct BackgroundScanlineEffect: View {
    var body: some View {
        Canvas { context, size in
            let lineSpacing: CGFloat = 3
            var y: CGFloat = 0
            
            while y < size.height {
                let rect = CGRect(x: 0, y: y + (lineSpacing / 2), width: size.width, height: lineSpacing / 2)
                context.fill(Path(rect), with: .color(DesignSystem.cyan.opacity(0.08)))
                y += lineSpacing
            }
        }
        .allowsHitTesting(false)
    }
}

/// Grid pattern for cyberpunk aesthetic
struct GridPattern: View {
    let spacing: CGFloat = 40
    let lineColor = DesignSystem.cyan
    
    var body: some View {
        Canvas { context, size in
            // Vertical lines
            var x: CGFloat = 0
            while x < size.width {
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(path, with: .color(lineColor), lineWidth: 1)
                x += spacing
            }
            
            // Horizontal lines
            var y: CGFloat = 0
            while y < size.height {
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: .color(lineColor), lineWidth: 1)
                y += spacing
            }
        }
    }
}

#Preview {
    CyberpunkBackground(isLowStability: false)
}
