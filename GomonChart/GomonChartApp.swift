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
            editing: .gomonModelDocument,
            migrationPlan: GomonModelMigrationPlan.self,
            editor: {
                DashboardView()
            },
            prepareDocument: { context in
                print("New document created:\n\(context.container.configurations)\n")
            }
        )
//        .commands {
//            CommandGroup(replacing: .appTermination) {
//
//            }
//        }

        //        Window("Nodegraph", id: "Nodegraph") {
        //            NodegraphView()
        //        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("Application finished launching \(notification)")
    }

    func applicationShouldTerminate(_ application: NSApplication) -> NSApplication.TerminateReply {
        print("Application should terminate \(application)")
        if GomonProcess.shared.command.isRunning {
            GomonProcess.shared.command.terminate()
            return .terminateLater
        }
        return .terminateNow
    }

    func applicationWillTerminate(_ notification: Notification) {
        print("Application will terminate \(notification)")
    }
}
