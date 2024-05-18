import SwiftUI
import CoreData
import UserNotifications

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
        animation: .default
    ) private var items: FetchedResults<Item>

    @State private var showingAddHabitView = false

    var body: some View {
        TabView {
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
            }.accentColor(.black)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            
            CalendarView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Calendar")
                }
        }
        .onAppear(perform: requestNotificationPermission)
    }
    
    private func requestNotificationPermission() {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                if let error = error {
                    print("Error requesting notification permission: \(error)")
                }
            }
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
