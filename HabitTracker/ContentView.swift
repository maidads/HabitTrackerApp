import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)], animation: .default) private var items: FetchedResults<Item>
    @State private var showingAddHabitView = false

    var body: some View {
        NavigationView {
            List {
                ForEach(items) { item in
                    NavigationLink(destination: HabitDetailView(item: item)) {
                        HabitRow(item: item)
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingAddHabitView = true
                    }) {
                        HStack {
                            Image(systemName: "plus").foregroundColor(.black)
                            Text("New habit")
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
            .sheet(isPresented: $showingAddHabitView) {
                AddHabitView()
            }
        }.accentColor(.black)
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(context: viewContext)
            newItem.name = "New Habit"
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}


struct HabitRow: View {
    @ObservedObject var item: Item
    @State private var daysSelected: [Bool] = [false, false, false, false, false, false, false]
    let weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    let rainbowColors: [Color] = [
        Color.red, Color.orange, Color.yellow, Color.green, Color.blue, Color.purple, Color.pink
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(item.name ?? "New Habit")
            HStack {
                ForEach(0..<7) { index in
                    VStack {
                        Circle()
                            .fill(daysSelected[index] ? rainbowColors[index] : Color.clear)
                            .overlay(
                                Circle().stroke(rainbowColors[index], lineWidth: 2)
                            )
                            .frame(width: 20, height: 20)
                            .onTapGesture {
                                daysSelected[index].toggle()
                            }
                        Text(weekdays[index])
                            .font(.caption)
                    }
                }
            }
        }
    }
}


struct HabitDetailView: View {
    @ObservedObject var item: Item
    @State private var newName: String

    @Environment(\.presentationMode) var presentationMode

    init(item: Item) {
        self.item = item
        _newName = State(initialValue: item.name ?? "")
    }

    var body: some View {
        VStack {
            TextField("Enter new name", text: $newName)
                .padding()
            Button("Save") {
                if !newName.isEmpty {
                    item.name = newName
                    do {
                        try item.managedObjectContext?.save()
                        presentationMode.wrappedValue.dismiss()
                    } catch {
                        let nsError = error as NSError
                        fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
                    }
                }
            }
            .padding()
        }
        .onAppear {
            newName = item.name ?? ""
        }
        .navigationTitle("Edit Habit")
    }
}


struct AddHabitView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    @State private var habitName: String = ""

    var body: some View {
        ZStack {
            Color.blue.opacity(0.1)
            VStack {
                TextField("Enter habit name", text: $habitName)
                    .padding()
                HStack {
                    Spacer()
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .padding(.horizontal)
                    Button("Save") {
                        if !habitName.isEmpty {
                            let newItem = Item(context: viewContext)
                            newItem.name = habitName
                            do {
                                try viewContext.save()
                                presentationMode.wrappedValue.dismiss()
                            } catch {
                                let nsError = error as NSError
                                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(16)
            .shadow(radius: 10)
        }
    }
}




