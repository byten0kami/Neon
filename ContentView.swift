import SwiftUI

/// Main content view with tab navigation
struct ContentView: View {
    @ObservedObject private var overlayManager = OverlayEffectsManager.shared
    @State private var selectedTab: TabItem = .home
    @State private var showChatPanel = false
    @State private var showCalendar = false
    @State private var chatContextItem: TimelineItem? // Task context for AI chat
    
    // Calendar State
    @State private var currentMonth: Date = Date()
    @State private var selectedDate: Date = Date()
    
    // MARK: - Helper Functions
    
    private func changeMonth(by value: Int) {
        if let newMonth = Calendar.current.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = newMonth
        }
    }
    
    var body: some View {
        ZStack {
            // 1. Background Layer
            CyberpunkBackground(isLowStability: false)
                .ignoresSafeArea()
            
            // 2. Main Content Layer
            Group {
                switch selectedTab {
                case .home:
                    HomeView(showingCalendar: $showCalendar, chatContextItem: $chatContextItem)
                case .protocols:
                    ProtocolsView()
                case .history:
                    HistoryView()
                case .settings:
                    SettingsView()
                case .smpl:
                    FontSamplerView()
                }
            }
            .padding(.bottom, 80) // Add padding for tab bar
            
            // 3. Tab Bar Layer (Behind overlays)
            // Using ignoresSafeArea(.keyboard) prevents it from moving up
            VStack {
                Spacer()
                CyberpunkTabBar(
                    activeTab: $selectedTab,
                    showChatPanel: $showChatPanel
                )
            }
            .ignoresSafeArea(.keyboard)
            .ignoresSafeArea(.container, edges: .bottom)
            .zIndex(10)
            
            // 4. Ambient Overlay Effects (Global, over TabBar)
            switch overlayManager.currentEffect {
            case .nyanCat:
                NyanCatView().transition(.opacity).zIndex(15)
            case .toxicGlow:
                ToxicGlowView().transition(.opacity).zIndex(15)
            case .matrixRain:
                MatrixRainView().transition(.opacity).zIndex(15)
            case .securityScan:
                SecurityScanView().transition(.opacity).zIndex(15)
            case .staticInterference:
                StaticInterferenceView().transition(.opacity).zIndex(15)
            case .confetti:
                EmptyView() 
            case .none:
                EmptyView()
            }

            // 5. Overlays Layer (Modals)
            
            // Calendar Overlay
            if showCalendar {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .zIndex(20)
                    .onTapGesture {
                        withAnimation {
                            showCalendar = false
                        }
                    }
                
                MonthCalendarView(
                    isPresented: $showCalendar,
                    currentMonth: $currentMonth,
                    selectedDate: $selectedDate
                )
                     .transition(.move(edge: .top))
                     .zIndex(21)
            }
            
            // Chat Overlay
            if showChatPanel {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .zIndex(30)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showChatPanel = false
                        }
                    }
                
                ExpandableChatPanel(isPresented: $showChatPanel, contextItem: chatContextItem)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(31)
            }
        }
        .preferredColorScheme(.dark)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showChatPanel)
        .animation(.easeInOut(duration: 0.3), value: showCalendar)
        .onChange(of: chatContextItem) { _, newItem in
            // Auto-open chat when context item is set from AI button
            if newItem != nil && !showChatPanel {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showChatPanel = true
                }
            }
        }
        .onChange(of: showChatPanel) { _, isShowing in
            // Clear context when chat is closed
            if !isShowing {
                chatContextItem = nil
            }
        }
    }
}

#Preview {
    ContentView()
}

