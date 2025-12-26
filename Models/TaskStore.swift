import Foundation
import UserNotifications

// MARK: - Task Store

/// Manages user tasks and schedules notifications
@MainActor
class TaskStore: ObservableObject {
    static let shared = TaskStore()
    
    @Published var tasks: [UserTask] = []
    
    private let storageKey = "neurosync_tasks"
    
    private init() {
        #if DEBUG
        // Load mock data for development/simulator testing
        injectMockData()
        #else
        // Production: load saved tasks
        load()
        #endif
        requestNotificationPermission()
    }
    
    // MARK: - Add Tasks
    
    func addTask(_ task: UserTask) {
        // Duplicate check - skip if same title already exists in pending tasks
        let isDuplicate = tasks.contains { existing in
            existing.title.lowercased() == task.title.lowercased() &&
            (existing.status == .pending || existing.status == .recurring)
        }
        
        if isDuplicate {
            print("[TaskStore] Skipping duplicate task: \(task.title)")
            return
        }
        
        tasks.append(task)
        save()
        
        // Schedule notification if has time
        if task.scheduledTime != nil || task.dailyTime != nil || task.intervalMinutes != nil {
            scheduleNotification(for: task)
        }
    }
    
    func addTask(title: String, description: String? = nil, priority: String = "normal", category: String = "general") {
        let taskPriority = priorityFromString(priority)
        let task = UserTask(title: title, description: description, priority: taskPriority, category: category)
        addTask(task)
    }
    
    /// Add one-time scheduled reminder
    func addScheduledReminder(title: String, time: String, priority: String = "normal") {
        guard let date = parseTime(time) else {
            print("[TaskStore] Invalid time format: \(time)")
            return
        }
        
        let task = UserTask(
            title: title,
            priority: priorityFromString(priority),
            scheduledTime: date,
            category: "reminder"
        )
        addTask(task)
        print("[TaskStore] Scheduled reminder '\(title)' at \(time)")
    }
    
    /// Add daily recurring reminder
    func addDailyReminder(title: String, dailyTime: String, priority: String = "normal") {
        let task = UserTask(
            title: title,
            status: .recurring,
            priority: priorityFromString(priority),
            dailyTime: dailyTime,
            category: "reminder"
        )
        addTask(task)
        print("[TaskStore] Daily reminder '\(title)' at \(dailyTime)")
    }
    
    /// Add interval-based recurring reminder (e.g., every 60 minutes)
    func addIntervalReminder(title: String, intervalMinutes: Int, priority: String = "normal") {
        let task = UserTask(
            title: title,
            status: .recurring,
            priority: priorityFromString(priority),
            intervalMinutes: intervalMinutes,
            category: "reminder"
        )
        addTask(task)
        print("[TaskStore] Interval reminder '\(title)' every \(intervalMinutes) min")
    }
    
    // MARK: - Task Actions
    
    func completeTask(id: UUID) {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        
        if tasks[index].isRecurring {
            // For recurring tasks, just update lastTriggered
            tasks[index].lastTriggered = Date()
        } else {
            // For one-time tasks, mark as completed
            tasks[index].status = .completed
            tasks[index].completedAt = Date()
            cancelNotification(for: tasks[index])
        }
        save()
    }
    
    func cancelTask(id: UUID) {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        tasks[index].status = .cancelled
        cancelNotification(for: tasks[index])
        save()
    }
    
    func deferTask(id: UUID, by hours: Int = 1) {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        
        // Update scheduled time
        let currentScheduled = tasks[index].scheduledTime ?? Date()
        let newTime = Calendar.current.date(byAdding: .hour, value: hours, to: currentScheduled) ?? Date()
        tasks[index].scheduledTime = newTime
        
        // Re-schedule notification
        cancelNotification(for: tasks[index])
        scheduleNotification(for: tasks[index])
        
        tasks[index].deferredCount += 1
        
        save()
        print("[TaskStore] Deferred task '\(tasks[index].title)' by \(hours) hour(s) to \(newTime) (Count: \(tasks[index].deferredCount))")
    }
    
    func deleteTask(id: UUID) {
        if let task = tasks.first(where: { $0.id == id }) {
            cancelNotification(for: task)
        }
        tasks.removeAll { $0.id == id }
        save()
    }
    
    func pendingTasks() -> [UserTask] {
        tasks.filter { $0.status == .pending || $0.status == .recurring }
            .sorted { t1, t2 in
                // 1. ASAP tasks always first
                let t1IsAsap = (t1.category.lowercased() == "asap" || t1.category.lowercased() == "urgent")
                let t2IsAsap = (t2.category.lowercased() == "asap" || t2.category.lowercased() == "urgent")
                
                if t1IsAsap != t2IsAsap {
                    return t1IsAsap // True comes before False
                }
                
                // 2. Effective Time (Earliest first)
                let time1 = effectiveTime(for: t1)
                let time2 = effectiveTime(for: t2)
                
                if let s1 = time1, let s2 = time2 {
                    return s1 < s2
                }
                // Tasks with time come before tasks without time
                if (time1 != nil) != (time2 != nil) {
                    return time1 != nil
                }
                
                // 3. Priority (Higher first)
                return t1.priority > t2.priority
            }
    }
    
    private func effectiveTime(for task: UserTask) -> Date? {
        if let scheduled = task.scheduledTime {
            return scheduled
        }
        
        if let daily = task.dailyTime {
            // Calculate today's occurrence
            let parts = daily.split(separator: ":").compactMap { Int($0) }
            if parts.count == 2 {
                return Calendar.current.date(bySettingHour: parts[0], minute: parts[1], second: 0, of: Date())
            }
        }
        
        if let interval = task.intervalMinutes {
            let base = task.lastTriggered ?? task.createdAt
            return base.addingTimeInterval(TimeInterval(interval * 60))
        }
        
        return nil
    }
    
    func completedTasks(within hours: Int = 24) -> [UserTask] {
        let cutoff = Calendar.current.date(byAdding: .hour, value: -hours, to: Date()) ?? Date()
        return tasks
            .filter { $0.status == .completed && ($0.completedAt ?? Date.distantPast) > cutoff }
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }
    
    func upcomingReminders() -> [UserTask] {
        let now = Date()
        return tasks.filter { task in
            guard task.status != .completed && task.status != .cancelled else { return false }
            
            if let scheduled = task.scheduledTime {
                return scheduled > now
            }
            return task.isRecurring
        }.sorted { t1, t2 in
            (t1.scheduledTime ?? .distantFuture) < (t2.scheduledTime ?? .distantFuture)
        }
    }
    
    // MARK: - Notifications
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("[TaskStore] Notification permission granted")
            }
        }
    }
    
    private func scheduleNotification(for task: UserTask) {
        let content = UNMutableNotificationContent()
        content.title = "NeuroSync"
        content.body = task.title
        content.sound = .default
        content.userInfo = ["taskId": task.id.uuidString]
        
        var trigger: UNNotificationTrigger?
        
        if let scheduledTime = task.scheduledTime {
            // One-time at specific date
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: scheduledTime)
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            
        } else if let dailyTime = task.dailyTime {
            // Daily at specific time
            let parts = dailyTime.split(separator: ":").compactMap { Int($0) }
            if parts.count == 2 {
                var components = DateComponents()
                components.hour = parts[0]
                components.minute = parts[1]
                trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            }
            
        } else if let interval = task.intervalMinutes {
            // Interval-based (minimum 1 minute for iOS)
            let seconds = max(60, TimeInterval(interval * 60))
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: true)
        }
        
        guard let notificationTrigger = trigger else { return }
        
        let request = UNNotificationRequest(
            identifier: task.id.uuidString,
            content: content,
            trigger: notificationTrigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("[TaskStore] Notification error: \(error)")
            } else {
                print("[TaskStore] Notification scheduled for: \(task.title)")
            }
        }
    }
    
    private func cancelNotification(for task: UserTask) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [task.id.uuidString])
    }
    
    // MARK: - Helpers
    
    private func priorityFromString(_ str: String) -> TaskPriority {
        switch str.lowercased() {
        case "urgent": return .urgent
        case "high": return .high
        case "low": return .low
        default: return .normal
        }
    }
    
    private func parseTime(_ timeString: String) -> Date? {
        let parts = timeString.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return nil }
        
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = parts[0]
        components.minute = parts[1]
        
        guard let date = Calendar.current.date(from: components) else { return nil }
        
        // If time is in the past today, schedule for tomorrow
        if date < Date() {
            return Calendar.current.date(byAdding: .day, value: 1, to: date)
        }
        return date
    }
    
    private func save() {
        if let data = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    private func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([UserTask].self, from: data) {
            tasks = decoded
        }
    }

    
    // MARK: - Debug / Dev Tools
    
    func clearAll() {
        tasks.removeAll()
        UserDefaults.standard.removeObject(forKey: storageKey)
        print("[TaskStore] All data cleared")
    }
    
    func injectMockData() {
        clearAll()
        let now = Date()
        
        // --- PAST RAIL (Completed) ---
        
        // 1. Standard Task (Completed)
        var p1 = UserTask(title: "Morning Protocol", status: .completed, category: "task")
        p1.completedAt = now.addingTimeInterval(-3600 * 6)
        
        // 2. Reminder (Completed Instance)
        var p2 = UserTask(title: "Physical Calibration", status: .completed, intervalMinutes: 120, category: "reminder")
        p2.completedAt = now.addingTimeInterval(-3600 * 5)
        
        // 3. Info (Completed)
        var p3 = UserTask(title: "System Boot v3.0", description: "Kernel initialized.", status: .completed, category: "info")
        p3.completedAt = now.addingTimeInterval(-3600 * 4)
        
        // 4. Insight (Completed)
        var p4 = UserTask(title: "Optimized Workflow", description: "Productivity up 15%.", status: .completed, category: "insight")
        p4.completedAt = now.addingTimeInterval(-3600 * 3)

        // 5. Task (Completed)
        var p5 = UserTask(title: "Review PRs", description: "Merged 3 features.", status: .completed, category: "task")
        p5.completedAt = now.addingTimeInterval(-3600 * 2)

        // 6. Reminder (Completed)
        var p6 = UserTask(title: "Drink Water", description: "Hydration check.", status: .completed, category: "reminder")
        p6.completedAt = now.addingTimeInterval(-3600 * 1)


        // --- FUTURE RAIL (Pending) ---
        
        // 1. Standard Task (Pending)
        let f1 = UserTask(title: "Upload Data", priority: .high, scheduledTime: now.addingTimeInterval(3600), category: "task")
        
        // 2. Reminder (Pending)
        let f2 = UserTask(title: "Hourly Sync", intervalMinutes: 60, category: "reminder")
        
        // 3. Info (Pending)
        let f3 = UserTask(title: "Server Status", description: "All systems operational.", scheduledTime: now.addingTimeInterval(3600 * 2), category: "info")
        
        // 4. Insight (Pending)
        let f4 = UserTask(title: "Sleep Pattern", description: "Consider earlier bedtime.", scheduledTime: now.addingTimeInterval(3600 * 3), category: "insight")
        
        // 5. Task (Pending)
        let f5 = UserTask(title: "Deploy Update", description: "Install patch v3.1.", scheduledTime: now.addingTimeInterval(3600 * 4), category: "task")
        
        // 6. Reminder (Pending)
        let f6 = UserTask(title: "Take Meds", description: "Evening dose.", scheduledTime: now.addingTimeInterval(3600 * 5), category: "reminder")
        
        tasks = [p1, p2, p3, p4, p5, p6, f1, f2, f3, f4, f5, f6]
        save()
        print("[TaskStore] Mock data injected: 6 Past, 6 Future (Task, Reminder, Info, Insight)")
    }
}
