import SwiftUI

struct WeekStartPicker: View {
    @Binding var weekStartOffset: Int // 0-6
    @Binding var isPresented: Bool
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    private let daySymbols = ["M", "T", "W", "T", "F", "S", "S"]
    
    // Geometry
    private let buttonSize: CGFloat = 38
    
    private var accentColor: Color {
        themeManager.currentTheme.mainAccent
    }
    
    var body: some View {
        ZStack {
            // Unlit background overlay
            Color.black.opacity(0.8)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            // Picker Card
            VStack(spacing: 0) {
                // Header
                Text("ALIGN START DAY")
                    .font(.custom(DesignSystem.monoFont, size: 14))
                    .foregroundColor(DesignSystem.cyan)
                    .tracking(2)
                    .padding(.top, 24)
                    .padding(.bottom, 24)
                    .shadow(color: DesignSystem.cyan.opacity(0.8), radius: 8)
                
                // Day Selection Grid
                HStack(spacing: 8) {
                    ForEach(0..<7, id: \.self) { index in
                        DayButton(
                            symbol: daySymbols[index],
                            isSelected: weekStartOffset == index,
                            accentColor: accentColor,
                            action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    weekStartOffset = index
                                }
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                            }
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
                
                // Confirm Button
                Button(action: { isPresented = false }) {
                    Text("CONFIRM")
                        .font(.custom(DesignSystem.monoFont, size: 16))
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(accentColor)
                        .cornerRadius(CardStyle.cornerRadius)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .background(Color.black.opacity(0.95))
            .cornerRadius(CardStyle.cornerRadius)
            // Custom Card Border (Thick Left, Thin Overlay)
            .overlay(
                ZStack(alignment: .leading) {
                    // Thin bezel all around
                    RoundedRectangle(cornerRadius: CardStyle.cornerRadius)
                        .stroke(accentColor.opacity(0.5), lineWidth: 1)
                    
                    // Thick left border
                    Rectangle()
                        .fill(accentColor)
                        .frame(width: CardStyle.borderWidth)
                        .cornerRadius(CardStyle.cornerRadius)
                }
            )
            .shadow(color: accentColor.opacity(0.15), radius: 20)
            .padding(.horizontal, 20)
        }
    }
}

// Subview for Day Button
struct DayButton: View {
    let symbol: String
    let isSelected: Bool
    let accentColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(symbol)
                .font(.custom(DesignSystem.monoFont, size: 18))
                .fontWeight(.bold)
                .foregroundColor(isSelected ? .black : .white)
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background(
                    isSelected ? accentColor : Color.white.opacity(0.05)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: CardStyle.cornerRadius)
                        .stroke(
                            isSelected ? accentColor : DesignSystem.slate600,
                            lineWidth: 1
                        )
                )
                .cornerRadius(CardStyle.cornerRadius)
        }
    }
}
