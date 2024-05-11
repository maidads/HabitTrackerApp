//
//  CalendarComponent.swift
//  HabitTracker
//
//  Created by Maida on 2024-05-11.
//

import SwiftUI

struct CalendarComponent: View {
    @Binding var selectedHabit: Item

    var body: some View {
        Text("Calendar for \(selectedHabit.name ?? "Habit")")
    }
}
