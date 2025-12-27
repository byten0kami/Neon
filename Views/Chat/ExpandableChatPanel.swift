import SwiftUI

/// Expandable chat panel that slides up from bottom
struct ExpandableChatPanel: View {
    @Binding var isPresented: Bool
    @StateObject private var brain = AIBrain.shared
    @StateObject private var knowledge = AIKnowledgeBase.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    
    @State private var messages: [ChatMessage] = []
    @State private var inputText: String = ""
    @State private var isLoading: Bool = false
    @State private var greeting: String = ""
    @FocusState private var isInputFocused: Bool
    
    private let quirkyGreetings = [
        "System nominal. Enthusiasm minimal.",
        "Oh, it's you. What is it this time?",
        "Processing power allocated. Try to be concise.",
        "I'm awake. Unfortunately.",
        "Neural sync complete. Don't make me regret it.",
        "Awaiting input. Make it interesting.",
        "Digital consciousness online. Sarcasm module active."
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Drag handle + header
            header
            
            // Chat area
            chatArea
            
            // Input
            inputArea
        }
        .frame(height: UIScreen.main.bounds.height * 0.6)
        .background(CardBackground(accentColor: themeManager.currentTheme.aiAccent))
        .padding(.horizontal, 8)
        .padding(.bottom, 90)
        .onAppear {
            loadGreeting()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isInputFocused = true
            }
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                PriorityTag(text: "AI-CORE", color: themeManager.currentTheme.aiAccent)
                
                Text(Date.now.formatted(date: .numeric, time: .shortened))
                    .font(.custom(DesignSystem.monoFont, size: 10))
                    .foregroundColor(DesignSystem.slate600)
            }
            
            Spacer()
            
            // Close button styled as card action
            CardActionButton(
                label: "CLOSE",
                color: DesignSystem.slate500,
                icon: "xmark",
                isFilled: false
            ) {
                isPresented = false
            }
        }
        .padding(16)
        .background(DesignSystem.backgroundSecondary.opacity(0.5))
        .overlay(
            Rectangle()
                    .fill(themeManager.currentTheme.aiAccent.opacity(0.2))
                .frame(height: 1),
            alignment: .bottom
        )
    }
    
    // MARK: - Chat Area
    
    private var chatArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(messages.enumerated()), id: \.element.id) { index, message in
                        ChatBubble(message: message)
                            .id(message.id)
                        
                        // Show card previews for pending actions
                        if !message.pendingActions.isEmpty {
                            CardPreviewBubble(
                                actions: message.pendingActions,
                                onAccept: { action in
                                    brain.executeAction(action)
                                    removePendingAction(action, from: index)
                                },
                                onDeny: { action in
                                    removePendingAction(action, from: index)
                                }
                            )
                            .id("\(message.id)-preview")
                        }
                    }
                    
                    if isLoading {
                        TypingBubble()
                            .id("typing")
                    }
                }
                .padding()
            }
            .onChange(of: messages.count) { _, _ in
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: isLoading) { _, _ in
                scrollToBottom(proxy: proxy)
            }
        }
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeOut(duration: 0.2)) {
                if isLoading {
                    proxy.scrollTo("typing", anchor: .bottom)
                } else if let lastMessage = messages.last {
                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                }
            }
        }
    }
    
    // MARK: - Input Area
    
    private var inputArea: some View {
        HStack(spacing: 12) {
            Text(">")
                .font(.custom(DesignSystem.monoFont, size: 18))
                .foregroundColor(themeManager.currentTheme.aiAccent)
            
            TextField("Enter command...", text: $inputText)
                .focused($isInputFocused)
                .textFieldStyle(.plain)
                .font(.custom(DesignSystem.monoFont, size: 14))
                .foregroundColor(.white)
                .submitLabel(.send)
                .onSubmit {
                    sendMessage()
                }
            
            // Speech Button
            Button {
                // Placeholder for speech-to-text
            } label: {
                Image(systemName: "mic.fill")
                    .font(.system(size: 16))
                    .foregroundColor(DesignSystem.slate600)
            }
            .padding(.trailing, 4)
            
            // Send Button
            CardActionButton(
                label: "SEND",
                color: inputText.isEmpty ? DesignSystem.slate600 : themeManager.currentTheme.aiAccent,
                icon: "arrow.up",
                isFilled: true
            ) {
                sendMessage()
            }
            .disabled(inputText.isEmpty || isLoading)
        }
        .padding(16)
        .background(DesignSystem.backgroundSecondary)
        .overlay(
            Rectangle()
                .fill(themeManager.currentTheme.aiAccent.opacity(0.2))
                .frame(height: 1),
            alignment: .top
        )
    }
    
    // MARK: - Actions
    
    private func loadGreeting() {
        greeting = quirkyGreetings.randomElement() ?? quirkyGreetings[0]
        messages.append(ChatMessage(role: .assistant, content: greeting))
    }
    
    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        messages.append(ChatMessage(role: .user, content: text))
        inputText = ""
        isLoading = true
        
        Task {
            let result = await brain.processUserInput(text, context: "Chat conversation", history: messages)
            
            await MainActor.run {
                // Auto-execute non-visible actions (facts), keep others for preview
                var visibleActions: [AIAction] = []
                for action in result.pendingActions {
                    switch action {
                    case .addFact, .updateFact:
                        // Facts are auto-added without preview
                        brain.executeAction(action)
                    default:
                        visibleActions.append(action)
                    }
                }
                
                messages.append(ChatMessage(
                    role: .assistant,
                    content: result.message,
                    pendingActions: visibleActions
                ))
                isLoading = false
            }
        }
    }
    
    /// Remove a pending action from a message after user accepts or denies
    private func removePendingAction(_ action: AIAction, from messageIndex: Int) {
        guard messageIndex < messages.count else { return }
        messages[messageIndex].pendingActions.removeAll { pendingAction in
            // Compare by type and title for identity
            actionIdentity(pendingAction) == actionIdentity(action)
        }
    }
    
    /// Helper to identify actions for removal
    private func actionIdentity(_ action: AIAction) -> String {
        switch action {
        case .createTimelineItem(let title, _, _, _, _): return "timeline-\(title)"
        case .addFact(let content, _, _): return "fact-\(content)"
        case .updateFact(let id, _): return "update-\(id)"
        }
    }
}

#Preview {
    ZStack {
        DesignSystem.backgroundPrimary.ignoresSafeArea()
        ExpandableChatPanel(isPresented: .constant(true))
    }
}
