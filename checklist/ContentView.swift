//
//  ContentView.swift
//  checklist
//
//  Created by Jarren on 10/18/25.
//

import SwiftUI

struct ChecklistItem: Identifiable {
    let id = UUID()
    var title: String
    var isCompleted: Bool = false
}

struct ContentView: View {
    @State private var items: [ChecklistItem] = []
    @State private var newItemText: String = ""
    
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
                            }) {
                                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(item.isCompleted ? .green : .gray)
                                    .font(.title3)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            
                            Text(item.title)
                                .strikethrough(item.isCompleted)
                                .foregroundColor(item.isCompleted ? .gray : .primary)
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
        items.append(newItem)
        newItemText = ""
    }
    
    private func deleteItems(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
    }
}

#Preview {
    ContentView()
}
