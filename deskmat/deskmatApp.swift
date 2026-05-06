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
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup(id: "main") {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onAppear {
                    NSApp.windows.first(where: {
                        !$0.className.contains("StatusBar")
                    }).map { window in
                        window.styleMask.remove(.miniaturizable)
                        window.isReleasedWhenClosed = false
                    }
                }
        }
        .handlesExternalEvents(matching: ["main"])
        .defaultSize(width: 800, height: 600)
        .windowResizability(.contentMinSize)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "photo.on.rectangle", accessibilityDescription: "Deskmat")
            button.action = #selector(handleClick)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.target = self
        }

        let popover = NSPopover()
        popover.contentSize = NSSize(width: 500, height: 300)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: ContentView()
                .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
                .frame(width: 500, height: 300)
        )
        self.popover = popover
    }

    @objc func handleClick(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp {
            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: "Quit Deskmat", action: #selector(quit), keyEquivalent: "q"))
            statusItem?.menu = menu
            statusItem?.button?.performClick(nil)
            statusItem?.menu = nil
        } else {
            if let popover, let button = statusItem?.button {
                if popover.isShown {
                    popover.performClose(nil)
                } else {
                    popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                }
            }
        }
    }

    @objc func quit() {
        NSApp.terminate(nil)
    }
}

