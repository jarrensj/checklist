//
//  ContentView.swift
//  checklist
//
//  Created by Jarren on 10/18/25.
//

import SwiftUI
import SwiftData

@Model
class ChecklistItem {
    var id: UUID
    var title: String
    var isCompleted: Bool
    var createdAt: Date
    var sortOrder: Int
    
    init(id: UUID = UUID(), title: String, isCompleted: Bool = false, createdAt: Date = Date(), sortOrder: Int = 0) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.sortOrder = sortOrder
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ChecklistItem.sortOrder, order: .reverse) private var items: [ChecklistItem]
    @State private var newItemText: String = ""
    @State private var editingItemId: UUID? = nil
    @State private var showingSettings = false
    
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
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [ChecklistItem]
    @State private var showingResetAlert = false
    
    var body: some View {
        NavigationView {
            List {
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
                
                Section(header: Text("Data")) {
                    Button(action: {
                        showingResetAlert = true
                    }) {
                        Text("Reset App to Defaults")
                            .foregroundColor(.red)
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
            .alert("Reset App to Defaults", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    resetApp()
                }
            } message: {
                Text("This will delete all checklist items. This action cannot be undone.")
            }
        }
    }
    
    private func resetApp() {
        for item in items {
            modelContext.delete(item)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: ChecklistItem.self, inMemory: true)
}
