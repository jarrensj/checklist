//
//  checklistApp.swift
//  checklist
//
//  Created by Jarren on 10/18/25.
//

import SwiftUI
import SwiftData

@main
struct checklistApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: ChecklistItem.self)
    }
}
