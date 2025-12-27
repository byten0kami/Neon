import SwiftUI

struct MonthCalendarView: View {
    @Binding var isPresented: Bool
    @StateObject private var engine = TimelineEngine.shared
    
    @State private var currentMonth: Date = Date()
    @State private var selectedDate: Date = Date()
    
    // Grid configuration
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    private let calendar = Calendar.current
    private let daysOfWeek = ["S", "M", "T", "W", "T", "F", "S"]
    
    // MARK: - Computed Properties
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: currentMonth)
    }
    
    private var daysInMonth: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else { return [] }
        
        let monthStart = monthInterval.start
        let monthEnd = monthInterval.end
        
        // Find the first day of the week for the month start
        let weekday = calendar.component(.weekday, from: monthStart)
        let offset = weekday - 1 // 1-based (Sunday is 1)
        
        var dates: [Date] = []
        
        // Add padding days from previous month
        if let startPadding = calendar.date(byAdding: .day, value: -offset, to: monthStart) {
            // Helper to generate dates
            var currentDate = startPadding
            // Generate until we reach the end of the 6-row grid (42 days) to keep UI stable
            
            while currentDate < monthEnd || calendar.component(.weekday, from: currentDate) != 1 {
                dates.append(currentDate)
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
            }
        }
        
        return dates
    }
    
    private var selectedDayTasks: [TimelineItem] {
        engine.items(for: selectedDate)
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Background
            DesignSystem.backgroundPrimary.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Header (Neon Style)
                HStack {
                    // Month Navigation & Title
                    HStack(spacing: 16) {
                        Button(action: { changeMonth(by: -1) }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .bold))
                        }
                        
                        Text(monthYearString.uppercased())
                            .font(.custom(DesignSystem.displayFont, size: 24))
                            .tracking(2)
                        
                        Button(action: { changeMonth(by: 1) }) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 16, weight: .bold))
                        }
                    }
                    .foregroundColor(DesignSystem.cyan)
                    
                    Spacer()
                    
                    // Close Button (Aligned with StatusHeader position)
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark.circle.fill") // Or just calendar if acting as toggle
                            .font(.system(size: 24))
                            .foregroundColor(DesignSystem.red)
                            .shadow(color: DesignSystem.red.opacity(0.5), radius: 4)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
                .background(DesignSystem.backgroundSecondary.opacity(0.8))
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(DesignSystem.cyan.opacity(0.3)),
                    alignment: .bottom
                )
                
                // Days of Week Header
                HStack {
                    ForEach(Array(daysOfWeek.enumerated()), id: \.offset) { _, day in
                        Text(day)
                            .font(.custom(DesignSystem.monoFont, size: 12))
                            .foregroundColor(DesignSystem.slate500)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.vertical, 12)
                
                // Calendar Grid
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(daysInMonth, id: \.self) { date in
                        DayCell(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isCurrentMonth: calendar.isDate(date, equalTo: currentMonth, toGranularity: .month),
                            hasItems: !engine.items(for: date).isEmpty
                        )
                        .onTapGesture {
                            selectedDate = date
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 16)
                
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
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    // Swipe up to close (negative translation.height)
                    if value.translation.height < -50 {
                        isPresented = false
                    }
                }
        )
    }
    
    // MARK: - Actions
    
    private func changeMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = newMonth
        }
    }
}

// MARK: - Day Cell

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isCurrentMonth: Bool
    let hasItems: Bool
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(calendar.component(.day, from: date))")
                .font(.custom(
                    isSelected ? DesignSystem.displayFont : DesignSystem.monoFont,
                    size: 14
                ))
                .foregroundColor(textColor)
                .frame(width: 36, height: 36)
                .background(
                    ZStack {
                        if isSelected {
                            Circle()
                                .stroke(DesignSystem.cyan, lineWidth: 1)
                                .background(Circle().fill(DesignSystem.cyan.opacity(0.2)))
                                .shadow(color: DesignSystem.cyan.opacity(0.5), radius: 4)
                        }
                    }
                )
            
            // Indicator dot
            Circle()
                .fill(hasItems ? (isSelected ? DesignSystem.cyan : DesignSystem.purple) : Color.clear)
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


