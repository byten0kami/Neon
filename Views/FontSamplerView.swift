import SwiftUI

// MARK: - Font Config Model

/// Saved font configuration for a card
struct FontConfig: Identifiable, Codable {
    let id: UUID
    var name: String
    var timeFont: String
    var titleFont: String
    var bodyFont: String
    var tagFont: String
    var themeId: ThemeID
    var priority: ItemPriority
    
    init(
        id: UUID = UUID(),
        name: String = "Untitled",
        timeFont: String = "ShareTechMono-Regular",
        titleFont: String = "Rajdhani-Bold",
        bodyFont: String = "Rajdhani-Regular",
        tagFont: String = "Rajdhani-SemiBold",
        themeId: ThemeID = .default,
        priority: ItemPriority = .normal
    ) {
        self.id = id
        self.name = name
        self.timeFont = timeFont
        self.titleFont = titleFont
        self.bodyFont = bodyFont
        self.tagFont = tagFont
        self.themeId = themeId
        self.priority = priority
    }
}

// MARK: - Available Fonts

/// All available font options
let availableFonts: [String] = [
    "Rajdhani-Bold",
    "Rajdhani-SemiBold",
    "Rajdhani-Medium",
    "Rajdhani-Regular",
    "ShareTechMono-Regular",
    "Orbitron-Bold",
    "Orbitron-Medium",
    "Orbitron-Regular",
    "Audiowide-Regular",
    "Electrolize-Regular",
    "Iceland-Regular",
    "TurretRoad-Bold",
    "TurretRoad-Medium",
    "TurretRoad-Regular",
    "TurretRoad-Light",
    "Handjet-Bold",
    "Handjet-SemiBold",
    "Handjet-Medium",
    "Handjet-Regular",
    "Handjet-Light",
    "Silkscreen-Bold",
    "Silkscreen-Regular",
    "Megrim-Regular",
    "MajorMonoDisplay-Regular",
    "Quantico-Bold",
    "Quantico-Regular",
    "Geo-Regular",
    "Iceberg-Regular",
    "Rationale-Regular",
    "SyneMono-Regular",
    "UbuntuMono-Bold",
    "UbuntuMono-Regular",
    "KellySlab-Regular",
    "Offside-Regular",
    "Anta-Regular",
    "Asimovian-Regular",
]

// MARK: - Font Constructor View

struct FontSamplerView: View {
    @State private var configs: [FontConfig] = []
    @State private var selectedConfigId: UUID? = nil
    
    // Persistence key
    private let saveKey = "FontSamplerConfigs"
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                Text("FONT CONSTRUCTOR")
                    .font(.custom("Orbitron-Bold", size: 22))
                    .foregroundColor(DesignSystem.cyan)
                    .padding(.top, 16)
                
                // Add Card Button
                Button {
                    let newConfig = FontConfig(name: "Config \(configs.count + 1)")
                    configs.append(newConfig)
                    selectedConfigId = newConfig.id
                    saveConfigs()
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("ADD CARD")
                    }
                    .font(.custom("Rajdhani-Bold", size: 16))
                    .foregroundColor(DesignSystem.lime)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(DesignSystem.lime, lineWidth: 1)
                    )
                }
                
                // Cards
                ForEach($configs) { $config in
                    FontConstructorCard(
                        config: $config,
                        isSelected: selectedConfigId == config.id,
                        onSelect: { selectedConfigId = config.id },
                        onDelete: {
                            configs.removeAll { $0.id == config.id }
                            saveConfigs()
                        },
                        onSave: { saveConfigs() }
                    )
                }
                
                // Export Section
                if !configs.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("SAVED CONFIGS")
                            .font(.custom("Rajdhani-Bold", size: 14))
                            .foregroundColor(DesignSystem.amber)
                        
                        ForEach(configs) { config in
                            HStack {
                                Text(config.name)
                                    .font(.custom("ShareTechMono-Regular", size: 12))
                                    .foregroundColor(.white)
                                Spacer()
                                Text("T:\(shortName(config.timeFont)) H:\(shortName(config.titleFont)) B:\(shortName(config.bodyFont)) G:\(shortName(config.tagFont))")
                                    .font(.custom("ShareTechMono-Regular", size: 9))
                                    .foregroundColor(DesignSystem.slate500)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(DesignSystem.backgroundSecondary)
                        }
                    }
                    .padding(12)
                    .background(DesignSystem.slate800.opacity(0.5))
                    .padding(.top, 16)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 100)
        }
        .onAppear { loadConfigs() }
    }
    
    private func shortName(_ font: String) -> String {
        font.replacingOccurrences(of: "-Regular", with: "")
             .replacingOccurrences(of: "-Bold", with: "B")
             .replacingOccurrences(of: "-SemiBold", with: "SB")
             .replacingOccurrences(of: "-Medium", with: "M")
             .replacingOccurrences(of: "-Light", with: "L")
    }
    
    private func saveConfigs() {
        if let data = try? JSONEncoder().encode(configs) {
            UserDefaults.standard.set(data, forKey: saveKey)
        }
    }
    
    private func loadConfigs() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([FontConfig].self, from: data) {
            configs = decoded
        }
    }
}

struct FontConstructorCard: View {
    @Binding var config: FontConfig
    let isSelected: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void
    let onSave: () -> Void
    
    @State private var isEditing = false
    
    // Get theme-aware styling
    private var priorityStyle: PriorityTagStyle {
        config.themeId.theme.priorityTagStyle(for: config.priority)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Card Preview with theme styling AND custom fonts
            themedCardPreview
                .overlay(
                    RoundedRectangle(cornerRadius: CardStyle.cornerRadius)
                        .stroke(isSelected ? DesignSystem.lime : Color.clear, lineWidth: isSelected ? 2 : 0)
                )
                .onTapGesture { onSelect() }
            
            // Pickers (when selected)
            if isSelected {
                VStack(spacing: 8) {
                    // Config Name
                    HStack {
                        Text("NAME:")
                            .font(.custom("ShareTechMono-Regular", size: 11))
                            .foregroundColor(DesignSystem.slate500)
                        TextField("Config Name", text: $config.name)
                            .font(.custom("ShareTechMono-Regular", size: 12))
                            .foregroundColor(.white)
                            .textFieldStyle(.plain)
                            .onChange(of: config.name) { _, _ in onSave() }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(DesignSystem.slate800)
                    
                    // Theme Picker
                    ThemePickerRow(
                        selection: $config.themeId,
                        onSave: onSave
                    )
                    .onChange(of: config.themeId) { _, newThemeId in
                        // Auto-fill fonts from the selected theme
                        let theme = newThemeId.theme
                        config.timeFont = theme.timeFont
                        config.titleFont = theme.titleFont
                        config.bodyFont = theme.bodyFont
                        config.tagFont = theme.tagFont
                        onSave()
                    }
                    
                    // Priority Picker
                    PriorityPickerRow(
                        selection: $config.priority,
                        themeId: config.themeId,
                        onSave: onSave
                    )
                    
                    // Font Pickers (for reference, these control display not actual card fonts)
                    FontPickerRow(label: "TIME", selection: $config.timeFont, onSave: onSave)
                    FontPickerRow(label: "TITLE", selection: $config.titleFont, onSave: onSave)
                    FontPickerRow(label: "BODY", selection: $config.bodyFont, onSave: onSave)
                    FontPickerRow(label: "TAG", selection: $config.tagFont, onSave: onSave)
                    
                    // Delete Button
                    Button {
                        onDelete()
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("DELETE")
                        }
                        .font(.custom("Rajdhani-Bold", size: 12))
                        .foregroundColor(DesignSystem.red)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(DesignSystem.red, lineWidth: 1)
                        )
                    }
                    .padding(.top, 4)
                }
                .padding(10)
                .background(DesignSystem.backgroundSecondary)
            }
        }
    }
    
    // MARK: - Themed Card Preview with Custom Fonts
    
    /// Card preview that matches UniversalTimelineCard structure but uses custom fonts
    private var themedCardPreview: some View {
        let accentColor = priorityStyle.color
        
        return VStack(alignment: .leading, spacing: 6) {
            // Header: Badge + Time
            HStack(alignment: .center, spacing: 8) {
                // Priority Tag (using theme styling)
                Text(priorityStyle.text)
                    .font(.custom(config.tagFont, size: 11))
                    .fontWeight(.bold)
                    .foregroundColor(priorityStyle.textColor ?? accentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(priorityStyle.backgroundColor ?? Color.clear)
                    .cornerRadius(priorityStyle.borderRadius)
                    .overlay(
                        RoundedRectangle(cornerRadius: priorityStyle.borderRadius)
                            .stroke(accentColor, lineWidth: 1)
                    )
                    .shadow(
                        color: priorityStyle.hasGlow ? accentColor.opacity(0.8) : .clear,
                        radius: priorityStyle.glowRadius
                    )
                
                Spacer()
                
                // Time
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .shadow(color: accentColor.opacity(0.8), radius: 5)
                    
                    Text("10:30")
                        .font(.custom(config.timeFont, size: 16))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .shadow(color: accentColor.opacity(0.8), radius: 5)
                }
            }
            
            // Title
            Text("Sample Task Title")
                .font(.custom(config.titleFont, size: 18))
                .foregroundColor(.white)
                .shadow(color: accentColor.opacity(0.6), radius: 6)
                .padding(.top, 4)
            
            // Description
            Text("This is sample body text for the description area.")
                .font(.custom(config.bodyFont, size: config.themeId.theme.bodyFontSize))
                .foregroundColor(DesignSystem.slate400)
            
            // Actions row
            Rectangle()
                .fill(accentColor.opacity(0.3))
                .frame(height: 1)
                .padding(.vertical, 4)
            
            HStack(spacing: 12) {
                Spacer()
                
                // Skip button
                HStack(spacing: 6) {
                    Image(systemName: "arrow.turn.up.right")
                        .font(.system(size: 12, weight: .bold))
                    Text("Skip")
                        .font(.custom(config.tagFont, size: 12))
                        .fontWeight(.bold)
                }
                .foregroundColor(DesignSystem.slate500)
                .padding(.horizontal, CardStyle.buttonPaddingH)
                .padding(.vertical, CardStyle.buttonPaddingV)
                .frame(height: CardStyle.buttonHeight)
                .overlay(
                    RoundedRectangle(cornerRadius: CardStyle.cornerRadius)
                        .stroke(DesignSystem.slate500, lineWidth: 1)
                )
                
                // Done button
                HStack(spacing: 6) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                    Text("Done")
                        .font(.custom(config.tagFont, size: 12))
                        .fontWeight(.bold)
                }
                .foregroundColor(accentColor)
                .padding(.horizontal, CardStyle.buttonPaddingH)
                .padding(.vertical, CardStyle.buttonPaddingV)
                .frame(height: CardStyle.buttonHeight)
                .background(accentColor.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: CardStyle.cornerRadius)
                        .stroke(accentColor, lineWidth: 1)
                )
                .cornerRadius(CardStyle.cornerRadius)
            }
        }
        .padding(CardStyle.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CardBackground(accentColor: accentColor))
    }
}

// MARK: - Theme Picker Row

struct ThemePickerRow: View {
    @Binding var selection: ThemeID
    let onSave: () -> Void
    
    var body: some View {
        HStack {
            Text("THEME")
                .font(.custom("ShareTechMono-Regular", size: 10))
                .foregroundColor(DesignSystem.amber)
                .frame(width: 50, alignment: .leading)
            
            Menu {
                ForEach(ThemeID.allCases, id: \.self) { themeId in
                    Button {
                        selection = themeId
                        onSave()
                    } label: {
                        HStack {
                            Circle()
                                .fill(themeId.theme.mainAccent)
                                .frame(width: 10, height: 10)
                            Text(themeId.theme.name.uppercased())
                        }
                    }
                }
            } label: {
                HStack {
                    Circle()
                        .fill(selection.theme.mainAccent)
                        .frame(width: 10, height: 10)
                    Text(selection.theme.name.uppercased())
                        .font(.custom("ShareTechMono-Regular", size: 12))
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10))
                        .foregroundColor(DesignSystem.slate500)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(DesignSystem.slate800)
            }
        }
    }
}

// MARK: - Priority Picker Row

struct PriorityPickerRow: View {
    @Binding var selection: ItemPriority
    let themeId: ThemeID
    let onSave: () -> Void
    
    var body: some View {
        let theme = themeId.theme
        
        HStack {
            Text("PRIO")
                .font(.custom("ShareTechMono-Regular", size: 10))
                .foregroundColor(DesignSystem.purple)
                .frame(width: 50, alignment: .leading)
            
            Menu {
                ForEach(ItemPriority.allCases, id: \.self) { priority in
                    let style = theme.priorityTagStyle(for: priority)
                    Button {
                        selection = priority
                        onSave()
                    } label: {
                        HStack {
                            Circle()
                                .fill(style.color)
                                .frame(width: 10, height: 10)
                            Text(priority.displayName)
                        }
                    }
                }
            } label: {
                let currentStyle = theme.priorityTagStyle(for: selection)
                HStack {
                    Circle()
                        .fill(currentStyle.color)
                        .frame(width: 10, height: 10)
                    Text(selection.displayName)
                        .font(.custom("ShareTechMono-Regular", size: 12))
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10))
                        .foregroundColor(DesignSystem.slate500)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(DesignSystem.slate800)
            }
        }
    }
}

// MARK: - Font Picker Row

struct FontPickerRow: View {
    let label: String
    @Binding var selection: String
    let onSave: () -> Void
    
    var body: some View {
        HStack {
            Text(label)
                .font(.custom("ShareTechMono-Regular", size: 10))
                .foregroundColor(DesignSystem.cyan)
                .frame(width: 40, alignment: .leading)
            
            Menu {
                ForEach(availableFonts, id: \.self) { font in
                    Button {
                        selection = font
                        onSave()
                    } label: {
                        Text(font)
                            .font(.custom(font, size: 14))
                    }
                }
            } label: {
                HStack {
                    Text(selection)
                        .font(.custom(selection, size: 12))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10))
                        .foregroundColor(DesignSystem.slate500)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(DesignSystem.slate800)
            }
        }
    }
}

#Preview {
    ZStack {
        DesignSystem.backgroundPrimary.ignoresSafeArea()
        FontSamplerView()
    }
}
