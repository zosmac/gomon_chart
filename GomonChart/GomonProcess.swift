//
//  GomonProcess.swift
//  GomonChart
//
//  Created by Keefe Hayes on 12/20/25.
//

import Foundation
import SwiftData
import SwiftUI

struct OpenWindow: NotificationCenter.AsyncMessage {
    typealias Subject = GomonProcess
    let id: UUID
    let title: String
    let window: NSWindow?
}

actor GomonProcess {
    @Observable final class Coordinator {
        var gomonProcess: GomonProcess?
    }

    @MainActor var appIsTerminating: Bool = false
    @MainActor var insert: (@MainActor @Sendable (Events) -> Bool)? = nil // = { _ in true }
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
            let stderrObserver = NotificationCenter.default.addObserver(
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

            let stdoutObserver = NotificationCenter.default.addObserver(
                forName: FileHandle.readCompletionNotification,
                object: stdout.fileHandleForReading,
                queue: .current
            ) { [self] notification in
                let data = notification.userInfo?["NSFileHandleNotificationDataItem"] as! Data
                stdout.fileHandleForReading.readInBackgroundAndNotify()

                let events = Events(data: data)
                if !events.events.isEmpty {
                    Task { @MainActor [self] in
                        if let fn = insert,
                           !fn(events) { // if insert fails ...
                            insert = nil //   un-register event capture
                            command.terminate()
                        }
                    }
                }
            }

            print("command to await termination is \(command)")
            let commandTerminateObserver = NotificationCenter.default.addObserver(
                forName: Process.didTerminateNotification,
                object: command,
                queue: .current
            ) { notification in
                print("process terminated \(String(describing: notification.object))")
                Task { @MainActor [self] in
                    if appIsTerminating {
                        NSApp.reply(toApplicationShouldTerminate: true)
                    }
                }
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

            NotificationCenter.default.removeObserver(commandTerminateObserver, name: Process.didTerminateNotification, object: command)
            NotificationCenter.default.removeObserver(stdoutObserver, name: FileHandle.readCompletionNotification, object: stdout.fileHandleForReading)
            NotificationCenter.default.removeObserver(stderrObserver, name: FileHandle.readCompletionNotification, object: stderr.fileHandleForReading)
        }
    }

    @MainActor func register(_ insert: @escaping (@MainActor @Sendable (Events) -> Bool) ) {
        self.insert = insert
    }
}
