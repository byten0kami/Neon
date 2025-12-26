import SwiftUI

/// Main content view with tab navigation
struct ContentView: View {
    @State private var selectedTab: TabItem = .home
    @State private var showChatPanel = false
    
    var body: some View {
        ZStack {
            CyberpunkBackground(isLowStability: false)
                .ignoresSafeArea()
            
            Group {
                switch selectedTab {
                case .home:
                    HomeView()
                case .protocols:
                    ProtocolsView()
                case .history:
                    HistoryView()
                case .settings:
                    SettingsView()
                }
            }
            // Disable interaction when chat is open
            .allowsHitTesting(!showChatPanel)
            
            // Modal overlay to dismiss chat
            if showChatPanel {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showChatPanel = false
                        }
                    }
                
                // Chat panel from bottom
                VStack {
                    Spacer()
                    ExpandableChatPanel(isPresented: $showChatPanel)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            
            VStack {
                Spacer()
                CyberpunkTabBar(
                    activeTab: $selectedTab,
                    showChatPanel: $showChatPanel
                )
            }
            .ignoresSafeArea(.container, edges: .bottom)
        }
        .preferredColorScheme(.dark)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showChatPanel)
    }
}

#Preview {
    ContentView()
}

