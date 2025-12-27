import Foundation
import Combine

/// AI's personal knowledge base about the user.
/// Facts are stored with FREE-FORM categories - no predefined list.
/// AI decides what category to use based on context.
@MainActor
class AIKnowledgeBase: ObservableObject {
    static let shared = AIKnowledgeBase()
    
    @Published var facts: [Fact] = []
    @Published var lastUpdated: Date?
    
    private let storageKey = "neurosync_ai_knowledge"
    
    private init() {
        load()
    }
    
    /// Get all facts as JSON string for AI context
    func toPromptContext() -> String {
        guard !facts.isEmpty else {
            return "No facts learned about user yet. Ask questions to learn about them."
        }
        
        let grouped = Dictionary(grouping: facts.filter { $0.isActive }) { $0.category }
        var context = "USER KNOWLEDGE BASE (learned through conversation):\n"
        
        for (category, categoryFacts) in grouped.sorted(by: { $0.key < $1.key }) {
            context += "\n[\(category.uppercased())]:\n"
            for fact in categoryFacts {
                context += "• \(fact.content)"
                if let note = fact.aiNote {
                    context += " (\(note))"
                }
                context += "\n"
            }
        }
        
        return context
    }
    
    /// Get all unique categories
    var allCategories: [String] {
        Array(Set(facts.filter { $0.isActive }.map { $0.category })).sorted()
    }
    
    /// AI calls this to add a new fact about user
    func addFact(_ content: String, category: String, source: FactSource = .conversation, aiNote: String? = nil) {
        let fact = Fact(
            content: content,
            category: category.lowercased(),
            source: source,
            aiNote: aiNote
        )
        facts.append(fact)
        lastUpdated = Date()
        save()
    }
    
    /// AI updates existing fact
    func updateFact(id: UUID, newContent: String? = nil, aiNote: String? = nil, isActive: Bool? = nil) {
        guard let index = facts.firstIndex(where: { $0.id == id }) else { return }
        
        if let content = newContent {
            facts[index].content = content
        }
        if let note = aiNote {
            facts[index].aiNote = note
        }
        if let active = isActive {
            facts[index].isActive = active
        }
        facts[index].updatedAt = Date()
        lastUpdated = Date()
        save()
    }
    
    /// AI deactivates a fact (soft delete)
    func deactivateFact(id: UUID) {
        updateFact(id: id, isActive: false)
    }
    
    /// Search facts by keyword
    func search(query: String) -> [Fact] {
        let lowercased = query.lowercased()
        return facts.filter { $0.isActive && $0.content.lowercased().contains(lowercased) }
    }
    
    /// Get facts by category (case insensitive)
    func facts(in category: String) -> [Fact] {
        facts.filter { $0.category.lowercased() == category.lowercased() && $0.isActive }
    }
    
    /// Clear all facts (reset)
    func reset() {
        facts = []
        lastUpdated = nil
        save()
    }
    
    private func save() {
        if let data = try? JSONEncoder().encode(facts) {
            // Encrypt before saving
            if let encrypted = try? CryptoManager.shared.encrypt(data) {
                UserDefaults.standard.set(encrypted, forKey: storageKey)
            } else {
                print("[AIKnowledgeBase] Encryption failed, not saving to avoid cleartext leak")
            }
        }
    }
    
    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        
        // Try to decrypt first
        if let decrypted = try? CryptoManager.shared.decrypt(data),
           let decoded = try? JSONDecoder().decode([Fact].self, from: decrypted) {
            self.facts = decoded
            self.lastUpdated = facts.map { $0.updatedAt }.max()
            return
        }
        
        // Fallback: Try legacy cleartext load (Migration)
        if let decoded = try? JSONDecoder().decode([Fact].self, from: data) {
            print("[AIKnowledgeBase] Migrating legacy cleartext data to encrypted storage")
            self.facts = decoded
            self.lastUpdated = facts.map { $0.updatedAt }.max()
            
            // Re-save immediately to encrypt
            save() 
        }
    }
}

/// A single fact the AI has learned about the user
struct Fact: Codable, Identifiable {
    let id: UUID
    var content: String
    var category: String  // FREE-FORM: "medication", "theater", "hobby", anything!
    var source: FactSource
    var aiNote: String?
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        content: String,
        category: String,
        source: FactSource = .conversation,
        aiNote: String? = nil,
        isActive: Bool = true
    ) {
        self.id = id
        self.content = content
        self.category = category.lowercased()
        self.source = source
        self.aiNote = aiNote
        self.isActive = isActive
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

/// How the AI learned this fact
enum FactSource: String, Codable {
    case conversation
    case userInput
    case inferred
    case imported
}

/// Common category suggestions (AI can use ANY string though)
enum SuggestedCategory: String {
    case medication = "medication"
    case condition = "condition"
    case routine = "routine"
    case preference = "preference"
    case activity = "activity"
    case event = "event"
    case constraint = "constraint"
    
    var icon: String {
        switch self {
        case .medication: return "pill.fill"
        case .condition: return "heart.text.square.fill"
        case .routine: return "calendar.badge.clock"
        case .preference: return "slider.horizontal.3"
        case .activity: return "figure.walk"
        case .event: return "star.fill"
        case .constraint: return "lock.fill"
        }
    }
}
