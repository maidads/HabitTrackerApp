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

    private var year: DateInterval {
        calendar.dateInterval(of: .year, for: Date())!
    }
    
    private var dayFormatter: DateFormatter {
            let formatter = DateFormatter()
            formatter.dateFormat = "d"
            return formatter
        }

    var body: some View {
        VStack {
            Text("Calendar for \(habit.name ?? "Habit")").font(.headline)
            let days = daysInMonth(Date())
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
                            ForEach(days, id: \.self) { day in
                                Text(dayFormatter.string(from: day))
                                    .padding(8)
                                    .background(isHabitTrackedOn(day) ? Color.green : Color.clear)
                                    .cornerRadius(10)
                         }
            }
        }
    }

    private func daysInMonth(_ date: Date) -> [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: date) else {
            return []
        }
        return calendar.generateDates(
            inside: monthInterval,
            matching: DateComponents(hour: 0, minute: 0, second: 0)
        )
    }

    private func isHabitTrackedOn(_ date: Date) -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        return habit.trackedDates?.contains(dateString) ?? false
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

