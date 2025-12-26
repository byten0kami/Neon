import SwiftUI

/// Decorative HUD corners for cards and containers
struct HUDCorners: View {
    var color: Color = DesignSystem.slate700
    var size: CGFloat = 8
    
    var body: some View {
        GeometryReader { geometry in
            // Top Right
            cornerPath
                .stroke(color, lineWidth: 1)
                .frame(width: size, height: size)
                .position(x: geometry.size.width - size/2, y: size/2)
            
            // Bottom Right  
            cornerPath
                .stroke(color, lineWidth: 1)
                .frame(width: size, height: size)
                .rotationEffect(.degrees(90))
                .position(x: geometry.size.width - size/2, y: geometry.size.height - size/2)
        }
    }
    
    private var cornerPath: some Shape {
        CornerShape()
    }
}

struct CornerShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        return path
    }
}

/// Full frame HUD corners (all 4 corners)
struct FullHUDCorners: View {
    var color: Color = DesignSystem.cyan
    var size: CGFloat = 12
    var opacity: Double = 0.5
    
    var body: some View {
        GeometryReader { geometry in
            Group {
                // Top Left
                LCorner()
                    .stroke(color.opacity(opacity), lineWidth: 1)
                    .frame(width: size, height: size)
                    .position(x: size/2, y: size/2)
                
                // Top Right
                LCorner()
                    .stroke(color.opacity(opacity), lineWidth: 1)
                    .frame(width: size, height: size)
                    .rotationEffect(.degrees(90))
                    .position(x: geometry.size.width - size/2, y: size/2)
                
                // Bottom Left
                LCorner()
                    .stroke(color.opacity(opacity), lineWidth: 1)
                    .frame(width: size, height: size)
                    .rotationEffect(.degrees(-90))
                    .position(x: size/2, y: geometry.size.height - size/2)
                
                // Bottom Right
                LCorner()
                    .stroke(color.opacity(opacity), lineWidth: 1)
                    .frame(width: size, height: size)
                    .rotationEffect(.degrees(180))
                    .position(x: geometry.size.width - size/2, y: geometry.size.height - size/2)
            }
        }
    }
}

struct LCorner: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return path
    }
}

#Preview {
    ZStack {
        DesignSystem.backgroundPrimary.ignoresSafeArea()
        
        RoundedRectangle(cornerRadius: 0)
            .fill(DesignSystem.backgroundCard)
            .frame(width: 200, height: 100)
            .overlay(FullHUDCorners(color: DesignSystem.cyan))
    }
}
