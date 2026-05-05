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
        WindowGroup(id: "main") {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onAppear {
                    NSApp.windows.first(where: {
                        !$0.className.contains("StatusBar")
                    }).map { window in
                        // Remove minimize and fullscreen buttons
                        window.styleMask.remove(.miniaturizable)
                        // Hide instead of close
                        window.isReleasedWhenClosed = false
                    }
                }
        }
        .handlesExternalEvents(matching: ["main"])
        .defaultSize(width: 800, height: 600)
        .windowResizability(.contentMinSize)
 
        MenuBarExtra("Deskmat", systemImage: "photo.on.rectangle") {
            MenuBarButtons()
        }
    }
}
 
struct MenuBarButtons: View {
    var body: some View {
        Button("Open Deskmat") {
            if let url = URL(string: "deskmat://main") {
                NSWorkspace.shared.open(url)
            }
            NSApp.activate(ignoringOtherApps: true)
        }
        Divider()
        Button("Quit") {
            NSApp.terminate(nil)
        }
    }
}

