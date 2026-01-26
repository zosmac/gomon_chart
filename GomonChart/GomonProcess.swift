//
//  GomonProcess.swift
//  GomonChart
//
//  Created by Keefe Hayes on 12/20/25.
//

import Foundation
import SwiftData
import SwiftUI

actor GomonProcess {
    @Observable final class Coordinator {
        var gomonProcess: GomonProcess?
    }

    @MainActor var insert: (@MainActor @Sendable (Events) -> Bool) = { _ in true }
    @MainActor static private let coordinator = Coordinator()
    @MainActor static var shared: GomonProcess? {
        get {
            if coordinator.gomonProcess == nil {
                coordinator.gomonProcess = GomonProcess()
            }
            return coordinator.gomonProcess
        }
        set {
            coordinator.gomonProcess = newValue
        }
    }

    let command = Process()
    let stdout = Pipe()
    let stderr = Pipe()

    private init() {
        // the filepath used here depends on sandboxing. Without sandboxing, use absolute path. With sandboxing, a relative path looks in the product location.
        //            process.executableURL = URL(fileURLWithPath: "/bin/sh")
        //            process.arguments = ["-c", "/Users/keefe/go/bin/gomon -measures process -events none -top 1"]

        command.executableURL = URL(filePath: "/Users/keefe/go/bin/gomon", directoryHint: .notDirectory, )
        command.arguments = ["-measurements", "process", "-observations", "none", "-top", "1"]
        command.standardInput = FileHandle.nullDevice
        command.standardOutput = stdout.fileHandleForWriting
        command.standardError = stderr.fileHandleForWriting
        // Does setting PATH work to find executable with/without sandboxing?
        command.environment = ["GOMON_LOG_LEVEL": "debug", "PATH": "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/Users/keefe/go/bin"]

        Task {
            // create observers here in task, so that they are retained until task exits
            NotificationCenter.default.addObserver(
                forName: FileHandle.readCompletionNotification,
                object: stderr.fileHandleForReading,
                queue: .current
            ) { [self] notification in
                let data = notification.userInfo?["NSFileHandleNotificationDataItem"] as! Data
                if let string = String(data: data, encoding: .utf8) {
                    print("=== stderr from gomon: ===\n\(string)")
                }
                stderr.fileHandleForReading.readInBackgroundAndNotify()
            }

            NotificationCenter.default.addObserver(
                forName: FileHandle.readCompletionNotification,
                object: stdout.fileHandleForReading,
                queue: .current
            ) { [self] notification in
                let data = notification.userInfo?["NSFileHandleNotificationDataItem"] as! Data
                stdout.fileHandleForReading.readInBackgroundAndNotify()

                let events = Events(data: data)
                if !events.events.isEmpty {
                    Task { @MainActor in
                        if !insert(events) {       // if insert fails ...
                            insert = { _ in true } //   un-register event capture
                            self.command.terminate()
                        }
                    }
                }
            }

            print("command to await termination is \(self.command)")
            NotificationCenter.default.addObserver(
                forName: Process.didTerminateNotification,
                object: self.command,
                queue: .current
            ) { notification in
                print("process terminated \(String(describing: notification.object))")
            }

            do {
                try command.run()
                stderr.fileHandleForReading.readInBackgroundAndNotify()
                stdout.fileHandleForReading.readInBackgroundAndNotify()
                command.waitUntilExit()
                Task { @MainActor in
                    GomonProcess.shared = nil
                }
            } catch {
                print(error)
            }
        }
    }

    @MainActor func register(_ insert: @escaping (@MainActor @Sendable (Events) -> Bool) ) {
        self.insert = insert
    }
}
