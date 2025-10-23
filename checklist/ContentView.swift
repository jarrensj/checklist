//
//  ContentView.swift
//  checklist
//
//  Created by Jarren on 10/18/25.
//

import SwiftUI
import SwiftData

enum AutoDeleteOption: String, CaseIterable, Identifiable {
    case never = "Never"
    case threeSeconds = "3 seconds"
    case tenSeconds = "10 seconds"
    case oneDay = "1 day"
    case threeDays = "3 days"
    case oneWeek = "1 week"
    
    var id: String { rawValue }
    
    var timeInterval: TimeInterval? {
        switch self {
        case .never:
            return nil
        case .threeSeconds:
            return 3
        case .tenSeconds:
            return 10
        case .oneDay:
            return 86400 // 24 * 60 * 60
        case .threeDays:
            return 259200 // 3 * 24 * 60 * 60
        case .oneWeek:
            return 604800 // 7 * 24 * 60 * 60
        }
    }
}

@Model
class ChecklistItem {
    var id: UUID
    var title: String
    var isCompleted: Bool
    var createdAt: Date
    var completedAt: Date?
    var sortOrder: Int
    
    init(id: UUID = UUID(), title: String, isCompleted: Bool = false, createdAt: Date = Date(), completedAt: Date? = nil, sortOrder: Int = 0) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.sortOrder = sortOrder
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ChecklistItem.sortOrder, order: .reverse) private var items: [ChecklistItem]
    @State private var newItemText: String = ""
    @State private var editingItemId: UUID? = nil
    @State private var showingSettings = false
    @AppStorage("autoDeleteOption") private var autoDeleteOptionRaw: String = AutoDeleteOption.never.rawValue
    
    private let cleanupTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    private var autoDeleteOption: AutoDeleteOption {
        AutoDeleteOption(rawValue: autoDeleteOptionRaw) ?? .never
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Input field for new items
                HStack {
                    TextField("Add new item", text: $newItemText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit {
                            addItem()
                        }
                    
                    Button(action: addItem) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    .disabled(newItemText.isEmpty)
                }
                .padding()
                
                // List of items
                List {
                    ForEach(items) { item in
                        HStack {
                            Button(action: {
                                item.isCompleted.toggle()
                                if item.isCompleted {
                                    item.completedAt = Date()
                                    scheduleAutoDelete(for: item)
                                } else {
                                    item.completedAt = nil
                                }
                            }) {
                                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(item.isCompleted ? .green : .gray)
                                    .font(.title3)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            
                            if editingItemId == item.id {
                                TextField("Edit item", text: Binding(
                                    get: { item.title },
                                    set: { item.title = $0 }
                                ))
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .onSubmit {
                                        editingItemId = nil
                                    }
                            } else {
                                Text(item.title)
                                    .strikethrough(item.isCompleted)
                                    .foregroundColor(item.isCompleted ? .gray : .primary)
                                    .onTapGesture {
                                        editingItemId = item.id
                                    }
                            }
                        }
                    }
                    .onDelete(perform: deleteItems)
                    .onMove(perform: moveItems)
                }
                .listStyle(InsetListStyle())
            }
            .navigationTitle("Checklist")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .onAppear {
                cleanupExpiredItems()
            }
            .onReceive(cleanupTimer) { _ in
                cleanupExpiredItems()
            }
        }
    }
    
    private func addItem() {
        guard !newItemText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        // New items get the highest sortOrder value to appear at top
        let maxOrder = items.map { $0.sortOrder }.max() ?? -1
        let newItem = ChecklistItem(title: newItemText, sortOrder: maxOrder + 1)
        modelContext.insert(newItem)
        newItemText = ""
    }
    
    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(items[index])
        }
    }
    
    private func moveItems(from source: IndexSet, to destination: Int) {
        // Create a mutable copy of the items array
        var reorderedItems = Array(items)
        
        // Perform the move
        reorderedItems.move(fromOffsets: source, toOffset: destination)
        
        // Reassign sortOrder values in descending order
        // First item gets highest value (appears at top with reverse sort)
        let startValue = reorderedItems.count - 1
        for (index, item) in reorderedItems.enumerated() {
            item.sortOrder = startValue - index
        }
    }
    
    private func scheduleAutoDelete(for item: ChecklistItem) {
        guard let timeInterval = autoDeleteOption.timeInterval else { return }
        
        // Use Task to schedule deletion after delay
        Task {
            try? await Task.sleep(nanoseconds: UInt64(timeInterval * 1_000_000_000))
            
            // Check if item still exists and is still completed
            if item.isCompleted, let completedAt = item.completedAt {
                let timeSinceCompletion = Date().timeIntervalSince(completedAt)
                if timeSinceCompletion >= timeInterval {
                    await MainActor.run {
                        modelContext.delete(item)
                    }
                }
            }
        }
    }
    
    private func cleanupExpiredItems() {
        guard let timeInterval = autoDeleteOption.timeInterval else { return }
        
        let now = Date()
        let itemsToDelete = items.filter { item in
            guard item.isCompleted, let completedAt = item.completedAt else { return false }
            return now.timeIntervalSince(completedAt) >= timeInterval
        }
        
        for item in itemsToDelete {
            modelContext.delete(item)
        }
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("autoDeleteOption") private var autoDeleteOptionRaw: String = AutoDeleteOption.never.rawValue
    
    private var autoDeleteOption: AutoDeleteOption {
        get { AutoDeleteOption(rawValue: autoDeleteOptionRaw) ?? .never }
        set { autoDeleteOptionRaw = newValue.rawValue }
    }
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Behavior")) {
                    Picker("Auto-delete completed", selection: Binding(
                        get: { autoDeleteOption },
                        set: { autoDeleteOptionRaw = $0.rawValue }
                    )) {
                        ForEach(AutoDeleteOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    
                    if autoDeleteOption != .never {
                        Text("Completed items will be automatically deleted after \(autoDeleteOption.rawValue).")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("App Name")
                        Spacer()
                        Text("Checklist")
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0-beta")
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: ChecklistItem.self, inMemory: true)
}
