//
//  GomonChartApp.swift
//  GomonChart
//
//  Created by Keefe Hayes on 12/7/25.
//

import SwiftData
import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static var gomonEventsDocument: UTType {
        UTType(exportedAs: "com.github.zosmac.gomonevents")
    }
}

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
                            for event in events.events {
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
                print("Window will close \(window)")
            }
        }
    }

    func applicationShouldTerminate(_ application: NSApplication) -> NSApplication.TerminateReply {
        print("Application should terminate \(application)")
        if let process = GomonProcess.shared,
           process.command.isRunning {
            print("process object is \(process)")
            process.appIsTerminating = true
            process.command.terminate()
            return .terminateLater
        }
        return .terminateNow
    }

    func applicationWillTerminate(_ notification: Notification) {
        print("Application will terminate \(notification)")
    }
}
