import Foundation

// MARK: - Schedule Preferences

/// User preferences for daily scheduling
struct SchedulePreferences: Codable {
    var wakeTime: ScheduleTime
    var sleepTime: ScheduleTime
    var timezone: String
    
    init(
        wakeTime: ScheduleTime = ScheduleTime(hour: 7, minute: 0, label: "Wake"),
        sleepTime: ScheduleTime = ScheduleTime(hour: 23, minute: 0, label: "Sleep"),
        timezone: String = TimeZone.current.identifier
    ) {
        self.wakeTime = wakeTime
        self.sleepTime = sleepTime
        self.timezone = timezone
    }
}

/// Time of day representation
struct ScheduleTime: Codable {
    var hour: Int
    var minute: Int
    var label: String?
    
    var asDate: Date {
        Calendar.current.date(from: DateComponents(hour: hour, minute: minute)) ?? Date()
    }
    
    var displayString: String {
        String(format: "%02d:%02d", hour, minute)
    }
}
