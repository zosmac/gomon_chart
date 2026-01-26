//
//  GomonChartApp.swift
//  GomonChart
//
//  Created by Keefe Hayes on 12/7/25.
//

import SwiftData
import SwiftUI

extension FocusedValues {
    @Entry var focusedModelContext: Binding<ModelContext>?
}

@Observable final class Insertor {
    var insert: (@MainActor @Sendable (Events) -> Bool) = { _ in true }
}

@main
struct GomonChartApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        DocumentGroup(
            editing: .gomonModelDocument,
            migrationPlan: GomonModelMigrationPlan.self,
            editor: {
                ContentView()
//                DashboardView()
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
//                    do {
//                        try modelContext.save()
//                    } catch {
//                        print("Save failed: \(error)")
//                    }
                }
            }
        )
    }

    //        Window("Nodegraph", id: "Nodegraph") {
    //            NodegraphView()
    //        }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var windowCloseObserver: NSObjectProtocol?
    var processTerminateObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("Application finished launching \(notification)")

        // create observer here in task, so that it is retained until task exits
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
            processTerminateObserver = NotificationCenter.default.addObserver(
                forName: Process.didTerminateNotification,
                object: process.command,
                queue: .current
            ) { notification in
                print("process terminated \(String(describing: notification.object))")
                Task {
                    await NSApp.reply(toApplicationShouldTerminate: true)
                }
            }
            GomonProcess.shared!.command.terminate()
            return .terminateLater
        }
        return .terminateNow
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let windowCloseObserver {
            NotificationCenter.default.removeObserver(windowCloseObserver, name: NSWindow.willCloseNotification, object: nil)
        }
        print("Application will terminate \(notification)")
    }
}
