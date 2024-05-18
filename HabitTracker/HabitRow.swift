//
//  HabitRow.swift
//  HabitTracker
//
//  Created by Maida on 2024-05-18.
//

import SwiftUI
import CoreData
import UserNotifications

struct HabitRow: View {
        @ObservedObject var item: Item
        @State private var daysSelected: [Bool]
        @State private var currentStreak: Int
        let calendar = Calendar.current
        
        init(item: Item) {
            self.item = item
            _daysSelected = State(initialValue: item.daysSelected?.map { $0 == "1" } ?? Array(repeating: false, count: 7))
            _currentStreak = State(initialValue: Int(item.currentStreak))
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text(item.name ?? "New Habit")
                HStack {
                    ForEach(0..<7) { index in
                        let date = calendar.date(byAdding: .day, value: index - calendar.component(.weekday, from: Date()) + 1, to: Date())!
                        let day = calendar.component(.day, from: date)
                        VStack {
                            Circle()
                                .fill(daysSelected[index] ? Color(hex: item.color ?? "#FFFFFF") : Color.clear)
                                .overlay(
                                    Circle().stroke(Color(hex: item.color ?? "#FFFFFF"), lineWidth: 2)
                                )
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Text("\(day)")
                                        .foregroundColor(daysSelected[index] ? .white : .black)
                                )
                                .onTapGesture {
                                    daysSelected[index].toggle()
                                    currentStreak = calculateStreak(at: index)
                                    updateDaysSelectedInCoreData()
                                }
                            Text(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"][calendar.component(.weekday, from: date) - 1])
                                .font(.caption)
                        }
                    }
                    Text("🔥 \(currentStreak)")
                        .padding(.top, -50).padding(.leading, -10)
                        .foregroundColor(Color.black)
                }
            }.onAppear {
                if let daysString = item.daysSelected {
                        daysSelected = daysString.map { $0 == "1" }
                    }
                    currentStreak = Int(item.currentStreak)
            }
        }
        
    func loadDaysSelected() {
            if let daysString = item.daysSelected {
                daysSelected = daysString.map { $0 == "1" }
            }
    }

    private func updateDaysSelectedInCoreData() {
        item.daysSelected = daysSelected.map { $0 ? "1" : "0" }.joined()
        item.currentStreak = Int16(currentStreak)
        do {
            try item.managedObjectContext?.save()
        } catch {
            print("Failed to save days selected: \(error)")
        }
    }

    func calculateStreak(at index: Int) -> Int {
        var streakCount = 0
        for i in index..<daysSelected.count {
            if daysSelected[i] {
                streakCount += 1
            } else {
                break
            }
        }
        for i in (0..<index).reversed() {
            if daysSelected[i] {
                streakCount += 1
            } else {
                break
            }
        }
        currentStreak = streakCount
        return streakCount
    }
}
