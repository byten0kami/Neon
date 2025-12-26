import SwiftUI

// MARK: - Settings View

/// Configuration view for app settings
/// Allows users to configure their own API key and select AI model
struct SettingsView: View {
    @StateObject private var apiSettings = APISettingsStore.shared
    @State private var apiKeyInput: String = ""
    @State private var showingAPIKey: Bool = false
    @State private var saveStatus: SaveStatus = .none
    @State private var showingPurchaseAlert: Bool = false
    @State private var isModelDropdownExpanded: Bool = false
    @StateObject private var themeManager = ThemeManager.shared
    @State private var isThemeDropdownExpanded: Bool = false
    
    enum SaveStatus {
        case none, saving, saved, error
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                header
                
                // AI Engine Section
                aiEngineSection
                
                // Theme Section (Only visible if themes besides default are available)
                if themeManager.availableThemes.count > 0 {
                    themeSection
                }
                
                // About Section
                aboutSection
                
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
        .background(
            CyberpunkBackground()
                .ignoresSafeArea()
        )
        .onAppear {
            // Load existing key (masked)
            if apiSettings.hasCustomAPIKey() {
                apiKeyInput = "••••••••••••••••"
            }
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        VStack(spacing: 8) {
            // Header styled like [LOGS]
            Text("[CFG]")
                .font(.custom(Theme.monoFont, size: 28))
                .foregroundColor(Theme.cyan)
            
            Text("CONFIGURATION")
                .font(.custom(Theme.displayFont, size: 32))
                .foregroundColor(.white)
                .shadow(color: Theme.cyan.opacity(0.6), radius: 6) // Glow effect
        }
        .padding(.top, 8)
    }
    
    // MARK: - AI Engine Section
    
    private var aiEngineSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("AI ENGINE")
            
            ZStack(alignment: .leading) {
                VStack(spacing: 0) {
                    // Use Custom Key Toggle
                    customKeyToggleRow
                    
                    divider
                    
                    // API Key Input
                    apiKeyInputRow
                        .opacity(apiSettings.settings.useCustomKey ? 1.0 : 0.5)
                        .disabled(!apiSettings.settings.useCustomKey)
                    
                    divider
                    
                    // Model Selection
                    modelSelectionRow
                }
                .background(Color.black.opacity(0.7))
                .cornerRadius(CardStyle.cornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: CardStyle.cornerRadius)
                        .stroke(Theme.cyan.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: Theme.cyan.opacity(0.2), radius: 10, x: 0, y: 0)
                
                // Left accent border
                Rectangle()
                    .fill(Theme.cyan)
                    .frame(width: CardStyle.borderWidth)
                    .cornerRadius(CardStyle.cornerRadius)
            }
        }
        .alert("Premium Feature", isPresented: $showingPurchaseAlert) {
            Button("Upgrade", role: .none) { }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Claude 3.5 Sonnet is available in the Pro plan. Please upgrade to access this model.")
        }
    }
    
    // MARK: - Extracted Rows
    
    private var customKeyToggleRow: some View {
        settingsRow {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Use Custom API Key")
                        .font(.custom(Theme.monoFont, size: 20))
                        .foregroundColor(.white)
                    Text("Override built-in key")
                        .font(.custom(Theme.lightFont, size: 16))
                        .foregroundColor(Theme.slate500)
                }
                Spacer()
                Toggle("", isOn: Binding(
                    get: { apiSettings.settings.useCustomKey },
                    set: { apiSettings.setUseCustomKey($0) }
                ))
                .labelsHidden()
                .tint(Theme.cyan)
            }
        }
    }
    
    private var apiKeyInputRow: some View {
        settingsRow {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("API Key")
                        .font(.custom(Theme.monoFont, size: 20))
                        .foregroundColor(.white)
                    Button(action: openOpenRouter) {
                        Text("Get Personal Key ↗")
                            .font(.custom(Theme.monoFont, size: 16))
                            .foregroundColor(Theme.cyan)
                            .underline()
                    }
                    
                    Spacer()
                    if saveStatus == .saved {
                        Text("Saved ✓")
                            .font(.custom(Theme.monoFont, size: 16))
                            .foregroundColor(Theme.green)
                    }
                }
                
                HStack(spacing: 8) {
                    Group {
                        if showingAPIKey {
                            TextField("sk-or-v1-...", text: $apiKeyInput)
                        } else {
                            SecureField("sk-or-v1-...", text: $apiKeyInput)
                        }
                    }
                    .font(.custom(Theme.monoFont, size: 18))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Theme.backgroundPrimary)
                    .cornerRadius(CardStyle.cornerRadius)
                    .overlay(
                        RoundedRectangle(cornerRadius: CardStyle.cornerRadius)
                            .stroke(Theme.slate700, lineWidth: 1)
                    )
                    
                    Button(action: { showingAPIKey.toggle() }) {
                        Image(systemName: showingAPIKey ? "eye.slash" : "eye")
                            .foregroundColor(Theme.slate400)
                            .frame(width: 44, height: 44)
                    }
                    
                    Button(action: saveAPIKey) {
                        Text("Save")
                            .font(.custom(Theme.monoFont, size: 16))
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .padding(.horizontal, CardStyle.buttonPaddingH)
                            .padding(.vertical, CardStyle.buttonPaddingV)
                            .frame(height: CardStyle.buttonHeight)
                            .background(Theme.cyan)
                            .cornerRadius(CardStyle.cornerRadius)
                    }
                }
            }
        }
    }
    
    private var modelSelectionRow: some View {
        settingsRow {
            VStack(alignment: .leading, spacing: 8) {
                Text("AI Model")
                    .font(.custom(Theme.monoFont, size: 20))
                    .foregroundColor(.white)
                
                Text("Limited access. Use your own key or upgrade for full access.")
                    .font(.custom(Theme.lightFont, size: 14))
                    .foregroundColor(Theme.slate500)
                
                // Custom Accordion Dropdown
                VStack(spacing: 0) {
                    // Header (Always visible)
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isModelDropdownExpanded.toggle()
                        }
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                if let currentModel = APISettings.availableModels.first(where: { $0.id == apiSettings.settings.selectedModel }) {
                                    Text(currentModel.name)
                                        .font(.custom(Theme.monoFont, size: 18))
                                        .foregroundColor(.white)
                                    Text(currentModel.description)
                                        .font(.custom(Theme.monoFont, size: 15))
                                        .foregroundColor(Theme.slate500)
                                } else {
                                    Text("Select Model")
                                        .font(.custom(Theme.monoFont, size: 18))
                                        .foregroundColor(.white)
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.down")
                                .font(.system(size: 16))
                                .foregroundColor(Theme.cyan)
                                .rotationEffect(.degrees(isModelDropdownExpanded ? 180 : 0))
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(Theme.cyan.opacity(0.1))
                    }
                    
                    // Expanded Options
                    if isModelDropdownExpanded {
                        Rectangle()
                            .fill(Theme.cyan.opacity(0.3))
                            .frame(height: 1)
                        
                        VStack(spacing: 0) {
                            ForEach(APISettings.availableModels, id: \.id) { model in
                                Button(action: {
                                    if model.id.contains("cvlaude") || model.id.contains("sonnet") {
                                        showingPurchaseAlert = true
                                    } else {
                                        apiSettings.setSelectedModel(model.id)
                                        withAnimation {
                                            isModelDropdownExpanded = false
                                        }
                                    }
                                }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(model.name)
                                                .font(.custom(Theme.monoFont, size: 18))
                                                .foregroundColor(.white)
                                            Text(model.description)
                                                .font(.custom(Theme.monoFont, size: 15))
                                                .foregroundColor(Theme.slate500)
                                            // Tooltip info
                                            Text(model.tooltip)
                                                .font(.custom(Theme.lightFont, size: 12))
                                                .foregroundColor(Theme.cyan.opacity(0.8))
                                                .fixedSize(horizontal: false, vertical: true)
                                                .padding(.top, 2)
                                        }
                                        
                                        Spacer()
                                        
                                        if model.id.contains("sonnet") {
                                            Image(systemName: "lock.fill")
                                                .font(.system(size: 16))
                                                .foregroundColor(Theme.amber)
                                        } else if apiSettings.settings.selectedModel == model.id {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 16))
                                                .foregroundColor(Theme.cyan)
                                        }
                                    }
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 16)
                                    .background(
                                        apiSettings.settings.selectedModel == model.id
                                            ? Theme.cyan.opacity(0.05)
                                            : Color.clear
                                    )
                                }
                                
                                // Divider between items (except last)
                                if model.id != APISettings.availableModels.last?.id {
                                    Rectangle()
                                        .fill(Theme.slate700.opacity(0.3))
                                        .frame(height: 1)
                                }
                            }
                        }
                    }
                }
                .background(Color.black.opacity(0.6))
                .cornerRadius(CardStyle.cornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: CardStyle.cornerRadius)
                        .stroke(Theme.cyan.opacity(0.3), lineWidth: 1)
                )
            }
        }
    }
    
    // MARK: - Theme Section
    
    private var themeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("UI THEME")
            
            ZStack(alignment: .leading) {
                VStack(spacing: 0) {
                    themeSelectionRow
                }
                .background(Color.black.opacity(0.7))
                .cornerRadius(CardStyle.cornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: CardStyle.cornerRadius)
                        .stroke(themeManager.currentTheme.mainAccent.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: themeManager.currentTheme.mainAccent.opacity(0.2), radius: 10, x: 0, y: 0)
                
                // Left accent border
                Rectangle()
                    .fill(themeManager.currentTheme.mainAccent)
                    .frame(width: CardStyle.borderWidth)
                    .cornerRadius(CardStyle.cornerRadius)
            }
        }
    }
    
    private var themeSelectionRow: some View {
        settingsRow {
            VStack(alignment: .leading, spacing: 8) {
                Text("Interface Skin")
                    .font(.custom(Theme.monoFont, size: 20))
                    .foregroundColor(.white)
                
                Text("Select your preferred neural interface visualization.")
                    .font(.custom(Theme.lightFont, size: 14))
                    .foregroundColor(Theme.slate500)
                
                // Custom Accordion Dropdown
                VStack(spacing: 0) {
                    // Header (Always visible)
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isThemeDropdownExpanded.toggle()
                        }
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(themeManager.currentTheme.name)
                                    .font(.custom(Theme.monoFont, size: 18))
                                    .foregroundColor(.white)
                                Text(themeManager.currentTheme.description)
                                    .font(.custom(Theme.monoFont, size: 15))
                                    .foregroundColor(Theme.slate500)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.down")
                                .font(.system(size: 16))
                                .foregroundColor(themeManager.currentTheme.mainAccent)
                                .rotationEffect(.degrees(isThemeDropdownExpanded ? 180 : 0))
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(themeManager.currentTheme.mainAccent.opacity(0.1))
                    }
                    
                    // Expanded Options
                    if isThemeDropdownExpanded {
                        Rectangle()
                            .fill(themeManager.currentTheme.mainAccent.opacity(0.3))
                            .frame(height: 1)
                        
                        VStack(spacing: 0) {
                            ForEach(themeManager.availableThemes) { theme in
                                Button(action: {
                                    themeManager.setTheme(theme.id)
                                    withAnimation {
                                        isThemeDropdownExpanded = false
                                    }
                                }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(theme.name)
                                                .font(.custom(Theme.monoFont, size: 18))
                                                .foregroundColor(.white)
                                            Text(theme.description)
                                                .font(.custom(Theme.monoFont, size: 15))
                                                .foregroundColor(Theme.slate500)
                                        }
                                        
                                        Spacer()
                                        
                                        if themeManager.currentTheme.id == theme.id {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 16))
                                                .foregroundColor(themeManager.currentTheme.mainAccent)
                                        }
                                    }
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 16)
                                    .background(
                                        themeManager.currentTheme.id == theme.id
                                            ? themeManager.currentTheme.mainAccent.opacity(0.05)
                                            : Color.clear
                                    )
                                }
                                
                                // Divider between items (except last)
                                if theme.id != themeManager.availableThemes.last?.id {
                                    Rectangle()
                                        .fill(Theme.slate700.opacity(0.3))
                                        .frame(height: 1)
                                }
                            }
                        }
                    }
                }
                .background(Color.black.opacity(0.6))
                .cornerRadius(CardStyle.cornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: CardStyle.cornerRadius)
                        .stroke(themeManager.currentTheme.mainAccent.opacity(0.3), lineWidth: 1)
                )
            }
        }
    }

    // MARK: - About Section
    
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("ABOUT")
            
            ZStack(alignment: .leading) {
                VStack(spacing: 0) {
                    settingsRow {
                        HStack {
                            Text("Version")
                                .font(.custom(Theme.monoFont, size: 20))
                                .foregroundColor(.white)
                            Spacer()
                            Text("1.0.0")
                                .font(.custom(Theme.monoFont, size: 18))
                                .foregroundColor(Theme.slate400)
                        }
                    }
                }
                .background(Color.black.opacity(0.7))
                .cornerRadius(CardStyle.cornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: CardStyle.cornerRadius)
                        .stroke(Theme.cyan.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: Theme.cyan.opacity(0.2), radius: 10, x: 0, y: 0)
                
                // Left accent border
                Rectangle()
                    .fill(Theme.cyan)
                    .frame(width: CardStyle.borderWidth)
                    .cornerRadius(CardStyle.cornerRadius)
            }
        }
    }
    
    // MARK: - Helper Views
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.custom(Theme.monoFont, size: 16))
            .foregroundColor(Theme.purple)
            .tracking(2)
    }
    
    private func settingsRow<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
    }
    
    private var divider: some View {
        Rectangle()
            .fill(Theme.slate700.opacity(0.3))
            .frame(height: 1)
    }
    
    // MARK: - Actions
    
    private func saveAPIKey() {
        guard !apiKeyInput.isEmpty, !apiKeyInput.starts(with: "•") else { return }
        
        saveStatus = .saving
        if apiSettings.saveAPIKey(apiKeyInput) {
            saveStatus = .saved
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                saveStatus = .none
            }
        } else {
            saveStatus = .error
        }
    }
    
    private func openOpenRouter() {
        if let url = URL(string: "https://openrouter.ai/keys") {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    SettingsView()
}
