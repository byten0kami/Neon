import SwiftUI

struct MonthCalendarView: View {
    @Binding var isPresented: Bool
    @StateObject private var engine = TimelineEngine.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    
    @Binding var currentMonth: Date
    @Binding var selectedDate: Date
    
    // Grid configuration
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    // Derived dynamically from engine
    private var calendar: Calendar { engine.calendar }
    
    // Dynamic days of week derived from calendar.firstWeekday
    private var daysOfWeek: [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let firstWeekdayIndex = calendar.firstWeekday - 1 // 1-based to 0-based
        // Rotate symbols so the start day is first
        return Array(symbols.suffix(from: firstWeekdayIndex) + symbols.prefix(upTo: firstWeekdayIndex))
    }
    
    // MARK: - Computed Properties
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: currentMonth).uppercased()
    }
    
    private var daysInMonth: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else { return [] }
        
        let monthStart = monthInterval.start
        let monthEnd = monthInterval.end
        
        // Find the first day of the week for the month start
        let weekday = calendar.component(.weekday, from: monthStart)
        
        // Calculate offset (how many days to pad before the 1st)
        let firstWeekday = calendar.firstWeekday
        let offset = ((weekday - firstWeekday) + 7) % 7
        
        var dates: [Date] = []
        
        // Add padding days from previous month
        if let startPadding = calendar.date(byAdding: .day, value: -offset, to: monthStart) {
            var currentDate = startPadding
            // Generate until we reach the end of the 6-row grid (42 days) to keep UI stable
            
            while currentDate < monthEnd || dates.count < 42 {
                dates.append(currentDate)
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
            }
        }
        
        return dates
    }
    
    private var selectedDayTasks: [TimelineItem] {
        engine.items(for: selectedDate)
            .filter { $0.priority != .ai }
            .sorted { $0.effectiveTime < $1.effectiveTime }
    }
    
    // MARK: - Actions
    
    private func changeMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = newMonth
        }
    }
    
    private func goToToday() {
        let now = Date()
        currentMonth = now
        selectedDate = now
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Calendar Header (Inside Frame)
            HStack {
                // Month Navigation
                HStack(spacing: 16) {
                    Button(action: { changeMonth(by: -1) }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                    }
                    
                    Text(monthYearString)
                        .font(.custom(DesignSystem.displayFont, size: 20))
                        .tracking(2)
                    
                    Button(action: { changeMonth(by: 1) }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .bold))
                    }
                }
                .foregroundColor(themeManager.currentTheme.mainAccent)
                
                Spacer()
                
                // Controls Row: Today + Close
                HStack(spacing: 12) {
                    // TODAY Button
                    Button(action: goToToday) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.counterclockwise")
                            Text("TODAY")
                        }
                        .font(.custom(DesignSystem.monoFont, size: 12))
                        .foregroundColor(themeManager.currentTheme.mainAccent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(themeManager.currentTheme.mainAccent, lineWidth: 1)
                        )
                    }
                    
                    // CLOSE Button
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark")
                            .foregroundColor(DesignSystem.red)
                            .font(.system(size: 20))
                            .shadow(color: DesignSystem.red.opacity(0.5), radius: 2)
                    }
                }
            }
            .padding(16)
            .background(DesignSystem.backgroundSecondary.opacity(0.3))
            
            // Days of Week Header
            // Use LazyVGrid to align perfectly with the calendar grid
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(Array(daysOfWeek.enumerated()), id: \.offset) { _, day in
                    Text(day)
                        .font(.custom(DesignSystem.monoFont, size: 12))
                        .foregroundColor(DesignSystem.slate500)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 12)
            
            // Calendar Grid
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(daysInMonth, id: \.self) { date in
                    DayCell(
                        date: date,
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                        isCurrentMonth: calendar.isDate(date, equalTo: currentMonth, toGranularity: .month),
                        hasItems: !engine.items(for: date).isEmpty,
                        accentColor: themeManager.currentTheme.mainAccent
                    )
                    .onTapGesture {
                        selectedDate = date
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
            .drawingGroup() // Fix: flatten the grid to prevent independent animation of numbers
            
            Divider()
                .background(DesignSystem.slate800)
            
            // Task List for Selected Day
            ScrollView {
                VStack(spacing: 0) {
                    if selectedDayTasks.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "calendar.badge.clock")
                                .font(.system(size: 40))
                                .foregroundColor(DesignSystem.slate700)
                            Text("NO OPERATIONS SCHEDULED")
                                .font(.custom(DesignSystem.monoFont, size: 14))
                                .foregroundColor(DesignSystem.slate500)
                                .tracking(1)
                        }
                        .padding(.top, 60)
                    } else {
                        ForEach(selectedDayTasks) { item in
                            TaskRow(item: item)
                                .padding(.horizontal)
                                .padding(.vertical, 12)
                            
                            Divider()
                                .background(DesignSystem.slate800.opacity(0.5))
                                .padding(.leading, 16)
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(DesignSystem.backgroundSecondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(CardBackground(accentColor: themeManager.currentTheme.mainAccent))
        .padding(.horizontal, 8)
        .padding(.top, 8)  // Cover status header area
        .padding(.bottom, 90)  // Space for tab bar (matches chat panel)
        .compositingGroup() // Ensure whole view transitions as one
        .gesture(
            DragGesture()
                .onEnded { value in
                    // Swipe down to close (positive translation.height)
                    if value.translation.height > 50 {
                        withAnimation {
                            isPresented = false
                        }
                    }
                }
        )
    }
}

// MARK: - Day Cell

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isCurrentMonth: Bool
    let hasItems: Bool
    let accentColor: Color
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(calendar.component(.day, from: date))")
                .font(.custom(
                    DesignSystem.displayFont, // Use displayFont for Neon numbers
                    size: 14
                ))
                .foregroundColor(textColor)
                .frame(width: 36, height: 36)
                .background(
                    ZStack {
                        if isSelected {
                            Circle()
                                .stroke(accentColor, lineWidth: 1)
                                .background(Circle().fill(accentColor.opacity(0.2)))
                                .shadow(color: accentColor.opacity(0.5), radius: 4)
                        }
                    }
                )
            
            // Indicator dot
            Circle()
                .fill(hasItems ? (isSelected ? accentColor : DesignSystem.purple) : Color.clear)
                .frame(width: 4, height: 4)
                .shadow(color: hasItems ? DesignSystem.purple.opacity(0.5) : .clear, radius: 2)
        }
        .frame(height: 44)
        .opacity(isCurrentMonth ? 1 : 0.3)
    }
    
    private var textColor: Color {
        if isSelected {
            return .white
        } else if isCurrentMonth {
            return .white
        } else {
            return DesignSystem.slate600
        }
    }
}
