import Foundation

// MARK: - Timeline Item

/// Unified entity for the Master-Instance architecture.
/// Acts as both Master (template) and Instance (concrete occurrence) depending on usage.
///
/// - **Master**: Has `recurrence` set, `seriesId` is nil. Hidden from daily view.
/// - **Instance**: Has `seriesId` linking to Master. Lives in the timeline.
/// - **Ghost**: Temporary in-memory projection (not persisted until interaction).
/// - **One-off**: No recurrence, no seriesId. Single occurrence.
struct TimelineItem: Identifiable, Codable, Sendable {
    
    // MARK: - Identity
    
    let id: UUID
    var seriesId: UUID?                 // Link to Master. If nil -> Master or One-off
    
    // MARK: - Core Data
    
    var title: String
    var description: String?
    var priority: ItemPriority
    var category: String                // For backwards compatibility / grouping
    
    // MARK: - Scheduling
    
    var scheduledTime: Date             // Original planned time
    var deferredUntil: Date?            // Snooze time (does not affect schedule)
    
    // MARK: - Lifecycle
    
    var isCompleted: Bool = false
    var isSkipped: Bool = false     // Completed but skipped (cancelled/dismissed)
    var completedAt: Date?
    var isArchived: Bool = false        // Soft delete for Masters
    var createdAt: Date
    
    // MARK: - Master Config (Only on Masters)
    
    var recurrence: RecurrenceRule?
    
    // MARK: - Optimization: Effective End Date (The Sieve)
    
    /// Calculated from recurrence.endCondition.
    /// Used to optimize infinite scroll queries.
    /// - If rule ends in 2025, this is 2025.
    /// - If forever, this is nil (infinite).
    var effectiveEndDate: Date?
    
    // MARK: - Tracking
    
    var deferredCount: Int = 0
    var completedCount: Int = 0         // For recurring: how many times completed
    
    // MARK: - Initializer
    
    init(
        id: UUID = UUID(),
        seriesId: UUID? = nil,
        title: String,
        description: String? = nil,
        priority: ItemPriority = .normal,
        category: String = "task",
        scheduledTime: Date,
        deferredUntil: Date? = nil,
        isCompleted: Bool = false,
        isSkipped: Bool = false,
        completedAt: Date? = nil,
        isArchived: Bool = false,
        createdAt: Date = Date(),
        recurrence: RecurrenceRule? = nil,
        effectiveEndDate: Date? = nil,
        deferredCount: Int = 0,
        completedCount: Int = 0
    ) {
        self.id = id
        self.seriesId = seriesId
        self.title = title
        self.description = description
        self.priority = priority
        self.category = category
        self.scheduledTime = scheduledTime
        self.deferredUntil = deferredUntil
        self.isCompleted = isCompleted
        self.isSkipped = isSkipped
        self.completedAt = completedAt
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.recurrence = recurrence
        self.effectiveEndDate = effectiveEndDate
        self.deferredCount = deferredCount
        self.completedCount = completedCount
    }
    
    // MARK: - Computed Properties
    
    /// True if this item is a Master (has recurrence, no seriesId)
    var isMaster: Bool {
        recurrence != nil && seriesId == nil
    }
    
    /// True if this item is an Instance (has seriesId linking to Master)
    var isInstance: Bool {
        seriesId != nil
    }
    
    /// True if this item is a one-off (no recurrence, no seriesId)
    var isOneOff: Bool {
        recurrence == nil && seriesId == nil
    }
    
    /// True if this item is overdue (past scheduled time, not completed)
    var isOverdue: Bool {
        guard !isCompleted else { return false }
        let effectiveTime = deferredUntil ?? scheduledTime
        return effectiveTime < Date()
    }
    
    /// True if this item has been deferred
    var isDeferred: Bool {
        deferredUntil != nil
    }
    
    /// The effective time used for display and sorting
    var effectiveTime: Date {
        deferredUntil ?? scheduledTime
    }
    
    /// Human-readable recurrence text
    var recurrenceText: String? {
        recurrence?.displayText
    }
    
    // MARK: - Factory Methods
    
    /// Create a Ghost (in-memory projection) from a Master for a specific date
    static func ghost(from master: TimelineItem, for date: Date) -> TimelineItem {
        var ghost = TimelineItem(
            id: UUID(),  // New ID for the ghost
            seriesId: master.id,  // Link to master
            title: master.title,
            description: master.description,
            priority: master.priority,
            category: master.category,
            scheduledTime: date,
            recurrence: nil  // Ghosts don't have recurrence
        )
        ghost.isSkipped = false
        ghost.effectiveEndDate = nil
        return ghost
    }
    
    /// Create a Master for a recurring task
    static func master(
        title: String,
        description: String? = nil,
        priority: ItemPriority = .normal,
        category: String = "task",
        startTime: Date,
        recurrence: RecurrenceRule
    ) -> TimelineItem {
        var item = TimelineItem(
            title: title,
            description: description,
            priority: priority,
            category: category,
            scheduledTime: startTime,
            recurrence: recurrence
        )
        
        // Calculate effective end date from recurrence
        switch recurrence.endCondition {
        case .forever:
            item.effectiveEndDate = nil
        case .until(let date):
            item.effectiveEndDate = date
        case .count:
            // For count-based, we don't know the end date yet
            item.effectiveEndDate = nil
        }
        
        return item
    }
    
    /// Create a one-off task
    static func oneOff(
        title: String,
        description: String? = nil,
        priority: ItemPriority = .normal,
        category: String = "task",
        scheduledTime: Date
    ) -> TimelineItem {
        TimelineItem(
            title: title,
            description: description,
            priority: priority,
            category: category,
            scheduledTime: scheduledTime
        )
    }
}

// MARK: - Hashable

extension TimelineItem: Hashable {
    static func == (lhs: TimelineItem, rhs: TimelineItem) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
