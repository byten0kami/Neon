import Foundation
import Combine

// Types moved to Models/Events/

/// Manages the daily schedule of events
@MainActor
class ScheduleStore: ObservableObject {
    static let shared = ScheduleStore()
    
    @Published var todayEvents: [ScheduledEvent] = []
    @Published var activeTimers: [ActiveTimer] = []
    
    private let eventsKey = "neurosync_today_events"
    
    private init() {
        loadTodayEvents()
    }
    
    func addEvent(_ event: ScheduledEvent) {
        todayEvents.append(event)
        sortEvents()
        save()
    }
    
    func completeEvent(id: UUID) {
        guard let index = todayEvents.firstIndex(where: { $0.id == id }) else { return }
        var event = todayEvents[index]
        event.status = .completed
        todayEvents[index] = event
        save()
        
        Task {
            await AIBrain.shared.onEventCompleted(event)
        }
    }
    
    func skipEvent(id: UUID) {
        guard let index = todayEvents.firstIndex(where: { $0.id == id }) else { return }
        var event = todayEvents[index]
        event.status = .skipped
        todayEvents[index] = event
        save()
    }
    
    func rescheduleEvent(id: UUID, newTime: Date) {
        guard let index = todayEvents.firstIndex(where: { $0.id == id }) else { return }
        var event = todayEvents[index]
        event.scheduledTime = newTime
        event.status = .rescheduled
        todayEvents[index] = event
        sortEvents()
        save()
    }
    
    func startTimer(name: String, durationMinutes: Int) {
        let timer = ActiveTimer(
            id: UUID(),
            name: name,
            startTime: Date(),
            durationMinutes: durationMinutes
        )
        activeTimers.append(timer)
    }
    
    func cancelTimer(id: UUID) {
        activeTimers.removeAll { $0.id == id }
    }
    
    func upcomingEvents(limit: Int = 5) -> [ScheduledEvent] {
        let now = Date()
        return todayEvents
            .filter { $0.status == .pending && ($0.scheduledTime ?? .distantFuture) > now }
            .sorted { ($0.scheduledTime ?? .distantFuture) < ($1.scheduledTime ?? .distantFuture) }
            .prefix(limit)
            .map { $0 }
    }
    
    func nextEvent() -> ScheduledEvent? {
        upcomingEvents(limit: 1).first
    }
    
    func clearAllEvents() {
        todayEvents = []
        activeTimers = []
        save()
    }
    
    private func sortEvents() {
        todayEvents.sort { e1, e2 in
            guard let t1 = e1.scheduledTime, let t2 = e2.scheduledTime else {
                return e1.priority > e2.priority
            }
            return t1 < t2
        }
    }
    
    private func loadTodayEvents() {
        if let data = UserDefaults.standard.data(forKey: eventsKey),
           let events = try? JSONDecoder().decode([ScheduledEvent].self, from: data) {
            self.todayEvents = events
        }
    }
    
    private func save() {
        if let data = try? JSONEncoder().encode(todayEvents) {
            UserDefaults.standard.set(data, forKey: eventsKey)
        }
    }
}

