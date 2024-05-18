//
//  AddHabitView.swift
//  HabitTracker
//
//  Created by Maida on 2024-05-18.
//

import SwiftUI
import CoreData
import UserNotifications

struct AddHabitView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    @State private var habitName: String = ""
    @State private var selectedColorIndex: Int = -1
    let rainbowColors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]

    var body: some View {
        ZStack {
            Color.blue.opacity(0.1)
            VStack {
                TextField("Enter habit name", text: $habitName)
                    .padding()
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
                                .padding(4)
                                .onTapGesture {
                                    selectedColorIndex = index
                                }
                        }
                    }
                }
                .padding()
                HStack {
                    Spacer()
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .padding(.horizontal)
                    Button("Save") {
                        addNewItem()
                    }
                    .padding(.horizontal)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(16)
            .shadow(radius: 10)
            .frame(width: 375, height: 430)
        }
    }

    private func addNewItem() {
        let newItem = Item(context: viewContext)
        newItem.name = habitName
        newItem.color = selectedColorIndex == -1 ? nil : UIColor(rainbowColors[selectedColorIndex]).toHex()

        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Error saving managed object context: \(error)")
        }
    }
}
