import Foundation

// MARK: - Recurrence Rule

/// Defines how a TimelineItem repeats (daily, weekly, etc.)
/// Supports both infinite habits and finite courses
struct RecurrenceRule: Codable, Hashable, Sendable {
    
    // MARK: - Frequency
    
    enum Frequency: String, Codable, Sendable {
        case minutely
        case hourly
        case daily
        case weekly
        case monthly
        case yearly
    }
    
    // MARK: - End Condition
    
    enum EndCondition: Codable, Hashable, Sendable {
        case forever                    // Indefinite (Yoga, Hydration)
        case until(Date)                // Hard stop date
        case count(Int)                 // Finite count ("5 pills")
        
        // MARK: Codable
        
        private enum CodingKeys: String, CodingKey {
            case type, date, count
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(String.self, forKey: .type)
            
            switch type {
            case "forever":
                self = .forever
            case "until":
                let date = try container.decode(Date.self, forKey: .date)
                self = .until(date)
            case "count":
                let count = try container.decode(Int.self, forKey: .count)
                self = .count(count)
            default:
                self = .forever
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            switch self {
            case .forever:
                try container.encode("forever", forKey: .type)
            case .until(let date):
                try container.encode("until", forKey: .type)
                try container.encode(date, forKey: .date)
            case .count(let count):
                try container.encode("count", forKey: .type)
                try container.encode(count, forKey: .count)
            }
        }
    }
    
    // MARK: - Properties
    
    var frequency: Frequency
    var interval: Int                   // e.g., 2 = every 2nd day/week/etc.
    var endCondition: EndCondition
    
    // For weekly recurrence: which days (0 = Sunday, 6 = Saturday)
    var weekdays: Set<Int>?
    
    // MARK: - Initializers
    
    init(
        frequency: Frequency,
        interval: Int = 1,
        endCondition: EndCondition = .forever,
        weekdays: Set<Int>? = nil
    ) {
        self.frequency = frequency
        self.interval = max(1, interval)
        self.endCondition = endCondition
        self.weekdays = weekdays
    }
    
    // MARK: - Convenience Factories
    
    /// Daily recurrence (e.g., "every day")
    static func daily(interval: Int = 1, endCondition: EndCondition = .forever) -> RecurrenceRule {
        RecurrenceRule(frequency: .daily, interval: interval, endCondition: endCondition)
    }
    
    /// Weekly recurrence on specific days
    static func weekly(on weekdays: Set<Int>, interval: Int = 1, endCondition: EndCondition = .forever) -> RecurrenceRule {
        RecurrenceRule(frequency: .weekly, interval: interval, endCondition: endCondition, weekdays: weekdays)
    }
    
    /// Finite course (e.g., "5 pills")
    static func finiteCourse(frequency: Frequency = .daily, count: Int) -> RecurrenceRule {
        RecurrenceRule(frequency: frequency, interval: 1, endCondition: .count(count))
    }
    
    // MARK: - Calculation Methods
    
    /// Check if the rule triggers on a given date relative to start date
    func triggers(on date: Date, startDate: Date, calendar: Calendar = .current) -> Bool {
        // If the date is before start, no trigger
        guard date >= calendar.startOfDay(for: startDate) else { return false }
        
        // Check end condition
        switch endCondition {
        case .forever:
            break
        case .until(let endDate):
            if date > endDate { return false }
        case .count:
            // Count-based needs external tracking
            break
        }
        
        let targetDay = calendar.startOfDay(for: date)
        let start = calendar.startOfDay(for: startDate)
        
        switch frequency {
        case .minutely:
            // Calculate minutes since start
            let minutes = calendar.dateComponents([.minute], from: startDate, to: date).minute ?? 0
            return minutes >= 0 && minutes % interval == 0
            
        case .hourly:
            // Calculate hours since start
            let hours = calendar.dateComponents([.hour], from: start, to: targetDay).hour ?? 0
            return hours >= 0 && hours % interval == 0
            
        case .daily:
            let days = calendar.dateComponents([.day], from: start, to: targetDay).day ?? 0
            return days >= 0 && days % interval == 0
            
        case .weekly:
            // Check if the weekday matches
            let weekday = calendar.component(.weekday, from: date) - 1 // 0-indexed
            guard weekdays?.contains(weekday) ?? true else { return false }
            
            let weeks = calendar.dateComponents([.weekOfYear], from: start, to: targetDay).weekOfYear ?? 0
            return weeks >= 0 && weeks % interval == 0
            
        case .monthly:
            let months = calendar.dateComponents([.month], from: start, to: targetDay).month ?? 0
            guard months >= 0 && months % interval == 0 else { return false }
            
            // Same day of month
            let startDay = calendar.component(.day, from: start)
            let targetDayOfMonth = calendar.component(.day, from: targetDay)
            return startDay == targetDayOfMonth
            
        case .yearly:
            let years = calendar.dateComponents([.year], from: start, to: targetDay).year ?? 0
            guard years >= 0 && years % interval == 0 else { return false }
            
            // Same month and day
            let startMonth = calendar.component(.month, from: start)
            let startDay = calendar.component(.day, from: start)
            let targetMonth = calendar.component(.month, from: targetDay)
            let targetDayNum = calendar.component(.day, from: targetDay)
            return startMonth == targetMonth && startDay == targetDayNum
        }
    }
    
    /// Calculate the next occurrence after a given date
    func nextOccurrence(after date: Date, startDate: Date, calendar: Calendar = .current) -> Date? {
        var current = calendar.startOfDay(for: date)
        
        // Limit search to prevent infinite loops
        for _ in 0..<365 {
            current = calendar.date(byAdding: .day, value: 1, to: current) ?? current
            if triggers(on: current, startDate: startDate, calendar: calendar) {
                return current
            }
        }
        
        return nil
    }
}

// MARK: - Display

extension RecurrenceRule {
    /// Human-readable description
    var displayText: String {
        switch frequency {
        case .minutely:
            return interval == 1 ? "Every minute" : "Every \(interval) min"
        case .hourly:
            return interval == 1 ? "Hourly" : "Every \(interval) hours"
        case .daily:
            return interval == 1 ? "Daily" : "Every \(interval) days"
        case .weekly:
            if let days = weekdays, !days.isEmpty {
                let dayNames = days.sorted().compactMap { dayNumber -> String? in
                    let formatter = DateFormatter()
                    formatter.locale = Locale(identifier: "en_US_POSIX")
                    return formatter.shortWeekdaySymbols[safe: dayNumber]
                }
                return dayNames.joined(separator: ", ")
            }
            return interval == 1 ? "Weekly" : "Every \(interval) weeks"
        case .monthly:
            return interval == 1 ? "Monthly" : "Every \(interval) months"
        case .yearly:
            return interval == 1 ? "Yearly" : "Every \(interval) years"
        }
    }
}

// MARK: - Array Safe Access Extension

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
