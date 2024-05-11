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



import SwiftUI

struct HabitCalendarView: View {
    var habit: Item
    @State private var month: Date = Date()

    var body: some View {
        VStack {
            Text("Calendar for \(habit.name ?? "Habit")")
                .font(.headline)
            Text("Calendar UI placeholder")
        }
        .navigationTitle("Habit Calendar")
        .navigationBarTitleDisplayMode(.inline)
    }
}

