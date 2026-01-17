//
//  GomonProcess.swift
//  GomonChart
//
//  Created by Keefe Hayes on 12/20/25.
//

import Foundation
import SwiftUI
import SwiftData

actor GomonProcess {
    static let shared = GomonProcess()
    let command = Process()
    let stdin = FileHandle(forReadingAtPath: "/dev/null")
    let stdout = Pipe()
    let stderr = Pipe()

    private init() {
        // the filepath used here depends on sandboxing. Without sandboxing, use absolute path. With sandboxing, a relative path looks in the product location.
        command.executableURL = URL(filePath: "/Users/keefe/go/bin/gomon", directoryHint: .notDirectory, )
        command.arguments = ["-measurements", "process", "-observations", "none", "-top", "1"]
        //            process.executableURL = URL(fileURLWithPath: "/bin/sh")
        //            process.arguments = ["-c", "/Users/keefe/go/bin/gomon -measures process -events none -top 1"]
        command.standardInput = stdin
        command.standardOutput = stdout.fileHandleForWriting
        command.standardError = stderr.fileHandleForWriting
        // Does setting PATH work to find executable with/without sandboxing?
        command.environment = ["GOMON_LOG_LEVEL": "debug", "PATH": "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/Users/keefe/go/bin"]
        _ = NotificationCenter.default.addObserver(
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
    }

    func run(_ insert: @escaping (@MainActor @Sendable (Events) -> Void) ) async throws {
        let observer = NotificationCenter.default.addObserver(
            forName: FileHandle.readCompletionNotification,
            object: stdout.fileHandleForReading,
            queue: .current
        ) { [self] notification in
            let data = notification.userInfo?["NSFileHandleNotificationDataItem"] as! Data
            stdout.fileHandleForReading.readInBackgroundAndNotify()

            let events = Events(data: data)
            if !events.events.isEmpty {
                Task { @MainActor in
                    insert(events)
                }
            }
        }

        Task {
            for await notification in NotificationCenter.default.notifications(
                named: Process.didTerminateNotification,
//                object: nil as Any? // is there a way to recognize the specific gomon process task?
            ) {
                print("process termination notification received \(notification)")
                await NSApp.reply(toApplicationShouldTerminate: true)
                print("termination complete")

                print("GOMON EXITED, STDOUT OBSERVER FREED!!!!!")
                NotificationCenter.default.removeObserver(observer)
            }
        }

        do {
            try command.run()
            stderr.fileHandleForReading.readInBackgroundAndNotify()
            stdout.fileHandleForReading.readInBackgroundAndNotify()
            command.waitUntilExit()
        } catch {
            print(error)
            throw error
        }
    }
}

struct GomonTerminated: NotificationCenter.MainActorMessage {
    typealias Subject = ErrHandler
    let line: String
}

@Observable final class ErrMessages: Sendable {
    var messages: String = ""
}

@Observable final class ErrHandler: Sendable {
    let errMessages: ErrMessages
    init(errMessages: ErrMessages) {
        self.errMessages = errMessages
    }
}
