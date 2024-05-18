//
//  HabitDetailView.swift
//  HabitTracker
//
//  Created by Maida on 2024-05-18.
//

import SwiftUI
import CoreData
import UserNotifications

struct HabitDetailView: View {
    @ObservedObject var item: Item
        @Environment(\.presentationMode) var presentationMode
        @Environment(\.managedObjectContext) private var viewContext

        @State private var newName: String
        @State private var selectedColorIndex: Int = -1
        @State private var reminderEnabled: Bool
        @State private var reminderTime: Date
    
    let rainbowColors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]

    init(item: Item) {
        self.item = item
        _newName = State(initialValue: item.name ?? "")
        _reminderEnabled = State(initialValue: item.reminderEnabled)
        _reminderTime = State(initialValue: item.reminderTime ?? Date())
        if let colorHex = item.color, let index = rainbowColors.firstIndex(where: { UIColor($0).toHex() == colorHex }) {
            _selectedColorIndex = State(initialValue: index)
        }
    }

    var body: some View {
        VStack {
            TextField("Enter new name", text: $newName)
                .padding()
            Toggle("Enable Reminder", isOn: $reminderEnabled)
                           .padding()
                       if reminderEnabled {
                           DatePicker("Reminder Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                               .padding()
                       }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(rainbowColors.indices, id: \.self) { index in
                        Circle()
                            .fill(rainbowColors[index])
                            .frame(width: selectedColorIndex == index ? 40 : 30,
                                   height: selectedColorIndex == index ? 40 : 30)
                            .overlay(
                                Circle().stroke(rainbowColors[index], lineWidth: selectedColorIndex == index ? 3 : 1)
                            )
                            .onTapGesture {
                                selectedColorIndex = index
                            }
                            .padding(4)
                    }
                }
            }
            .padding()

            Button("Save") {
                saveChanges()
            }
            .padding()
        }
        .navigationTitle("Edit Habit")
        .onAppear {
            newName = item.name ?? ""
        }
    }
    
    private func saveChanges() {
        item.name = newName
        item.color = selectedColorIndex == -1 ? nil : UIColor(rainbowColors[selectedColorIndex]).toHex()
        item.reminderEnabled = reminderEnabled
        item.reminderTime = reminderEnabled ? reminderTime : nil
        do {
            try viewContext.save()
            if reminderEnabled {
                scheduleNotification()
            } else {
                removeNotification()
            }
                presentationMode.wrappedValue.dismiss()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
    }
    
    private func scheduleNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Habit Reminder"
        content.body = "Time to work on your habit: \(newName)"
        content.sound = UNNotificationSound.default
        
        var dateComponents = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        dateComponents.second = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: item.objectID.uriRepresentation().absoluteString, content: content, trigger: trigger)
            
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }

    private func removeNotification() {
        let identifier = item.objectID.uriRepresentation().absoluteString
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}
