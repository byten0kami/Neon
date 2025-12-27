import SwiftUI

// MARK: - Timeline Rail Past

/// Vertical line for the past section (ABOVE NOW)
/// Uses pastRailGradient for symmetric effects (e.g., Nyan rainbow)
struct TimelineRailPast: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        GeometryReader { geometry in
            if geometry.size.height > 0 {
                ZStack {
                    Rectangle()
                        .fill(themeManager.currentTheme.pastRailGradient)
                        .frame(width: 2)
                }
                .frame(maxHeight: .infinity)
                .position(x: 35, y: geometry.size.height / 2)
            }
        }
    }
}

// MARK: - Timeline Rail Future (Rainbow)

/// Rainbow vertical line for the future section (BELOW NOW)
/// Features a colorful gradient with glow effect
// MARK: - Timeline Rail Future (Rainbow)

/// Rainbow vertical line for the future section (BELOW NOW)
/// Cyan at top (Now), Purple at bottom (Future)
// MARK: - Timeline Rail Future (Rainbow)

/// Rainbow vertical line for the future section (BELOW NOW)
/// Repeating Rainbow Gradient (Cyan -> Purple)
/// Starts with Cyan at the top (Now)
struct TimelineRailFuture: View {
    var contentHeight: CGFloat?
    @State private var glowIntensity: Double = 0.5
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        GeometryReader { geometry in
            if geometry.size.height > 0 {
                let gradient = themeManager.currentTheme.railGradient
                
                // Return the view content
                ZStack {
                    // Outer glow layer
                    Rectangle()
                        .fill(gradient.opacity(0.15 * glowIntensity))
                        .frame(width: 12)
                        .blur(radius: 8)
                    
                    // Middle glow layer
                    Rectangle()
                        .fill(gradient.opacity(0.3 * glowIntensity))
                        .frame(width: 6)
                        .blur(radius: 4)
                    
                    // Core line
                    Rectangle()
                        .fill(gradient)
                        .frame(width: 2)
                }
                .frame(height: geometry.size.height)
                .position(x: 35, y: geometry.size.height / 2)
            }
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 2.0)
                .repeatForever(autoreverses: true)
            ) {
                glowIntensity = 1.0
            }
        }
    }
}

// MARK: - Timeline Rails (Unified)

/// Unified rail system extending mainly from the Now Card
/// Anchored at the center (Dot), extending Up (Past) and Down (Future)
struct TimelineRails: View {
    var body: some View {
        GeometryReader { geometry in
            if geometry.size.height > 0 {
                let center = geometry.size.height / 2
                
                ZStack {
                    // Top Rail (Past) - Goes UP from center
                    // We offset it so its bottom is at the center
                    TimelineRailPast()
                        .frame(height: 3000) // Long enough to cover scroll
                        .position(x: 35, y: center - 1500) // Center of 3000 is 1500. We want Bottom (3000) at Center.
                        // Y = Center - (Height/2) = Center - 1500. Correct.
                    
                    // Bottom Rail (Future) - Goes DOWN from center
                    TimelineRailFuture()
                        .frame(height: 3000) // Long enough to cover scroll
                        .position(x: 35, y: center + 1500) // Center of 3000 is 1500. We want Top (0) at Center.
                        // Y = Center + (Height/2) = Center + 1500. Correct.
                }
            }
        }
    }
}


// MARK: - Now Card

/// Central "NOW" indicator on the timeline
/// Shows current time with sonar pulse effect
struct NowCard: View {
    @State private var currentTime = Date()
    @State private var sonarRings: [UUID] = []
    @ObservedObject private var themeManager = ThemeManager.shared
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let sonarTimer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: currentTime)
    }
    
    private var secondsString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ss"
        return formatter.string(from: currentTime)
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: currentTime).uppercased()
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Dot with sonar on timeline
            // WIDTH FIXED AT 70 to match standard timeline connector width
            // Center is at 35, aligning with rail
            ZStack {
                // Rails behind the dot (New unified rail system)
                TimelineRails()
                    .frame(width: 70, height: 120) // Match card height, width enough for rail
                    .background(Color.clear) // Ensure it doesn't clip
                    .allowsHitTesting(false)
                
                ForEach(sonarRings, id: \.self) { _ in
                    SonarRing()
                }
                
                Circle()
                    .fill(themeManager.currentTheme.mainAccent)
                    .frame(width: 14, height: 14)
                    .shadow(color: themeManager.currentTheme.mainAccent, radius: 8)
            }
            .frame(width: 70) // Ensure explicit width to align with standard connector
            
            // Horizontal branch line
            Rectangle()
                .fill(themeManager.currentTheme.mainAccent.opacity(0.5))
                .frame(width: 25, height: 2)
            
            Spacer()
                .frame(width: 8)
            
            // Time display - using mono font for technical time display
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("[NOW]")
                        .font(.custom(themeManager.currentTheme.bodyFont, size: 16))
                        .tracking(4)
                        .foregroundColor(themeManager.currentTheme.mainAccent)
                    
                    Spacer()
                    
                    // Date uses bodyFont (description theme font)
                    Text(dateString)
                        .font(.custom(themeManager.currentTheme.bodyFont, size: 16))
                        .tracking(2)
                        .foregroundColor(themeManager.currentTheme.mainAccent.opacity(0.8))
                }
                
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    // Time uses timeFont (theme time font)
                    Text(timeString)
                        .font(.custom(themeManager.currentTheme.timeFont, size: 44))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(secondsString)
                        .font(.custom(themeManager.currentTheme.timeFont, size: 24))
                        .fontWeight(.bold)
                        .foregroundColor(DesignSystem.slate500)
                }
            }
            .padding(.trailing) // Add trailing padding since we removed the Spacer
        }
        .frame(height: 120)
        .onAppear {
            emitSonarRing()
        }
        .onReceive(timer) { time in
            currentTime = time
        }
        .onReceive(sonarTimer) { _ in
            emitSonarRing()
        }
    }
    
    private func emitSonarRing() {
        let newRing = UUID()
        sonarRings.append(newRing)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            sonarRings.removeAll { $0 == newRing }
        }
    }
}

// MARK: - Sonar Ring

/// Single outgoing pulse ring for NOW indicator
struct SonarRing: View {
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 0.6
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Circle()
            .stroke(themeManager.currentTheme.mainAccent, lineWidth: 1.5)
            .frame(width: 14, height: 14)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 2.5)) {
                    scale = 5.0
                    opacity = 0.0
                }
            }
    }
}
