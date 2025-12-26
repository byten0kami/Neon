import Foundation

// MARK: - Scheduled Event

/// Any schedulable item - medication, meal, activity, reminder, timer
struct ScheduledEvent: Identifiable, Codable {
    let id: UUID
    var type: EventType
    var title: String
    var description: String?
    var scheduledTime: Date?
    var duration: TimeInterval?
    var status: EventStatus
    var priority: EventPriority
    var metadata: [String: String]
    
    init(
        id: UUID = UUID(),
        type: EventType,
        title: String,
        description: String? = nil,
        scheduledTime: Date? = nil,
        duration: TimeInterval? = nil,
        status: EventStatus = .pending,
        priority: EventPriority = .normal,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.description = description
        self.scheduledTime = scheduledTime
        self.duration = duration
        self.status = status
        self.priority = priority
        self.metadata = metadata
    }
}

enum EventStatus: String, Codable {
    case pending, inProgress, completed, skipped, rescheduled
}

enum EventPriority: Int, Codable, Comparable {
    case low = 0
    case normal = 1
    case high = 2
    case critical = 3
    
    static func < (lhs: EventPriority, rhs: EventPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
