import SwiftUI

/// Reusable view modifiers for cyberpunk aesthetic
struct HUDCornersModifier: ViewModifier {
    var color: Color = Theme.slate700
    var opacity: Double = 0.5
    
    func body(content: Content) -> some View {
        content.overlay(
            GeometryReader { geometry in
                // Top Left
                HUDCorner()
                    .stroke(color.opacity(opacity), lineWidth: 1)
                    .frame(width: 8, height: 8)
                    .position(x: 4, y: 4)
                
                // Top Right
                HUDCorner()
                    .stroke(color.opacity(opacity), lineWidth: 1)
                    .frame(width: 8, height: 8)
                    .rotationEffect(.degrees(90))
                    .position(x: geometry.size.width - 4, y: 4)
                
                // Bottom Left
                HUDCorner()
                    .stroke(color.opacity(opacity), lineWidth: 1)
                    .frame(width: 8, height: 8)
                    .rotationEffect(.degrees(-90))
                    .position(x: 4, y: geometry.size.height - 4)
                
                // Bottom Right
                HUDCorner()
                    .stroke(color.opacity(opacity), lineWidth: 1)
                    .frame(width: 8, height: 8)
                    .rotationEffect(.degrees(180))
                    .position(x: geometry.size.width - 4, y: geometry.size.height - 4)
            }
        )
    }
}

struct HUDCorner: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return path
    }
}

struct GlowModifier: ViewModifier {
    var color: Color
    var radius: CGFloat = 8
    
    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.5), radius: radius, x: 0, y: 0)
    }
}

struct CyberpunkBorderModifier: ViewModifier {
    var color: Color = Theme.slate700
    var leftAccent: Color? = nil
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Rectangle()
                    .stroke(color, lineWidth: 1)
            )
            .overlay(
                Group {
                    if let accent = leftAccent {
                        Rectangle()
                            .fill(accent)
                            .frame(width: 2)
                    }
                },
                alignment: .leading
            )
    }
}

struct SkewedBarModifier: ViewModifier {
    var filled: Bool
    var filledColor: Color
    var emptyColor: Color = Theme.slate800
    
    func body(content: Content) -> some View {
        content
            .frame(width: 4, height: 12)
            .background(filled ? filledColor : emptyColor)
            .transformEffect(CGAffineTransform(a: 1, b: 0, c: -0.2, d: 1, tx: 0, ty: 0))
    }
}

// MARK: - View Extensions

extension View {
    func hudCorners(color: Color = Theme.slate700, opacity: Double = 0.5) -> some View {
        modifier(HUDCornersModifier(color: color, opacity: opacity))
    }
    
    func glow(color: Color, radius: CGFloat = 8) -> some View {
        modifier(GlowModifier(color: color, radius: radius))
    }
    
    func cyberpunkBorder(color: Color = Theme.slate700, leftAccent: Color? = nil) -> some View {
        modifier(CyberpunkBorderModifier(color: color, leftAccent: leftAccent))
    }
}
