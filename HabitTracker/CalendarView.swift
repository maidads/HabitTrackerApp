//
//  CalendarView.swift
//  HabitTracker
//
//  Created by Maida on 2024-05-11.
//

import SwiftUI
import CoreData

struct CalendarView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: Item.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
        animation: .default
    ) var items: FetchedResults<Item>

    var body: some View {
        NavigationView {
            List(items, id: \.self) { item in
                NavigationLink(destination: HabitCalendarView(habit: item)) {
                    Text(item.name ?? "Unnamed Habit")
                }
            }
            .navigationBarTitle("Select Habit")
            .navigationBarItems(trailing: EditButton())
        }
    }
}


struct HabitCalendarView: View {
    @ObservedObject var habit: Item
    @Environment(\.calendar) var calendar
    @Environment(\.managedObjectContext) private var viewContext
    @State private var trackedDatesSet: Set<String> = []

    init(habit: Item) {
            _habit = ObservedObject(initialValue: habit)
        }
    static private var dayFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "d"
            return formatter
        }()

        static private var headerFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE"
            return formatter
        }()

    var body: some View {
        VStack {
            Text("Calendar for \(habit.name ?? "Habit")").font(.headline)
            headersView
            calendarGrid
        }
        .onAppear {
            updateTrackedDatesSet()
        }
    }

    private var headersView: some View {
        HStack(spacing: 0) {
            ForEach(daysOfTheWeek(), id: \.self) { day in
                Text(Self.headerFormatter.string(from: day))
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .font(.caption)
            }
        }
    }

    private var calendarGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
            ForEach(daysInMonth(Date()), id: \.self) { day in
                dayCell(for: day)
            }
        }
    }

    private func dayCell(for day: Date) -> some View {
        let dayIsSelected = trackedDatesSet.contains(dateString(day))
        return Text(Self.dayFormatter.string(from: day))
            .frame(width: 30, height: 30)
            .padding(8)
            .background(Circle()
                .fill(dayIsSelected ? Color.green : Color.gray.opacity(0.2)))
            .foregroundColor(Color.white)
            .onTapGesture {
                toggleDaySelected(day: day)
            }
    }


    private func updateTrackedDatesSet() {
        trackedDatesSet = Set(habit.trackedDates?.split(separator: ",").map(String.init) ?? [])
    }

    private func dateString(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.string(from: date)
    }

    private func daysInMonth(_ date: Date) -> [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: date) else {
            return []
        }
        return calendar.generateDates(inside: monthInterval, matching: DateComponents(hour: 0, minute: 0, second: 0))
    }

    private func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }

    private func daysOfTheWeek() -> [Date] {
        let today = Date()
        let currentWeekday = calendar.component(.weekday, from: today)
        return (1...7).map { calendar.date(byAdding: .day, value: $0 - currentWeekday, to: today)! }
    }

    func toggleDaySelected(day: Date) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: day)

        var newTrackedDates = Set(habit.trackedDates?.split(separator: ",").map(String.init) ?? [])
        if newTrackedDates.contains(dateString) {
            newTrackedDates.remove(dateString)
        } else {
            newTrackedDates.insert(dateString)
        }

        habit.trackedDates = newTrackedDates.joined(separator: ",")
        do {
            try viewContext.save()
        } catch {
            print("Failed to update habit tracked dates: \(error)")
        }
        trackedDatesSet = newTrackedDates
    }

}


extension Calendar {
    func generateDates(inside interval: DateInterval, matching components: DateComponents) -> [Date] {
        var dates: [Date] = []
        dates.append(interval.start)

        enumerateDates(startingAfter: interval.start, matching: components, matchingPolicy: .nextTime) { date, _, stop in
            guard let date = date else { return }
            if date < interval.end {
                dates.append(date)
            } else {
                stop = true
            }
        }

        return dates
    }
}


