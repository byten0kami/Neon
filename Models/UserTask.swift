import Foundation

// MARK: - User Task Model

/// A task or reminder created by AI or user
struct UserTask: Identifiable, Codable {
    let id: UUID
    var title: String
    var description: String?
    var status: TaskStatus
    var priority: TaskPriority
    var scheduledTime: Date?           // One-time scheduled
    var dailyTime: String?             // Daily at this time (HH:mm)
    var intervalMinutes: Int?          // Recurring every N minutes
    var category: String
    var createdAt: Date
    var completedAt: Date?
    var lastTriggered: Date?
    var deferredCount: Int = 0
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String? = nil,
        status: TaskStatus = .pending,
        priority: TaskPriority = .normal,
        scheduledTime: Date? = nil,
        dailyTime: String? = nil,
        intervalMinutes: Int? = nil,
        category: String = "general"
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.status = status
        self.priority = priority
        self.scheduledTime = scheduledTime
        self.dailyTime = dailyTime
        self.intervalMinutes = intervalMinutes
        self.category = category
        self.createdAt = Date()
        self.completedAt = nil
        self.lastTriggered = nil
        self.deferredCount = 0
    }
    
    var isRecurring: Bool {
        intervalMinutes != nil || dailyTime != nil
    }
    
    var isCompleted: Bool {
        status == .completed
    }
    
    var isOverdue: Bool {
        guard !isCompleted, let scheduled = scheduledTime else { return false }
        return scheduled < Date()
    }
    
    var isDeferred: Bool {
        deferredCount > 0
    }
    
    var taskDescription: String? {
        description
    }
    
    var recurrence: String? {
        if let interval = intervalMinutes {
            return "every \(interval) min"
        } else if dailyTime != nil {
            return "daily"
        }
        return nil
    }
    
    var scheduleDescription: String {
        if let interval = intervalMinutes {
            return "Every \(interval) min"
        } else if let daily = dailyTime {
            return "Daily at \(daily)"
        } else if let time = scheduledTime {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return "At \(formatter.string(from: time))"
        }
        return ""
    }
}

// MARK: - Task Status

enum TaskStatus: String, Codable {
    case pending
    case inProgress
    case completed
    case cancelled
    case recurring  // Active recurring task
}

// MARK: - Task Priority

enum TaskPriority: String, Codable, Comparable {
    case low
    case normal
    case high
    case urgent
    
    static func < (lhs: TaskPriority, rhs: TaskPriority) -> Bool {
        let order: [TaskPriority] = [.low, .normal, .high, .urgent]
        return order.firstIndex(of: lhs)! < order.firstIndex(of: rhs)!
    }
}
