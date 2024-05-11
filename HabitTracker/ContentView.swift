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
            .navigationBarTitle("Habit Tracker", displayMode: .large)
            .navigationBarTitleDisplayMode(.large)
        }
        .accentColor(.black)
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

struct HabitDetailView: View {
    @ObservedObject var item: Item
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext

    @State private var newName: String
    @State private var selectedColorIndex: Int = -1
    let rainbowColors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]

    init(item: Item) {
        self.item = item
        _newName = State(initialValue: item.name ?? "")
        if let colorHex = item.color, let index = rainbowColors.firstIndex(where: { UIColor($0).toHex() == colorHex }) {
            _selectedColorIndex = State(initialValue: index)
        }
    }

    var body: some View {
        VStack {
            TextField("Enter new name", text: $newName)
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
                            .onTapGesture {
                                selectedColorIndex = index
                            }
                            .padding(4)
                    }
                }
            }
            .padding()

            Button("Save") {
                if !newName.isEmpty {
                    item.name = newName
                    item.color = selectedColorIndex == -1 ? nil : UIColor(rainbowColors[selectedColorIndex]).toHex()
                    do {
                        try viewContext.save()
                        presentationMode.wrappedValue.dismiss()
                    } catch {
                        let nsError = error as NSError
                        fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Edit Habit")
        .onAppear {
            newName = item.name ?? ""
        }
    }
}


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
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        (r, g, b) = (int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        self.init(red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255)
    }
}


struct HabitRow: View {
    @ObservedObject var item: Item
        @State private var daysSelected: [Bool] = [false, false, false, false, false, false, false]
        @State private var currentStreak: Int = 0
        let calendar = Calendar.current

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
                        .padding(.leading, 40)
                        .foregroundColor(Color.black)
                }
            }.onAppear {
                loadDaysSelected()
            }
        }
        func loadDaysSelected() {
            if let daysString = item.daysSelected {
                daysSelected = daysString.map { $0 == "1" }
            }
        }

        func updateDaysSelectedInCoreData() {
            item.daysSelected = daysSelected.map { $0 ? "1" : "0" }.joined()
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
            return streakCount
        }
}




extension UIColor {
    func toHex() -> String? {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        self.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return String(format: "#%02X%02X%02X", Int(red * 255), Int(green * 255), Int(blue * 255))
    }
    convenience init(color: Color) {
            let uiColor = UIColor(color)
            self.init(cgColor: uiColor.cgColor)
        }
}
