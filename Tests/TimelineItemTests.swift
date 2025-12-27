import XCTest
@testable import NeonTracker

/// Unit tests for TimelineItem model
final class TimelineItemTests: XCTestCase {
    
    var calendar: Calendar!
    
    override func setUp() {
        super.setUp()
        calendar = Calendar.current
    }
    
    // MARK: - Helper Methods
    
    private func date(_ string: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.date(from: string) ?? Date()
    }
    
    // MARK: - Factory Method Tests
    
    func test_master_hasRecurrenceAndNoSeriesId() {
        let master = TimelineItem.master(
            title: "Daily Meditation",
            startTime: Date(),
            recurrence: .daily()
        )
        
        XCTAssertNotNil(master.recurrence)
        XCTAssertNil(master.seriesId)
        XCTAssertTrue(master.isMaster)
    }
    
    func test_master_calculatesEffectiveEndDateForUntil() {
        let endDate = date("2025-12-31 23:59")
        let master = TimelineItem.master(
            title: "Limited Task",
            startTime: Date(),
            recurrence: .daily(endCondition: .until(endDate))
        )
        
        XCTAssertNotNil(master.effectiveEndDate)
        XCTAssertEqual(master.effectiveEndDate, endDate)
    }
    
    func test_master_effectiveEndDateNilForForever() {
        let master = TimelineItem.master(
            title: "Forever Task",
            startTime: Date(),
            recurrence: .daily(endCondition: .forever)
        )
        
        XCTAssertNil(master.effectiveEndDate)
    }
    
    func test_ghost_hasSeriesIdLinkingToMaster() {
        let master = TimelineItem.master(
            title: "Parent Task",
            startTime: Date(),
            recurrence: .daily()
        )
        
        let ghost = TimelineItem.ghost(from: master, for: Date())
        
        XCTAssertEqual(ghost.seriesId, master.id)
        XCTAssertTrue(ghost.isInstance)
        XCTAssertFalse(ghost.isMaster)
    }
    
    func test_ghost_copiesPropertiesFromMaster() {
        let master = TimelineItem.master(
            title: "Test Task",
            description: "A description",
            priority: .high,
            category: "health",
            startTime: Date(),
            recurrence: .daily()
        )
        
        let ghost = TimelineItem.ghost(from: master, for: Date())
        
        XCTAssertEqual(ghost.title, master.title)
        XCTAssertEqual(ghost.description, master.description)
        XCTAssertEqual(ghost.priority, master.priority)
        XCTAssertEqual(ghost.category, master.category)
    }
    
    func test_ghost_hasNoRecurrence() {
        let master = TimelineItem.master(
            title: "Recurring",
            startTime: Date(),
            recurrence: .weekly()
        )
        
        let ghost = TimelineItem.ghost(from: master, for: Date())
        
        XCTAssertNil(ghost.recurrence)
    }
    
    func test_ghost_copiesRecurrenceDisplayText() {
        let master = TimelineItem.master(
            title: "Daily Task",
            startTime: Date(),
            recurrence: .daily()
        )
        
        let ghost = TimelineItem.ghost(from: master, for: Date())
        
        XCTAssertNotNil(ghost.recurrenceDisplayText)
        XCTAssertEqual(ghost.recurrenceDisplayText, master.recurrence?.displayText)
    }
    
    func test_oneOff_hasNoRecurrenceOrSeriesId() {
        let oneOff = TimelineItem.oneOff(
            title: "Single Task",
            scheduledTime: Date()
        )
        
        XCTAssertNil(oneOff.recurrence)
        XCTAssertNil(oneOff.seriesId)
        XCTAssertTrue(oneOff.isOneOff)
    }
    
    // MARK: - Computed Property Tests
    
    func test_isMaster_trueOnlyWhenHasRecurrenceAndNoSeriesId() {
        let master = TimelineItem.master(
            title: "Master",
            startTime: Date(),
            recurrence: .daily()
        )
        
        let oneOff = TimelineItem.oneOff(title: "OneOff", scheduledTime: Date())
        let ghost = TimelineItem.ghost(from: master, for: Date())
        
        XCTAssertTrue(master.isMaster)
        XCTAssertFalse(oneOff.isMaster)
        XCTAssertFalse(ghost.isMaster)
    }
    
    func test_isInstance_trueWhenHasSeriesId() {
        let master = TimelineItem.master(
            title: "Master",
            startTime: Date(),
            recurrence: .daily()
        )
        let ghost = TimelineItem.ghost(from: master, for: Date())
        
        XCTAssertTrue(ghost.isInstance)
        XCTAssertFalse(master.isInstance)
    }
    
    func test_isOneOff_trueWhenNoRecurrenceOrSeriesId() {
        let oneOff = TimelineItem.oneOff(title: "Single", scheduledTime: Date())
        let master = TimelineItem.master(title: "Master", startTime: Date(), recurrence: .daily())
        
        XCTAssertTrue(oneOff.isOneOff)
        XCTAssertFalse(master.isOneOff)
    }
    
    func test_isOverdue_trueWhenPastScheduledTimeAndNotCompleted() {
        let pastDate = calendar.date(byAdding: .hour, value: -2, to: Date())!
        var item = TimelineItem.oneOff(title: "Past Task", scheduledTime: pastDate)
        
        XCTAssertTrue(item.isOverdue)
        
        item.isCompleted = true
        XCTAssertFalse(item.isOverdue)
    }
    
    func test_isOverdue_falseWhenInFuture() {
        let futureDate = calendar.date(byAdding: .hour, value: 2, to: Date())!
        let item = TimelineItem.oneOff(title: "Future Task", scheduledTime: futureDate)
        
        XCTAssertFalse(item.isOverdue)
    }
    
    func test_isOverdue_usesDeferredUntilIfSet() {
        let pastDate = calendar.date(byAdding: .hour, value: -2, to: Date())!
        let futureDefer = calendar.date(byAdding: .hour, value: 2, to: Date())!
        
        var item = TimelineItem.oneOff(title: "Deferred", scheduledTime: pastDate)
        item.deferredUntil = futureDefer
        
        // Should not be overdue because deferredUntil is in the future
        XCTAssertFalse(item.isOverdue)
    }
    
    func test_isDeferred_trueWhenDeferredUntilSet() {
        var item = TimelineItem.oneOff(title: "Test", scheduledTime: Date())
        
        XCTAssertFalse(item.isDeferred)
        
        item.deferredUntil = Date().addingTimeInterval(3600)
        XCTAssertTrue(item.isDeferred)
    }
    
    func test_effectiveTime_usesDeferredUntilOverScheduledTime() {
        let scheduled = date("2025-01-01 09:00")
        let deferred = date("2025-01-01 11:00")
        
        var item = TimelineItem.oneOff(title: "Test", scheduledTime: scheduled)
        XCTAssertEqual(item.effectiveTime, scheduled)
        
        item.deferredUntil = deferred
        XCTAssertEqual(item.effectiveTime, deferred)
    }
    
    func test_recurrenceText_fallsBackCorrectly() {
        let master = TimelineItem.master(
            title: "Daily",
            startTime: Date(),
            recurrence: .daily()
        )
        
        XCTAssertNotNil(master.recurrenceText)
        XCTAssertEqual(master.recurrenceText, "Daily")
        
        let oneOff = TimelineItem.oneOff(title: "Single", scheduledTime: Date())
        XCTAssertNil(oneOff.recurrenceText)
    }
    
    // MARK: - Hashable/Equatable Tests
    
    func test_equality_basedOnId() {
        let id = UUID()
        let item1 = TimelineItem(id: id, title: "Task 1", scheduledTime: Date())
        let item2 = TimelineItem(id: id, title: "Task 2", scheduledTime: Date()) // Different title, same ID
        
        XCTAssertEqual(item1, item2)
    }
    
    func test_inequality_differentIds() {
        let item1 = TimelineItem(title: "Task", scheduledTime: Date())
        let item2 = TimelineItem(title: "Task", scheduledTime: Date())
        
        XCTAssertNotEqual(item1, item2) // Different IDs
    }
    
    func test_hashable_sameIdSameHash() {
        let id = UUID()
        let item1 = TimelineItem(id: id, title: "A", scheduledTime: Date())
        let item2 = TimelineItem(id: id, title: "B", scheduledTime: Date())
        
        var set = Set<TimelineItem>()
        set.insert(item1)
        set.insert(item2)
        
        XCTAssertEqual(set.count, 1) // Same ID means same hash, only one in set
    }
}
