import Foundation
import UserNotifications

// MARK: - Timeline Engine

/// The core engine for the Master-Instance architecture.
/// Handles ghost projection, time debt, and item management.
@MainActor
class TimelineEngine: ObservableObject {
    static let shared = TimelineEngine()
    
    // MARK: - Storage
    
    @Published var masters: [TimelineItem] = []         // Masters (recurrence rules)
    @Published var instances: [TimelineItem] = []       // Saved instances (materialized ghosts + one-offs)
    
    private let mastersKey = "neon_timeline_masters_v2"
    private let instancesKey = "neon_timeline_instances_v2"
    
    private lazy var calendar: Calendar = {
        var cal = Calendar.current
        cal.timeZone = TimeZone.current
        return cal
    }()
    
    // MARK: - Initialization
    
    private init() {
        load()
        requestNotificationPermission()
    }
    
    // MARK: - Main Query Method
    
    /// Returns all items (debt + instances + ghosts) for a specific date
    /// This is the primary method used by the UI
    func items(for viewDate: Date) -> [TimelineItem] {
        let dayStart = calendar.startOfDay(for: viewDate)
        
        var result: [TimelineItem] = []
        
        // 1. Fetch Real Instances for the view date
        let realInstances = instances.filter { instance in
            let instanceDay = calendar.startOfDay(for: instance.effectiveTime)
            return instanceDay == dayStart && !instance.isArchived
        }
        result.append(contentsOf: realInstances)
        
        // 2. Collect existing instance seriesIds for this date to avoid ghost duplication
        let existingSeriesIds = Set(realInstances.compactMap { $0.seriesId })
        
        // 3. Project Ghosts from active Masters (The Sieve)
        let activeGhosts = projectGhosts(for: viewDate, excluding: existingSeriesIds)
        result.append(contentsOf: activeGhosts)
        
        // 4. Fetch Debt (only for Today)
        if calendar.isDateInToday(viewDate) {
            let debt = fetchDebt()
            result.append(contentsOf: debt)
        }
        
        // 5. Sort: Debt first (critical overdue), then by time
        return result.sorted { item1, item2 in
            // Critical overdue items first
            let isDebt1 = item1.isOverdue && item1.mustBeCompleted
            let isDebt2 = item2.isOverdue && item2.mustBeCompleted
            
            if isDebt1 != isDebt2 {
                return isDebt1
            }
            
            // Critical priority items next
            if item1.priority == .critical && item2.priority != .critical {
                return true
            }
            if item2.priority == .critical && item1.priority != .critical {
                return false
            }
            
            // Then by effective time
            return item1.effectiveTime < item2.effectiveTime
        }
    }
    
    // MARK: - The Sieve (Query Optimization)
    
    /// Filters masters that are active for the given date
    /// master.startDate <= viewDate AND (master.effectiveEndDate == nil OR effectiveEndDate >= viewDate)
    private func sieve(for viewDate: Date) -> [TimelineItem] {
        let targetDay = calendar.startOfDay(for: viewDate)
        
        return masters.filter { master in
            guard !master.isArchived else { return false }
            
            // Check if master has started
            let masterStart = calendar.startOfDay(for: master.scheduledTime)
            guard targetDay >= masterStart else { return false }
            
            // Check if master has ended
            if let endDate = master.effectiveEndDate {
                let endDay = calendar.startOfDay(for: endDate)
                guard targetDay <= endDay else { return false }
            }
            
            return true
        }
    }
    
    // MARK: - Ghost Projection
    
    /// Projects ghosts from active masters for a given date
    private func projectGhosts(for viewDate: Date, excluding existingSeriesIds: Set<UUID>) -> [TimelineItem] {
        let activeMasters = sieve(for: viewDate)
        var ghosts: [TimelineItem] = []
        
        for master in activeMasters {
            // Skip if a real instance already exists for this master on this date
            guard !existingSeriesIds.contains(master.id) else { continue }
            
            // Check if the recurrence rule triggers on this date
            guard let recurrence = master.recurrence else { continue }
            
            if recurrence.triggers(on: viewDate, startDate: master.scheduledTime, calendar: calendar) {
                // Create ghost with the scheduled time set to viewDate + master's time-of-day
                let ghostTime = combineDateWithTime(date: viewDate, time: master.scheduledTime)
                let ghost = TimelineItem.ghost(from: master, for: ghostTime)
                ghosts.append(ghost)
            }
        }
        
        return ghosts
    }
    
    /// Helper: Combine date from one Date and time from another
    private func combineDateWithTime(date: Date, time: Date) -> Date {
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: time)
        
        var combined = DateComponents()
        combined.year = dateComponents.year
        combined.month = dateComponents.month
        combined.day = dateComponents.day
        combined.hour = timeComponents.hour
        combined.minute = timeComponents.minute
        combined.second = timeComponents.second
        
        return calendar.date(from: combined) ?? date
    }
    
    // MARK: - Time Debt
    
    /// Fetches overdue items that must be completed (rolls over to Today)
    private func fetchDebt() -> [TimelineItem] {
        let today = calendar.startOfDay(for: Date())
        
        return instances.filter { item in
            guard item.mustBeCompleted else { return false }
            guard !item.isCompleted else { return false }
            guard !item.isArchived else { return false }
            
            // Item is in the past
            let itemDay = calendar.startOfDay(for: item.effectiveTime)
            return itemDay < today
        }
    }
    
    // MARK: - Materialization
    
    /// Convert a ghost into a real instance (save to DB)
    func materialize(_ ghost: TimelineItem) {
        // Check if already materialized
        guard !instances.contains(where: { $0.id == ghost.id }) else { return }
        
        instances.append(ghost)
        save()
        
        // Schedule notification if in the future
        if ghost.effectiveTime > Date() {
            scheduleNotification(for: ghost)
        }
    }
    
    // MARK: - CRUD Operations
    
    /// Add a new Master (recurring item)
    func addMaster(_ master: TimelineItem) {
        guard master.isMaster else {
            print("[TimelineEngine] Attempted to add non-master as master")
            return
        }
        
        // Duplicate check
        let isDuplicate = masters.contains { existing in
            existing.title.lowercased() == master.title.lowercased() && !existing.isArchived
        }
        
        guard !isDuplicate else {
            print("[TimelineEngine] Skipping duplicate master: \(master.title)")
            return
        }
        
        masters.append(master)
        save()
        print("[TimelineEngine] Added master: \(master.title)")
    }
    
    /// Add a new one-off item
    func addOneOff(_ item: TimelineItem) {
        guard item.isOneOff else {
            print("[TimelineEngine] Attempted to add non-one-off as one-off")
            return
        }
        
        instances.append(item)
        save()
        
        if item.effectiveTime > Date() {
            scheduleNotification(for: item)
        }
        
        print("[TimelineEngine] Added one-off: \(item.title)")
    }
    
    /// Complete an item
    func complete(id: UUID) {
        // Check instances first
        if let index = instances.firstIndex(where: { $0.id == id }) {
            instances[index].isCompleted = true
            instances[index].completedAt = Date()
            cancelNotification(for: instances[index])
            save()
            print("[TimelineEngine] Completed instance: \(instances[index].title)")
            return
        }
        
        // If it's a ghost being completed, it should have been materialized first
        print("[TimelineEngine] Item not found for completion: \(id)")
    }
    
    /// Defer an item by a number of hours
    func `defer`(id: UUID, byHours hours: Int = 1) {
        if let index = instances.firstIndex(where: { $0.id == id }) {
            let current = instances[index].deferredUntil ?? instances[index].scheduledTime
            let newTime = calendar.date(byAdding: .hour, value: hours, to: current) ?? current
            
            instances[index].deferredUntil = newTime
            instances[index].deferredCount += 1
            
            // Reschedule notification
            cancelNotification(for: instances[index])
            scheduleNotification(for: instances[index])
            
            save()
            print("[TimelineEngine] Deferred: \(instances[index].title) to \(newTime)")
        }
    }
    
    /// Delete an instance or archive a master
    func delete(id: UUID) {
        // Try instances first
        if let index = instances.firstIndex(where: { $0.id == id }) {
            cancelNotification(for: instances[index])
            instances.remove(at: index)
            save()
            return
        }
        
        // Try masters (archive instead of delete)
        if let index = masters.firstIndex(where: { $0.id == id }) {
            masters[index].isArchived = true
            masters[index].effectiveEndDate = Date()
            save()
            return
        }
    }
    
    // MARK: - Persistence
    
    private func save() {
        if let mastersData = try? JSONEncoder().encode(masters) {
            UserDefaults.standard.set(mastersData, forKey: mastersKey)
        }
        if let instancesData = try? JSONEncoder().encode(instances) {
            UserDefaults.standard.set(instancesData, forKey: instancesKey)
        }
    }
    
    private func load() {
        if let mastersData = UserDefaults.standard.data(forKey: mastersKey),
           let decoded = try? JSONDecoder().decode([TimelineItem].self, from: mastersData) {
            masters = decoded
        }
        if let instancesData = UserDefaults.standard.data(forKey: instancesKey),
           let decoded = try? JSONDecoder().decode([TimelineItem].self, from: instancesData) {
            instances = decoded
        }
        
        #if DEBUG
        if masters.isEmpty && instances.isEmpty {
            injectMockData()
        }
        #endif
    }
    
    // MARK: - Notifications
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("[TimelineEngine] Notification permission granted")
            }
        }
    }
    
    private func scheduleNotification(for item: TimelineItem) {
        let content = UNMutableNotificationContent()
        content.title = "Neon"
        content.body = item.title
        content.sound = .default
        content.userInfo = ["itemId": item.id.uuidString]
        
        let triggerDate = item.effectiveTime
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: item.id.uuidString,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("[TimelineEngine] Notification error: \(error)")
            }
        }
    }
    
    private func cancelNotification(for item: TimelineItem) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [item.id.uuidString])
    }
    
    // MARK: - Debug / Mock Data
    
    func clearAll() {
        masters.removeAll()
        instances.removeAll()
        UserDefaults.standard.removeObject(forKey: mastersKey)
        UserDefaults.standard.removeObject(forKey: instancesKey)
        print("[TimelineEngine] All data cleared")
    }
    
    private func injectMockData() {
        let now = Date()
        
        // --- Masters (Recurring) ---
        
        // Daily habit
        let yoga = TimelineItem.master(
            title: "Morning Yoga",
            description: "20 min stretch routine",
            startTime: calendar.date(bySettingHour: 7, minute: 0, second: 0, of: now) ?? now,
            mustBeCompleted: false,
            recurrence: .daily()
        )
        
        // Critical daily task (pills)
        let meds = TimelineItem.master(
            title: "Take Medication",
            description: "Morning dose",
            priority: .critical,
            startTime: calendar.date(bySettingHour: 8, minute: 0, second: 0, of: now) ?? now,
            mustBeCompleted: true,
            recurrence: .daily()
        )
        
        // Weekly habit
        let review = TimelineItem.master(
            title: "Weekly Review",
            description: "Plan the week ahead",
            priority: .high,
            startTime: calendar.date(bySettingHour: 18, minute: 0, second: 0, of: now) ?? now,
            mustBeCompleted: false,
            recurrence: .weekly(on: [0], endCondition: .forever) // Sunday
        )
        
        masters = [yoga, meds, review]
        
        // --- Instances (Past completed + Future one-offs) ---
        
        // Completed yesterday
        var completed1 = TimelineItem.oneOff(
            title: "System Boot Protocol",
            description: "Initialization complete",
            category: "info",
            scheduledTime: now.addingTimeInterval(-3600 * 4)
        )
        completed1.isCompleted = true
        completed1.completedAt = now.addingTimeInterval(-3600 * 3)
        
        var completed2 = TimelineItem.oneOff(
            title: "Review PRs",
            priority: .high,
            scheduledTime: now.addingTimeInterval(-3600 * 2)
        )
        completed2.isCompleted = true
        completed2.completedAt = now.addingTimeInterval(-3600 * 1)
        
        // Future one-offs
        let future1 = TimelineItem.oneOff(
            title: "Upload Data Packet",
            priority: .high,
            scheduledTime: now.addingTimeInterval(3600 * 1)
        )
        
        let future2 = TimelineItem.oneOff(
            title: "Server Status Check",
            description: "All systems operational",
            category: "info",
            scheduledTime: now.addingTimeInterval(3600 * 2)
        )
        
        // Overdue debt item
        let overdueDebt = TimelineItem.oneOff(
            title: "Overdue Critical Task",
            priority: .critical,
            scheduledTime: now.addingTimeInterval(-3600 * 24), // Yesterday
            mustBeCompleted: true
        )
        
        instances = [completed1, completed2, future1, future2, overdueDebt]
        
        save()
        print("[TimelineEngine] Mock data injected: \(masters.count) masters, \(instances.count) instances")
    }
}
