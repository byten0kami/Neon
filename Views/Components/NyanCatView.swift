
import SwiftUI

struct NyanCatView: View {
    @State private var offset: CGFloat = -200
    @State private var frameCounter = 0
    @State private var isExploding = false
    
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    // Screen width for animation bounds
    private let screenWidth = UIScreen.main.bounds.width
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if !isExploding {
                    // Flying Cat
                    ZStack {
                        // Rainbow Tail
                        RainbowTail(frame: frameCounter)
                            .offset(x: -40, y: 0)
                        
                        // The Cat
                        CatBody()
                    }
                    .scaleEffect(0.6)
                    .position(x: offset, y: geometry.size.height / 3 + sin(Double(offset) / 50) * 20)
                    .onTapGesture {
                        triggerExplosion()
                    }
                } else {
                    // Explosion Effect
                    ExplosionView()
                        .position(x: offset, y: geometry.size.height / 3 + sin(Double(offset) / 50) * 20)
                }
            }
            .onReceive(timer) { _ in
                guard !isExploding else { return }
                
                frameCounter += 1
                
                // Move the cat
                withAnimation(.linear(duration: 0.1)) {
                    offset += 10
                }
                
                // Reset when off screen or dismiss if done
                if offset > screenWidth + 200 {
                    OverlayEffectsManager.shared.dismiss()
                    offset = -200
                }
            }
        }
        .frame(height: 300) // Increase frame for interaction
        .allowsHitTesting(true) // Enable interaction
    }
    
    private func triggerExplosion() {
        isExploding = true
        QuestManager.shared.completeQuest(id: .nyanCat)
        
        // Wait for explosion animation then dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            OverlayEffectsManager.shared.dismiss()
        }
    }
}

// MARK: - Explosion View

struct ExplosionView: View {
    @State private var particles: [Particle] = []
    
    struct Particle: Hashable, Identifiable {
        let id = UUID()
        var angle: Double
        var distance: CGFloat = 0
        var color: Color
        var scale: CGFloat = 1.0
    }
    
    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: 8, height: 8)
                    .scaleEffect(particle.scale)
                    .offset(
                        x: cos(particle.angle) * particle.distance,
                        y: sin(particle.angle) * particle.distance
                    )
            }
        }
        .onAppear {
            createParticles()
            animateParticles()
        }
    }
    
    private func createParticles() {
        let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .white]
        for _ in 0..<50 {
            let angle = Double.random(in: 0..<360) * .pi / 180
            let color = colors.randomElement()!
            particles.append(Particle(angle: angle, color: color))
        }
    }
    
    private func animateParticles() {
        withAnimation(.easeOut(duration: 1.0)) {
            for i in 0..<particles.count {
                particles[i].distance = CGFloat.random(in: 50...150)
                particles[i].scale = 0.0
            }
        }
    }
}

// MARK: - Components

struct CatBody: View {
    var body: some View {
        ZStack {
            // Feet
            HStack(spacing: 25) {
                Color.black.frame(width: 8, height: 8)
                Color.black.frame(width: 8, height: 8)
                Color.black.frame(width: 8, height: 8)
                Color.black.frame(width: 8, height: 8)
            }
            .offset(y: 18)
            
            // Pop-Tart Body
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(red: 1.0, green: 0.6, blue: 0.8)) // Dark pink
                .frame(width: 44, height: 32)
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(Color.black, lineWidth: 2)
                )
            
            // Pop-Tart Center
            RoundedRectangle(cornerRadius: 1)
                .fill(Color(red: 1.0, green: 0.2, blue: 0.6)) // Hot pink
                .frame(width: 36, height: 24)
            
            // Sprinkles (dots)
            Group {
                Circle().fill(Color.red).frame(width: 3, height: 3).offset(x: -10, y: -5)
                Circle().fill(Color.orange).frame(width: 3, height: 3).offset(x: 5, y: -8)
                Circle().fill(Color.red).frame(width: 3, height: 3).offset(x: 10, y: 4)
                Circle().fill(Color.orange).frame(width: 3, height: 3).offset(x: -8, y: 6)
                Circle().fill(Color.orange).frame(width: 3, height: 3).offset(x: 0, y: 0)
            }
            
            // Head
            ZStack {
                // Main gray head
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray)
                    .frame(width: 28, height: 20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.black, lineWidth: 2)
                    )
                
                // Ears
                HStack(spacing: 14) {
                    Triangle()
                        .fill(Color.gray)
                        .frame(width: 8, height: 8)
                        .overlay(Triangle().stroke(Color.black, lineWidth: 2))
                    Triangle()
                        .fill(Color.gray)
                        .frame(width: 8, height: 8)
                        .overlay(Triangle().stroke(Color.black, lineWidth: 2))
                }
                .offset(y: -12)
                
                // Eyes
                HStack(spacing: 8) {
                    Circle().fill(Color.black).frame(width: 4, height: 4)
                    Circle().fill(Color.black).frame(width: 4, height: 4)
                }
                .offset(y: -2)
                
                // Mouth
                Text("w")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.black)
                    .offset(y: 4)
                
                // Cheeks
                HStack(spacing: 16) {
                    Circle().fill(Color(red: 1.0, green: 0.6, blue: 0.6)).frame(width: 4, height: 4)
                    Circle().fill(Color(red: 1.0, green: 0.6, blue: 0.6)).frame(width: 4, height: 4)
                }
                .offset(y: 2)
            }
            .offset(x: 25, y: -2)
            
            // Tail
            Path { path in
                path.move(to: CGPoint(x: 0, y: 0))
                path.addQuadCurve(to: CGPoint(x: 10, y: 0), control: CGPoint(x: 5, y: -5))
            }
            .stroke(Color.gray, style: StrokeStyle(lineWidth: 4, lineCap: .round))
            .frame(width: 10, height: 10)
            .offset(x: -25, y: 0)
        }
    }
}

struct RainbowTail: View {
    let frame: Int
    
    let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<6) { i in // 6 segments
                VStack(spacing: 0) {
                    ForEach(0..<colors.count, id: \.self) { colorIndex in
                        colors[colorIndex]
                            .frame(width: 15, height: 5)
                            // Wave effect based on frame and position
                            .offset(y: calculateOffset(segment: i, frame: frame))
                    }
                }
            }
        }
    }
    
    func calculateOffset(segment: Int, frame: Int) -> CGFloat {
        // Simple wave pattern: alternating up and down
        let wave = ((segment + frame) % 2 == 0) ? -3.0 : 3.0
        return CGFloat(wave)
    }
}

// Helper for ears
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
