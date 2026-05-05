//
//  deskmatApp.swift
//  deskmat
//
//  Created by Vjeko Ne Radi on 04.05.2026..
//

import SwiftUI
import CoreData

@main
struct deskmatApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
        .defaultSize(width: 300, height: 200)
        .windowResizability(.contentMinSize)
    }
}
