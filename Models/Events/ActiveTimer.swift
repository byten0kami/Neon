import Foundation

// MARK: - Active Timer

/// Active countdown timer
struct ActiveTimer: Identifiable {
    let id: UUID
    let name: String
    let startTime: Date
    let durationMinutes: Int
    
    var endTime: Date {
        startTime.addingTimeInterval(TimeInterval(durationMinutes * 60))
    }
    
    var remainingSeconds: Int {
        max(0, Int(endTime.timeIntervalSinceNow))
    }
    
    var isExpired: Bool {
        remainingSeconds <= 0
    }
}
