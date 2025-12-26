import XCTest
@testable import NeonTracker

/// Unit tests for TimelineEngine (TDD)
/// These tests are written BEFORE implementation to drive development
final class TimelineEngineTests: XCTestCase {
    
    var engine: TimelineEngine!
    var calendar: Calendar!
    
    override func setUp() {
        super.setUp()
        calendar = Calendar.current
        // Engine will be initialized when implemented
    }
    
    override func tearDown() {
        engine = nil
        super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    private func date(_ string: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.date(from: string) ?? Date()
    }
    
    private func dateTime(_ string: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.date(from: string) ?? Date()
    }
    
    // MARK: - The Sieve Tests
    
    /// Masters with expired endCondition should be filtered out
    func test_sieve_filtersExpiredMasters() async throws {
        // Given: A master that ended yesterday
        let master = TimelineItem.master(
            title: "Old Habit",
            startTime: date("2024-01-01"),
            recurrence: .daily(endCondition: .until(date("2024-12-31")))
        )
        
        // When: We query for today (2025-12-26)
        // Then: The master should NOT appear (it's expired)
        
        // TODO: Implement when TimelineEngine is created
        // let items = await engine.items(for: date("2025-12-26"))
        // XCTAssertFalse(items.contains { $0.seriesId == master.id })
    }
    
    /// Masters with .forever endCondition should always be included
    func test_sieve_includesForeverMasters() async throws {
        // Given: A master with forever recurrence
        let master = TimelineItem.master(
            title: "Daily Yoga",
            startTime: date("2024-01-01"),
            recurrence: .daily(endCondition: .forever)
        )
        
        // When: We query for any future date (2050)
        // Then: The master should project a ghost
        
        // TODO: Implement when TimelineEngine is created
        // let items = await engine.items(for: date("2050-01-01"))
        // XCTAssertTrue(items.contains { $0.title == "Daily Yoga" })
    }
    
    /// Masters that haven't started yet should be excluded
    func test_sieve_excludesFutureMasters() async throws {
        // Given: A master that starts next year
        let master = TimelineItem.master(
            title: "Future Habit",
            startTime: date("2026-01-01"),
            recurrence: .daily()
        )
        
        // When: We query for today (2025-12-26)
        // Then: The master should NOT appear (hasn't started)
        
        // TODO: Implement when TimelineEngine is created
        // let items = await engine.items(for: date("2025-12-26"))
        // XCTAssertFalse(items.contains { $0.title == "Future Habit" })
    }
    
    // MARK: - Ghost Projection Tests
    
    /// Active masters should create ghost projections for matching dates
    func test_ghostProjection_createsGhostForActiveRule() async throws {
        // Given: A daily master starting today
        let today = Date()
        let master = TimelineItem.master(
            title: "Morning Pills",
            startTime: today,
            recurrence: .daily()
        )
        
        // When: We query for today
        // Then: A ghost should be created with seriesId = master.id
        
        // TODO: Implement when TimelineEngine is created
        // let items = await engine.items(for: today)
        // let ghost = items.first { $0.seriesId == master.id }
        // XCTAssertNotNil(ghost)
        // XCTAssertEqual(ghost?.title, "Morning Pills")
    }
    
    /// If a real instance exists, no ghost should be created
    func test_ghostProjection_skipsWhenInstanceExists() async throws {
        // Given: A master AND a saved instance for the same date
        let today = Date()
        let master = TimelineItem.master(
            title: "Daily Task",
            startTime: today,
            recurrence: .daily()
        )
        
        let instance = TimelineItem(
            seriesId: master.id,
            title: "Daily Task",
            scheduledTime: today,
            isCompleted: true
        )
        
        // When: We query for today
        // Then: Only the real instance should appear, no ghost
        
        // TODO: Implement when TimelineEngine is created
        // let items = await engine.items(for: today)
        // let matching = items.filter { $0.title == "Daily Task" }
        // XCTAssertEqual(matching.count, 1)
        // XCTAssertEqual(matching.first?.id, instance.id)
    }
    
    /// Ghost should have correct scheduled time for the projected date
    func test_ghostProjection_calculatesCorrectDate() async throws {
        // Given: A daily master at 09:00
        let startDate = dateTime("2025-01-01 09:00")
        let master = TimelineItem.master(
            title: "9 AM Task",
            startTime: startDate,
            recurrence: .daily()
        )
        
        // When: We query for 2025-06-15
        // Then: Ghost should have scheduledTime on 2025-06-15 at 09:00
        
        // TODO: Implement when TimelineEngine is created
        // let items = await engine.items(for: date("2025-06-15"))
        // let ghost = items.first { $0.seriesId == master.id }
        // let ghostHour = calendar.component(.hour, from: ghost!.scheduledTime)
        // XCTAssertEqual(ghostHour, 9)
    }
    
    // MARK: - Time Debt Tests
    
    /// mustBeCompleted items from the past should appear on Today
    func test_debt_mustBeCompletedAppearsOnToday() async throws {
        // Given: An overdue item with mustBeCompleted = true
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
        var item = TimelineItem.oneOff(
            title: "Missed Pills",
            scheduledTime: yesterday,
            mustBeCompleted: true
        )
        
        // When: We query for Today
        // Then: The item should appear in the debt list
        
        // TODO: Implement when TimelineEngine is created
        // let items = await engine.items(for: Date())
        // XCTAssertTrue(items.contains { $0.title == "Missed Pills" })
    }
    
    /// Regular missed items should stay in the past
    func test_debt_regularMissedStaysInPast() async throws {
        // Given: An overdue item with mustBeCompleted = false
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
        var item = TimelineItem.oneOff(
            title: "Missed Yoga",
            scheduledTime: yesterday,
            mustBeCompleted: false
        )
        
        // When: We query for Today
        // Then: The item should NOT appear (stays in history)
        
        // TODO: Implement when TimelineEngine is created
        // let items = await engine.items(for: Date())
        // XCTAssertFalse(items.contains { $0.title == "Missed Yoga" })
    }
    
    /// Completed debt items should not appear on Today
    func test_debt_completedDebtDisappears() async throws {
        // Given: A completed item that WAS in debt
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
        var item = TimelineItem.oneOff(
            title: "Completed Pills",
            scheduledTime: yesterday,
            mustBeCompleted: true
        )
        item.isCompleted = true
        item.completedAt = Date()
        
        // When: We query for Today
        // Then: The item should NOT appear (debt cleared)
        
        // TODO: Implement when TimelineEngine is created
        // let items = await engine.items(for: Date())
        // XCTAssertFalse(items.contains { $0.title == "Completed Pills" })
    }
    
    // MARK: - Materialization Tests
    
    /// Materializing a ghost should save it as a real instance
    func test_materialize_savesGhostAsInstance() async throws {
        // Given: A ghost item (in-memory)
        let master = TimelineItem.master(
            title: "Daily Habit",
            startTime: Date(),
            recurrence: .daily()
        )
        let ghost = TimelineItem.ghost(from: master, for: Date())
        
        // When: We materialize the ghost
        // Then: It should be saved to the instances store
        
        // TODO: Implement when TimelineEngine is created
        // await engine.materialize(ghost)
        // XCTAssertTrue(engine.instances.contains { $0.id == ghost.id })
    }
    
    /// Materialized instance should have seriesId linking to master
    func test_materialize_linksToMasterWithSeriesId() async throws {
        // Given: A ghost from a master
        let master = TimelineItem.master(
            title: "Track Origin",
            startTime: Date(),
            recurrence: .daily()
        )
        let ghost = TimelineItem.ghost(from: master, for: Date())
        
        // When: We materialize
        // Then: seriesId should equal master.id
        
        XCTAssertEqual(ghost.seriesId, master.id)
        
        // TODO: After materialization, verify persistence
        // await engine.materialize(ghost)
        // let saved = engine.instances.first { $0.id == ghost.id }
        // XCTAssertEqual(saved?.seriesId, master.id)
    }
}

// MARK: - RecurrenceRule Tests

final class RecurrenceRuleTests: XCTestCase {
    
    var calendar: Calendar!
    
    override func setUp() {
        super.setUp()
        calendar = Calendar.current
    }
    
    private func date(_ string: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.date(from: string) ?? Date()
    }
    
    // MARK: - Trigger Tests
    
    func test_daily_triggersEveryDay() {
        let rule = RecurrenceRule.daily()
        let start = date("2025-01-01")
        
        XCTAssertTrue(rule.triggers(on: date("2025-01-01"), startDate: start))
        XCTAssertTrue(rule.triggers(on: date("2025-01-02"), startDate: start))
        XCTAssertTrue(rule.triggers(on: date("2025-01-10"), startDate: start))
    }
    
    func test_daily_intervalSkipsDays() {
        let rule = RecurrenceRule.daily(interval: 2)
        let start = date("2025-01-01")
        
        XCTAssertTrue(rule.triggers(on: date("2025-01-01"), startDate: start))  // Day 0
        XCTAssertFalse(rule.triggers(on: date("2025-01-02"), startDate: start)) // Day 1
        XCTAssertTrue(rule.triggers(on: date("2025-01-03"), startDate: start))  // Day 2
        XCTAssertFalse(rule.triggers(on: date("2025-01-04"), startDate: start)) // Day 3
        XCTAssertTrue(rule.triggers(on: date("2025-01-05"), startDate: start))  // Day 4
    }
    
    func test_daily_beforeStartReturnsFalse() {
        let rule = RecurrenceRule.daily()
        let start = date("2025-06-01")
        
        XCTAssertFalse(rule.triggers(on: date("2025-05-31"), startDate: start))
    }
    
    func test_endCondition_untilStopsAfterDate() {
        let rule = RecurrenceRule.daily(endCondition: .until(date("2025-01-05")))
        let start = date("2025-01-01")
        
        XCTAssertTrue(rule.triggers(on: date("2025-01-03"), startDate: start))
        XCTAssertTrue(rule.triggers(on: date("2025-01-05"), startDate: start))
        XCTAssertFalse(rule.triggers(on: date("2025-01-06"), startDate: start))
    }
    
    func test_finiteCourse_createsCountEndCondition() {
        let rule = RecurrenceRule.finiteCourse(count: 5)
        
        if case .count(let n) = rule.endCondition {
            XCTAssertEqual(n, 5)
        } else {
            XCTFail("Expected .count end condition")
        }
    }
}
