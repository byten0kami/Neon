import SwiftUI

// MARK: - Protocols View (Bio-Kernel)

/// Displays facts learned by the AI about the user
/// Styled according to the active theme (CMD/Terminal aesthetic)
struct ProtocolsView: View {
    @ObservedObject private var knowledgeBase = AIKnowledgeBase.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    
    // Group facts by category
    private var groupedFacts: [String: [Fact]] {
        Dictionary(grouping: knowledgeBase.facts.filter { $0.isActive }) { $0.category }
    }
    
    private var sortedCategories: [String] {
        groupedFacts.keys.sorted()
    }
    
    var body: some View {
        let theme = themeManager.currentTheme
        
        ZStack {
            // Background
            CyberpunkBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("BIO-KERNEL // PROTOCOLS")
                        .font(.custom(theme.titleFont, size: 28))
                        .foregroundColor(theme.mainAccent)
                        .glow(color: theme.mainAccent, radius: 2)
                    
                    Spacer()
                    
                    Text("MEM_USAGE: \(knowledgeBase.facts.filter { $0.isActive }.count) BLOCKS")
                        .font(.custom(theme.timeFont, size: 16))
                        .foregroundColor(theme.mainAccent.opacity(0.7))
                }
                .padding()
                .background(Color.black.opacity(0.3))
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(theme.mainAccent.opacity(0.3)),
                    alignment: .bottom
                )
                
                // Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        if knowledgeBase.facts.filter({ $0.isActive }).isEmpty {
                            emptyStateView(theme: theme)
                        } else {
                            ForEach(sortedCategories, id: \.self) { category in
                                categorySection(category: category, facts: groupedFacts[category] ?? [], theme: theme)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    // MARK: - Components
    
    @ViewBuilder
    private func categorySection(category: String, facts: [Fact], theme: any Theme) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Category Header
            HStack {
                Text("> \(category.uppercased())")
                    .font(.custom(theme.tagFont, size: 20))
                    .foregroundColor(theme.mainAccent)
                
                Spacer()
                
                Rectangle()
                    .fill(theme.mainAccent.opacity(0.3))
                    .frame(height: 1)
            }
            
            // Facts List
            VStack(alignment: .leading, spacing: 8) {
                ForEach(facts) { fact in
                    FactRow(fact: fact, theme: theme) {
                        deleteFact(fact)
                    }
                }
            }
            .padding(.leading, 12)
        }
    }
    
    @ViewBuilder
    private func emptyStateView(theme: any Theme) -> some View {
        VStack(spacing: 16) {
            Spacer()
                .frame(height: 100)
            
            Image(systemName: "cpu")
                .font(.system(size: 48))
                .foregroundColor(theme.mainAccent.opacity(0.5))
            
            Text("NO DATA ACQUIRED")
                .font(.custom(theme.titleFont, size: 22))
                .foregroundColor(theme.mainAccent.opacity(0.7))
            
            Text("Engage in conversation to populate bio-kernel.")
                .font(.custom(theme.bodyFont, size: 16))
                .foregroundColor(theme.mainAccent.opacity(0.5))
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
    
    private func deleteFact(_ fact: Fact) {
        withAnimation {
            knowledgeBase.deactivateFact(id: fact.id)
        }
    }
}

// MARK: - Subviews

struct FactRow: View {
    let fact: Fact
    let theme: any Theme
    let onDelete: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Bullet point
            Text("•")
                .font(.custom(theme.bodyFont, size: 20))
                .foregroundColor(theme.mainAccent.opacity(0.7))
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(fact.content)
                    .font(.custom(theme.bodyFont, size: 20))
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
                
                if let note = fact.aiNote {
                    Text("// \(note)")
                        .font(.custom(theme.timeFont, size: 16))
                        .foregroundColor(theme.mainAccent.opacity(0.5))
                }
            }
            
            Spacer()
            
            // Delete Button
            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(theme.mainAccent.opacity(0.6))
                    .frame(width: 24, height: 24)
                    .background(Color.black.opacity(0.3))
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(theme.mainAccent.opacity(0.3), lineWidth: 1)
                    )
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(theme.mainAccent.opacity(isHovering ? 0.1 : 0.0))
        )
        .onHover { hovering in
            withAnimation {
                isHovering = hovering
            }
        }
    }
}

#Preview {
    ProtocolsView()
}
