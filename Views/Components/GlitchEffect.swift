import SwiftUI

/// Full-screen glitch effect for cyber-psychosis (low stability)
struct GlitchEffect: View {
    @State private var offset1: CGFloat = 0
    @State private var offset2: CGFloat = 0
    @State private var opacity: Double = 1
    @State private var showWarning: Bool = false
    
    let intensity: Double
    
    init(intensity: Double = 0.5) {
        self.intensity = min(max(intensity, 0), 1)
    }
    
    var body: some View {
        ZStack {
            // RGB Channel separation
            rgbSeparation
            
            // Random noise bars
            noiseBars
            
            // Warning overlay
            if showWarning {
                warningOverlay
            }
        }
        .onAppear {
            startGlitchAnimation()
        }
    }
    
    private var rgbSeparation: some View {
        GeometryReader { geometry in
            ZStack {
                // Red channel offset
                Rectangle()
                    .fill(DesignSystem.red.opacity(0.1 * intensity))
                    .offset(x: offset1)
                    .blendMode(.screen)
                
                // Cyan channel offset
                Rectangle()
                    .fill(DesignSystem.cyan.opacity(0.1 * intensity))
                    .offset(x: -offset2)
                    .blendMode(.screen)
            }
        }
        .ignoresSafeArea()
    }
    
    private var noiseBars: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                ForEach(0..<10, id: \.self) { index in
                    if Bool.random() && intensity > 0.3 {
                        Rectangle()
                            .fill(DesignSystem.slate700.opacity(Double.random(in: 0.3...0.8)))
                            .frame(height: CGFloat.random(in: 2...8))
                            .offset(x: CGFloat.random(in: -20...20))
                    } else {
                        Spacer()
                            .frame(height: geometry.size.height / 10)
                    }
                }
            }
        }
        .ignoresSafeArea()
        .opacity(opacity)
    }
    
    private var warningOverlay: some View {
        VStack {
            Spacer()
            
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(DesignSystem.red)
                
                Text("SYSTEM REBOOT REQUIRED")
                    .font(.custom(DesignSystem.displayFont, size: 14))
                    .foregroundColor(DesignSystem.red)
                    .shadow(color: DesignSystem.red.opacity(0.8), radius: 4)
            }
            .padding()
            .background(DesignSystem.backgroundSecondary.opacity(0.9))
            .overlay(
                Rectangle()
                    .stroke(DesignSystem.red, lineWidth: 2)
            )
            
            Spacer()
        }
        .transition(.opacity)
    }
    
    private func startGlitchAnimation() {
        // Random glitch offsets
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if Double.random(in: 0...1) < intensity * 0.3 {
                withAnimation(.easeInOut(duration: 0.05)) {
                    offset1 = CGFloat.random(in: -10...10) * intensity
                    offset2 = CGFloat.random(in: -10...10) * intensity
                }
            } else {
                withAnimation(.easeInOut(duration: 0.1)) {
                    offset1 = 0
                    offset2 = 0
                }
            }
        }
        
        // Random opacity flicker
        Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
            if Double.random(in: 0...1) < intensity * 0.2 {
                withAnimation(.easeInOut(duration: 0.1)) {
                    opacity = Double.random(in: 0.5...1.0)
                }
            }
        }
        
        // Show warning if high intensity
        if intensity > 0.6 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    showWarning = true
                }
            }
        }
    }
}

#Preview {
    ZStack {
        DesignSystem.backgroundPrimary.ignoresSafeArea()
        
        VStack {
            Text("NEURAL STABILITY: 35%")
                .font(.custom(DesignSystem.displayFont, size: 18))
                .foregroundColor(DesignSystem.red)
        }
        
        GlitchEffect(intensity: 0.7)
    }
}
