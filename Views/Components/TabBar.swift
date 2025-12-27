import SwiftUI

/// Tab items for the main navigation (4 tabs, no chat)
enum TabItem: String, CaseIterable {
    case home
    case protocols
    case history
    case settings
    #if DEBUG
    case smpl
    #endif
    
    var title: String {
        switch self {
        case .home: return "COMMAND CENTER"
        case .protocols: return "BIO-KERNEL"
        case .history: return "SYSTEM LOGS"
        case .settings: return "CONFIGURATION"

        #if DEBUG
        case .smpl: return "FONT SAMPLER"
        #endif
        }
    }
    
    var label: String {
        switch self {
        case .home: return "CMD"
        case .protocols: return "PROTO"
        case .history: return "LOGS"
        case .settings: return "CFG"

        #if DEBUG
        case .smpl: return "SMPL"
        #endif
        }
    }
    
    var icon: String {
        switch self {
        case .home: return "terminal.fill"
        case .protocols: return "cylinder.split.1x2.fill"
        case .history: return "clock.arrow.circlepath"
        case .settings: return "gearshape.fill"

        #if DEBUG
        case .smpl: return "textformat"
        #endif
        }
    }
    
    var color: Color {
        switch self {
        case .home: return DesignSystem.cyan
        case .protocols: return DesignSystem.purple
        case .history: return DesignSystem.amber
        case .settings: return DesignSystem.slate400

        #if DEBUG
        case .smpl: return DesignSystem.lime
        #endif
        }
    }
}

/// Custom cyberpunk-styled tab bar
struct CyberpunkTabBar: View {
    @Binding var activeTab: TabItem
    @Binding var showChatPanel: Bool
    @Namespace private var animation
    
    @State private var cmdBlinkOpacity: Double = 1.0
    @State private var isBlinking = false
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(TabItem.allCases, id: \.self) { tab in
                if tab == .home {
                    cmdButton
                } else {
                    tabButton(for: tab)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
        .padding(.bottom, 40)
        .background(
            DesignSystem.backgroundSecondary
        )
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(DesignSystem.slate800),
            alignment: .top
        )
        .onChange(of: activeTab) { _, newTab in
            updateBlinkState(for: newTab)
        }
        .onChange(of: showChatPanel) { _, isShowing in
            if !isShowing && activeTab == .home {
                startBlinking()
            } else {
                stopBlinking()
            }
        }
        .onAppear {
            if activeTab == .home && !showChatPanel {
                startBlinking()
            }
        }
    }
    
    // MARK: - CMD Button (Special Behavior)
    
    private var cmdButton: some View {
        let isActive = activeTab == .home
        
        return Button {
            handleCmdTap()
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    if isActive {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [TabItem.home.color.opacity(0.1), .clear],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                            .matchedGeometryEffect(id: "activeTab", in: animation)
                    }
                    
                    Image(systemName: TabItem.home.icon)
                        .font(.system(size: 20, weight: isActive ? .bold : .regular))
                        .foregroundColor(isActive ? TabItem.home.color : DesignSystem.slate600)
                        .offset(y: isActive ? -2 : 0)
                        .opacity(isActive && isBlinking ? cmdBlinkOpacity : 1.0)
                }
                .frame(height: 32)
                
                Text(TabItem.home.label)
                    .font(.custom(DesignSystem.headlineFont, size: 9))
                    .foregroundColor(isActive ? TabItem.home.color : DesignSystem.slate700)
                    .shadow(color: isActive ? TabItem.home.color.opacity(0.5) : .clear, radius: 2)
                    .opacity(isActive && isBlinking ? cmdBlinkOpacity : 1.0)
                
                if isActive {
                    Rectangle()
                        .fill(TabItem.home.color)
                        .frame(width: 32, height: 2)
                        .glow(color: TabItem.home.color, radius: 4)
                        .matchedGeometryEffect(id: "indicator", in: animation)
                } else {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: 32, height: 2)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
    
    private func handleCmdTap() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if activeTab != .home {
                // On other tab → go to CMD
                activeTab = .home
                if !showChatPanel {
                    startBlinking()
                }
            } else {
                // On CMD tab → toggle chat
                showChatPanel.toggle()
            }
        }
    }
    
    private func updateBlinkState(for tab: TabItem) {
        if tab == .home && !showChatPanel {
            startBlinking()
        } else {
            stopBlinking()
        }
    }
    
    private func startBlinking() {
        guard !isBlinking else { return }
        isBlinking = true
        withAnimation(
            .easeInOut(duration: 0.8)
            .repeatForever(autoreverses: true)
        ) {
            cmdBlinkOpacity = 0.4
        }
    }
    
    private func stopBlinking() {
        isBlinking = false
        withAnimation(.easeOut(duration: 0.2)) {
            cmdBlinkOpacity = 1.0
        }
    }
    
    @ViewBuilder
    private func tabButton(for tab: TabItem) -> some View {
        let isActive = activeTab == tab
        
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                activeTab = tab
            }
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    if isActive {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [tab.color.opacity(0.1), .clear],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                            .matchedGeometryEffect(id: "activeTab", in: animation)
                    }
                    
                    Image(systemName: tab.icon)
                        .font(.system(size: 20, weight: isActive ? .bold : .regular))
                        .foregroundColor(isActive ? tab.color : DesignSystem.slate600)
                        .offset(y: isActive ? -2 : 0)
                }
                .frame(height: 32)
                
                Text(tab.label)
                    .font(.custom(DesignSystem.headlineFont, size: 9))
                    .foregroundColor(isActive ? tab.color : DesignSystem.slate700)
                    .shadow(color: isActive ? tab.color.opacity(0.5) : .clear, radius: 2)
                
                if isActive {
                    Rectangle()
                        .fill(tab.color)
                        .frame(width: 32, height: 2)
                        .glow(color: tab.color, radius: 4)
                        .matchedGeometryEffect(id: "indicator", in: animation)
                } else {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: 32, height: 2)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .allowsHitTesting(!showChatPanel)
        .opacity(showChatPanel ? 0.3 : 1.0)
    }
}

#Preview {
    ZStack {
        DesignSystem.backgroundPrimary.ignoresSafeArea()
        VStack {
            Spacer()
            CyberpunkTabBar(activeTab: .constant(.home), showChatPanel: .constant(false))
        }
    }
}

