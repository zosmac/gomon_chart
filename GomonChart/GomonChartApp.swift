//
//  GomonChartApp.swift
//  GomonChart
//
//  Created by Keefe Hayes on 12/7/25.
//

import SwiftData
import SwiftUI

@main
struct GomonChartApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        DocumentGroup(
            editing: .gomonEventsDocument,
            migrationPlan: GomonEventsMigrationPlan.self,
            editor: {
                DashboardView()
            },
            prepareDocument: { modelContext in
                // Each "new" document replaces the gomon process insert events closure.
                GomonProcess.shared!.register { events in
                    // autosaveEnabled is the only indicator for determining if current "new" document is no longer accepting database updates (i.e. that the window presenting the "new" document is closed).
                    if !modelContext.autosaveEnabled {
                        return false // tells gomon process to remove this insert closure
                    }

                    do {
                        try modelContext.transaction {
                            for event in events {
                                modelContext.insert(event)
                            }
                        }
                        return true
                    } catch {
                        print("Transaction failed: \(error)")
                        return false
                    }
                }
            }
        )

//        Window("Nodegraph", id: "Nodegraph") {
//            NodegraphView()
//        }

    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var windowCloseObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("Application finished launching \(notification)")

        windowCloseObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: nil,
            queue: nil,
        ) { notification in
            let window = notification.object as! NSWindow
            Task { @MainActor in
                let nsView = window.contentView
                let subViews = nsView?.subviews
                let superView = nsView?.superview
                if nsView is NSHostingView<DashboardView> {
                    print("view will close \(String(describing: nsView))")
                }
                if superView is NSHostingView<DashboardView> {
                    print("superview will close \(String(describing: superView))")
                }
                for view in subViews! {
                    if view is any NSViewRepresentable {
                        print("subview will close \(String(describing: view))")
                    }
                }
            }
        }
    }

    func applicationShouldTerminate(_ application: NSApplication) -> NSApplication.TerminateReply {
        GomonProcess.terminate(appIsTerminating: true)
    }

    func applicationWillTerminate(_ notification: Notification) {
        print("Application will terminate \(notification)")
    }
}
