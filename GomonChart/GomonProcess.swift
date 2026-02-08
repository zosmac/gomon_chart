//
//  GomonProcess.swift
//  GomonChart
//
//  Created by Keefe Hayes on 12/20/25.
//

import Foundation
import SwiftData
import SwiftUI

final class GomonProcess {
    static private var _shared: GomonProcess?
    static var shared: GomonProcess? {
        if _shared == nil {
            if !appIsTerminating {
                _shared = GomonProcess()
            }
        }
        return _shared
    }
    static private var appIsTerminating: Bool = false
    static func terminate(appIsTerminating: Bool) -> NSApplication.TerminateReply {
        Self.appIsTerminating = appIsTerminating
        if let _shared,
           _shared.command.isRunning {
            Self._shared = nil
            print("process object is \(_shared)")
            _shared.command.terminate()
            return .terminateLater
        }
        return .terminateNow
    }

    let command = Process()
    let stdout = Pipe()
    let stderr = Pipe()
    var insert: (@MainActor @Sendable ([Event]) -> Bool)? = nil // = { _ in true }

    private init() {
        // the filepath used here depends on sandboxing. Without sandboxing, use absolute path. With sandboxing, a relative path looks in the product location.
        //            command.executableURL = URL(fileURLWithPath: "/bin/sh")
        //            command.arguments = ["-c", "/Users/keefe/go/bin/gomon -measures process -events none -top 1"]

        command.executableURL = URL(filePath: "/Users/keefe/go/bin/gomon", directoryHint: .notDirectory, )
        command.arguments = ["-measurements", "process", "-observations", "none", "-top", "1"]
        command.standardInput = FileHandle.nullDevice
        command.standardOutput = stdout.fileHandleForWriting
        command.standardError = stderr.fileHandleForWriting
        // Does setting PATH work to find executable with/without sandboxing?
        command.environment = ["GOMON_LOG_LEVEL": "debug", "PATH": "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/Users/keefe/go/bin"]

        Task.detached { [self] in
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

                let events = GomonEvents.events(data: data)
                if !events.isEmpty {
                    Task { @MainActor [self] in
                        if insert != nil,
                           !insert!(events) { // if insert fails ...
                            _ = GomonProcess.terminate(appIsTerminating: false)
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
                Task { @MainActor in
                    if GomonProcess.appIsTerminating {
                        NSApp.reply(toApplicationShouldTerminate: true)
                    }
                }
            }

            do {
                try command.run()
                stderr.fileHandleForReading.readInBackgroundAndNotify()
                stdout.fileHandleForReading.readInBackgroundAndNotify()
                command.waitUntilExit()
            } catch {
                print(error)
            }

            NotificationCenter.default.removeObserver(commandTerminateObserver, name: Process.didTerminateNotification, object: command)
            NotificationCenter.default.removeObserver(stdoutObserver, name: FileHandle.readCompletionNotification, object: stdout.fileHandleForReading)
            NotificationCenter.default.removeObserver(stderrObserver, name: FileHandle.readCompletionNotification, object: stderr.fileHandleForReading)
        }
    }

    func register(_ insert: @escaping (@MainActor @Sendable ([Event]) -> Bool) ) {
        self.insert = insert
    }
}
