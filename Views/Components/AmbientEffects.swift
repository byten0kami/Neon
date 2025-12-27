
import SwiftUI

// MARK: - Toxic Glow (Stalker) -> Acid Burn
struct ToxicGlowView: View {
    var body: some View {
        GeometryReader { geometry in
            AcidLayer(width: geometry.size.width, height: geometry.size.height)
        }
        .ignoresSafeArea(.all)
        .allowsHitTesting(false)
    }
}


struct AcidLayer: View {
    let width: CGFloat
    let height: CGFloat
    
    // Pre-calculate all bubble positions at init time
    private let bubbles: [BubbleData]
    
    init(width: CGFloat, height: CGFloat) {
        self.width = width
        self.height = height
        
        // Generate bubble data with edge positions
        var data: [BubbleData] = []
        let edgeDepth: CGFloat = 35
        
        for i in 0..<80 {
            let edge = Int.random(in: 0...3)
            var x: CGFloat = 0
            var y: CGFloat = 0
            
            switch edge {
            case 0: // Top
                x = CGFloat.random(in: 0...width)
                y = CGFloat.random(in: 0...edgeDepth)
            case 1: // Bottom
                x = CGFloat.random(in: 0...width)
                y = CGFloat.random(in: max(0, height - edgeDepth)...height)
            case 2: // Left
                x = CGFloat.random(in: 0...edgeDepth)
                y = CGFloat.random(in: 0...height)
            case 3: // Right
                x = CGFloat.random(in: max(0, width - edgeDepth)...width)
                y = CGFloat.random(in: 0...height)
            default: break
            }
            
            data.append(BubbleData(
                id: i,
                x: x,
                y: y,
                size: CGFloat.random(in: 3...14),
                color: Bool.random() ? Color.green : Color(hex: "CEFF00"),
                startDelay: Double.random(in: 0...0.9),
                lifespan: Double.random(in: 0.12...0.35)
            ))
        }
        self.bubbles = data
    }
    
    var body: some View {
        ZStack {
            ForEach(bubbles, id: \.id) { bubble in
                AcidBubble(data: bubble)
            }
        }
    }
}

struct BubbleData {
    let id: Int
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let color: Color
    let startDelay: Double
    let lifespan: Double
}

struct AcidBubble: View {
    let data: BubbleData
    
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.1
    
    var body: some View {
        Circle()
            .fill(data.color)
            .frame(width: data.size, height: data.size)
            .position(x: data.x, y: data.y)  // Position is fixed from data
            .opacity(opacity)
            .scaleEffect(scale)
            .shadow(color: data.color.opacity(0.5), radius: 2)
            .onAppear {
                animateBubble()
            }
    }
    
    func animateBubble() {
        // Phase 1: Pop into existence
        withAnimation(.easeOut(duration: data.lifespan * 0.35).delay(data.startDelay)) {
            opacity = Double.random(in: 0.5...0.9)
            scale = CGFloat.random(in: 0.7...1.0)
        }
        
        // Phase 2: Dissolve/pop
        withAnimation(.easeIn(duration: data.lifespan * 0.65).delay(data.startDelay + data.lifespan * 0.35)) {
            opacity = 0
            scale = CGFloat.random(in: 1.1...1.4)
        }
    }
}


struct RadiationInboundLayer: View {
    let width: CGFloat
    let height: CGFloat
    
    var body: some View {
        ZStack {
            ForEach(0..<20, id: \.self) { _ in
                RadiationHazardIcon(containerW: width, containerH: height)
            }
        }
    }
}

struct RadiationHazardIcon: View {
    let containerW: CGFloat
    let containerH: CGFloat
    
    @State private var x: CGFloat = 0
    @State private var y: CGFloat = 0
    @State private var opacity: Double = 0
    @State private var rotation: Double = 0
    
    let size = CGFloat.random(in: 20...40)
    
    var body: some View {
        Image(systemName: "exclamationmark.triangle.fill")
            .font(.system(size: size))
            .foregroundColor(.green)
            .position(x: x, y: y)
            .rotationEffect(.degrees(rotation))
            .opacity(opacity)
            .shadow(color: .green.opacity(0.8), radius: 5)
            .onAppear {
                setupAnimation()
            }
    }
    
    func setupAnimation() {
        // Random start side
        let side = Int.random(in: 0...3)
        var startX: CGFloat = 0
        var startY: CGFloat = 0
        var endX: CGFloat = 0
        var endY: CGFloat = 0
        
        // Randomize trajectory to not be straight to center
        let randomOffset = CGFloat.random(in: -100...100)
        
        switch side {
        case 0: // Top
            startX = CGFloat.random(in: 0...containerW)
            startY = -60
            endX = startX + randomOffset
            endY = containerH * 0.4
        case 1: // Right
            startX = containerW + 60
            startY = CGFloat.random(in: 0...containerH)
            endX = containerW * 0.6
            endY = startY + randomOffset
        case 2: // Bottom
            startX = CGFloat.random(in: 0...containerW)
            startY = containerH + 60
            endX = startX + randomOffset
            endY = containerH * 0.6
        case 3: // Left
            startX = -60
            startY = CGFloat.random(in: 0...containerH)
            endX = containerW * 0.4
            endY = startY + randomOffset
        default: break
        }
        
        x = startX
        y = startY
        rotation = Double.random(in: -30...30)
        
        // NOT all at once - random delay
        let delay = Double.random(in: 0...0.5)
        
        // Fly in
        opacity = 1.0 // Visible initially (off screen)
        
        withAnimation(.easeOut(duration: 0.8).delay(delay)) {
            x = endX
            y = endY
            rotation += Double.random(in: -90...90)
        }
        
        // Fade out halfway (0.4s into 0.8s move)
        withAnimation(.linear(duration: 0.4).delay(delay + 0.4)) {
            opacity = 0
        }
    }
}

// MARK: - Matrix Rain (Terminal)
struct MatrixRainView: View {
    @State private var columns: [MatrixColumn] = []
    let timer = Timer.publish(every: 0.02, on: .main, in: .common).autoconnect()
    
    struct MatrixColumn: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var speed: CGFloat
        var chars: String
        var opacity: Double
        var size: CGFloat
    }
    
    let matrixChars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ$#%&@"
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.opacity(0.8).ignoresSafeArea()
                
                ForEach(columns) { column in
                    Text(column.chars)
                        .font(.custom("Silkscreen-Regular", size: column.size))
                        .foregroundColor(Color(red: 0, green: 1.0, blue: 0.4))
                        .position(x: column.x, y: column.y)
                        .opacity(column.opacity)
                        .shadow(color: .green.opacity(0.8), radius: 2)
                }
            }
            .onAppear {
                let colWidth: CGFloat = 16
                let count = Int(geometry.size.width / colWidth) + 5
                
                for _ in 0..<count {
                    createColumn(in: geometry.size)
                }
                for _ in 0..<count/2 {
                    createColumn(in: geometry.size)
                }
            }
            .onReceive(timer) { _ in
                updateColumns(in: geometry.size)
            }
        }
        .allowsHitTesting(false)
    }
    
    func createColumn(in size: CGSize) {
        let length = Int.random(in: 10...30)
        let chars = String((0..<length).map { _ in matrixChars.randomElement()! })
            .map { String($0) }
            .joined(separator: "\n")
        
        let fontSize = CGFloat.random(in: 10...18)
        
        let column = MatrixColumn(
            x: CGFloat.random(in: 0...size.width),
            y: -CGFloat.random(in: 100...size.height),
            speed: CGFloat.random(in: 20...50),
            chars: chars,
            opacity: Double.random(in: 0.3...0.9),
            size: fontSize
        )
        columns.append(column)
    }
    
    func updateColumns(in size: CGSize) {
        for i in 0..<columns.count {
            columns[i].y += columns[i].speed
            if columns[i].y > size.height + 600 {
                columns[i].y = -CGFloat.random(in: 100...400)
                columns[i].x = CGFloat.random(in: 0...size.width)
                columns[i].speed = CGFloat.random(in: 20...50)
            }
        }
    }
}

// MARK: - Security Scan (Corporate)
struct SecurityScanView: View {
    @State private var scanY: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Rectangle()
                    .fill(Color.red)
                    .frame(height: 2)
                    .shadow(color: .red, radius: 4)
                    .shadow(color: .red, radius: 8)
                    .offset(y: scanY)
            }
            .onAppear {
                scanY = -50
                withAnimation(.linear(duration: 2.0)) {
                    scanY = geometry.size.height + 50
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Static Interference (Mercenary)
// 50% Opacity Full Screen Animated Static (TV Snow)
struct StaticInterferenceView: View {
    var body: some View {
        GeometryReader { geometry in
            SwiftUI.TimelineView(.animation) { context in
                Canvas { context, size in
                    for _ in 0..<1500 {
                        let rect = CGRect(
                            x: CGFloat.random(in: 0...size.width),
                            y: CGFloat.random(in: 0...size.height),
                            width: CGFloat.random(in: 1...3),
                            height: CGFloat.random(in: 1...3)
                        )
                        let gray = Double.random(in: 0...1)
                        context.fill(Path(rect), with: .color(Color(white: gray, opacity: 0.5)))
                    }
                }
            }
            .opacity(0.5)
            .ignoresSafeArea()
        }
        .allowsHitTesting(false)
    }
}
