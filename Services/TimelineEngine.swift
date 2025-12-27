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
    private let weekStartKey = "neon_week_start_offset"
    
    @Published var weekStartOffset: Int {
        didSet {
            UserDefaults.standard.set(weekStartOffset, forKey: weekStartKey)
            updateCalendar()
        }
    }
    
    // Public calendar that respects the user's week start setting
    private(set) var calendar: Calendar
    
    // MARK: - Initialization
    
    private init() {
        let offset = UserDefaults.standard.object(forKey: weekStartKey) as? Int ?? {
            let weekday = Locale.current.calendar.firstWeekday
            return (weekday - 2 + 7) % 7
        }()
        var cal = Calendar.current
        cal.timeZone = TimeZone.current
        cal.firstWeekday = ((offset + 1) % 7) + 1
        self.calendar = cal
        
        self.weekStartOffset = offset
        
        load()
        materializeToday() // Check for today's ghosts immediately
        requestNotificationPermission()
        
        // Listen for significant time changes (midnight)
        NotificationCenter.default.addObserver(forName: .NSCalendarDayChanged, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                self?.materializeToday()
            }
        }
    }
    
    private func updateCalendar() {
        var cal = Calendar.current
        cal.timeZone = TimeZone.current
        cal.firstWeekday = ((weekStartOffset + 1) % 7) + 1
        self.calendar = cal
        // Re-process views if necessary, but @Published calendar change should trigger updates
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
        
        // 4. Sort: AI first, then by time
        return result.sorted { item1, item2 in
            // AI always first
            if item1.priority == .ai && item2.priority != .ai { return true }
            if item2.priority == .ai && item1.priority != .ai { return false }
            
            // Everything else by effective time (including overdue items)
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
    
    // MARK: - Time Debt (Removed)
    
    // Debt logic has been removed as per user request. Overdue items stay in the past.

    
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
        
        // Immediately materialize if it triggers today
        materializeToday()
    }
    
    // MARK: - Auto-Materialization
    
    /// Ensures that all recurring tasks for Today are real instances, not ghosts.
    func materializeToday() {
        let today = Date()
        let dayStart = calendar.startOfDay(for: today)
        
        // 1. Fetch existing instance seriesIDs for today
        // (We only care about recurring masters being materialized)
        let todayInstances = instances.filter {
            let instanceDay = calendar.startOfDay(for: $0.effectiveTime)
            return instanceDay == dayStart && !$0.isArchived && $0.seriesId != nil
        }
        let existingSeriesIds = Set(todayInstances.compactMap { $0.seriesId })
        
        // 2. Project ghosts for today
        let ghosts = projectGhosts(for: today, excluding: existingSeriesIds)
        
        if !ghosts.isEmpty {
            print("[TimelineEngine] Materializing \(ghosts.count) ghosts for Today")
            for ghost in ghosts {
                 instances.append(ghost)
                 if ghost.effectiveTime > Date() {
                     scheduleNotification(for: ghost)
                 }
            }
            save()
        }
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
    
    /// Update an existing item
    func update(_ item: TimelineItem) {
        // Update instances
        if let index = instances.firstIndex(where: { $0.id == item.id }) {
            instances[index] = item
            cancelNotification(for: item)
            if !item.isCompleted && item.effectiveTime > Date() {
                scheduleNotification(for: item)
            }
            save()
            print("[TimelineEngine] Updated instance: \(item.title)")
            return
        }
        
        // Update masters
        if let index = masters.firstIndex(where: { $0.id == item.id }) {
            masters[index] = item
            save()
            print("[TimelineEngine] Updated master: \(item.title)")
            return
        }
        
        print("[TimelineEngine] Item not found for update: \(item.id)")
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
    
    /// Skip an item (mark as completed and skipped)
    func skip(id: UUID) {
        // Check instances first
        if let index = instances.firstIndex(where: { $0.id == id }) {
            instances[index].isCompleted = true
            instances[index].isSkipped = true
            instances[index].completedAt = Date()
            cancelNotification(for: instances[index])
            save()
            print("[TimelineEngine] Skipped instance: \(instances[index].title)")
            return
        }
        
        print("[TimelineEngine] Item not found for skipping: \(id)")
    }
    
    /// Defer an item by a number of minutes
    func `defer`(id: UUID, byMinutes minutes: Int = 60) {
        if let index = instances.firstIndex(where: { $0.id == id }) {
            let current = instances[index].deferredUntil ?? instances[index].scheduledTime
            
            // If overdue (current < Now), defer relative to Now
            // If future (current > Now), defer relative to scheduled time
            // We strip seconds to keep it clean (and avoid edge case where Date() is slightly ahead)
            let now = Date()
            let baseTime = current < now ? now : current
            
            let newTime = calendar.date(byAdding: .minute, value: minutes, to: baseTime) ?? baseTime
            
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
            recurrence: .daily()
        )
        
        // Critical daily task (pills)
        let meds = TimelineItem.master(
            title: "Take Medication",
            description: "Morning dose",
            priority: .high,
            startTime: calendar.date(bySettingHour: 8, minute: 0, second: 0, of: now) ?? now,
            recurrence: .daily()
        )
        
        // Weekly habit
        let review = TimelineItem.master(
            title: "Weekly Review",
            description: "Plan the week ahead",
            priority: .high,
            startTime: calendar.date(bySettingHour: 18, minute: 0, second: 0, of: now) ?? now,
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
            priority: .high,
            scheduledTime: now.addingTimeInterval(-3600 * 24) // Yesterday
        )
        
        // AI Insight - Scheduling conflict
        let aiInsight = TimelineItem.oneOff(
            title: "Schedule Conflict Detected",
            description: "Upload Data Packet overlaps with Server Status Check. Consider moving one task by 30 minutes.",
            priority: .ai,
            scheduledTime: now.addingTimeInterval(3600 * 1.5)
        )
        
        // Low priority task
        let lowPriority = TimelineItem.oneOff(
            title: "Read Tech Article",
            description: "Optional: New Swift features overview",
            priority: .low,
            scheduledTime: now.addingTimeInterval(3600 * 6)
        )
        
        instances = [completed1, completed2, future1, future2, overdueDebt, aiInsight, lowPriority]
        
        save()
        print("[TimelineEngine] Mock data injected: \(masters.count) masters, \(instances.count) instances")
    }
}
