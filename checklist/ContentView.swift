//
//  ContentView.swift
//  checklist
//
//  Created by Jarren on 10/18/25.
//

import SwiftUI

struct ChecklistItem: Identifiable, Codable {
    let id: UUID
    var title: String
    var isCompleted: Bool = false
    
    init(id: UUID = UUID(), title: String, isCompleted: Bool = false) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
    }
}

struct ContentView: View {
    @State private var items: [ChecklistItem] = []
    @State private var newItemText: String = ""
    @State private var editingItemId: UUID? = nil
    
    private let itemsKey = "checklistItems"
    
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
                    ForEach($items) { $item in
                        HStack {
                            Button(action: {
                                item.isCompleted.toggle()
                                saveItems()
                            }) {
                                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(item.isCompleted ? .green : .gray)
                                    .font(.title3)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            
                            if editingItemId == item.id {
                                TextField("Edit item", text: $item.title)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .onSubmit {
                                        editingItemId = nil
                                        saveItems()
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
                }
                .listStyle(InsetListStyle())
            }
            .navigationTitle("Checklist")
            .toolbar {
                EditButton()
            }
            .onAppear {
                loadItems()
            }
        }
    }
    
    private func addItem() {
        guard !newItemText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        let newItem = ChecklistItem(title: newItemText)
        items.append(newItem)
        newItemText = ""
        saveItems()
    }
    
    private func deleteItems(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        saveItems()
    }
    
    private func saveItems() {
        if let encoded = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(encoded, forKey: itemsKey)
        }
    }
    
    private func loadItems() {
        if let data = UserDefaults.standard.data(forKey: itemsKey),
           let decoded = try? JSONDecoder().decode([ChecklistItem].self, from: data) {
            items = decoded
        }
    }
}

#Preview {
    ContentView()
}
