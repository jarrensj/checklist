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
    @State private var itemToDelete: ChecklistItem? = nil
    
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
                            
                            Spacer()
                            
                            // Drag handle
                            Image(systemName: "line.3.horizontal")
                                .foregroundColor(.gray)
                                .font(.body)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            if itemToDelete == item {
                                Button(role: .destructive) {
                                    deleteItem(item)
                                } label: {
                                    Label("Confirm Delete", systemImage: "checkmark")
                                }
                            } else {
                                Button(role: .destructive) {
                                    itemToDelete = item
                                    // Reset after a delay if not confirmed
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                        if itemToDelete == item {
                                            itemToDelete = nil
                                        }
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                        .deleteDisabled(true)
                    }
                    .onMove(perform: moveItems)
                }
                .listStyle(InsetListStyle())
                .environment(\.editMode, .constant(.active))
            }
            .navigationTitle("Checklist")
            .toolbar {
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
    
    private func deleteItem(_ item: ChecklistItem) {
        modelContext.delete(item)
        itemToDelete = nil
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
