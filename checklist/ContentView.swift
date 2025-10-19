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
    
    init(id: UUID = UUID(), title: String, isCompleted: Bool = false) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [ChecklistItem]
    @State private var newItemText: String = ""
    @State private var editingItemId: UUID? = nil
    
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
                }
                .listStyle(InsetListStyle())
            }
            .navigationTitle("Checklist")
            .toolbar {
                EditButton()
            }
        }
    }
    
    private func addItem() {
        guard !newItemText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        let newItem = ChecklistItem(title: newItemText)
        modelContext.insert(newItem)
        newItemText = ""
    }
    
    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(items[index])
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: ChecklistItem.self, inMemory: true)
}
