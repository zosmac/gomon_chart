//
//  GomonProcess.swift
//  GomonChart
//
//  Created by Keefe Hayes on 12/20/25.
//

import Foundation
import SwiftData

actor GomonProcess {
    let command = Process()
    let stdin = FileHandle(forReadingAtPath: "/dev/null")
    let stdout = Pipe()
    let stderr = Pipe()

    init() {
        // the filepath used here depends on sandboxing. Without sandboxing, use absolute path. With sandboxing, a relative path looks in the product location.
        command.executableURL = URL(filePath: "/Users/keefe/go/bin/gomon", directoryHint: .notDirectory, )
        command.arguments = ["-measures", "process", "-events", "none", "-top", "1"]
        //            process.executableURL = URL(fileURLWithPath: "/bin/sh")
        //            process.arguments = ["-c", "/Users/keefe/go/bin/gomon -measures process -events none -top 1"]
        command.standardInput = stdin
        command.standardOutput = stdout.fileHandleForWriting
        command.standardError = stderr.fileHandleForWriting
        // Does setting PATH work to find executable with/without sandboxing?
        command.environment = ["GOMON_LOG_LEVEL": "debug", "PATH": "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/Users/keefe/go/bin"]
    }

    func run(context: ModelContext) async throws {
        print("INIT OBSERVER!!!!!!!!")
        nonisolated(unsafe) let context = context // TODO: lock access? context not Sendable
        let observer = NotificationCenter.default.addObserver(
            forName: FileHandle.readCompletionNotification,
            object: stdout.fileHandleForReading,
            queue: .current
        ) { [self] notification in
            let data = notification.userInfo?["NSFileHandleNotificationDataItem"] as! Data
            Task { @MainActor in
                let measures = Measures(data: data)
                if !measures.measures.isEmpty {
                    context.insert(measures)
                }
                stdout.fileHandleForReading.readInBackgroundAndNotify()
            }
        }

        do {
            try self.command.run()
            stdout.fileHandleForReading.readInBackgroundAndNotify()
            command.waitUntilExit()
        } catch {
            print(error)
            throw error
        }

        print("FREE OBSERVER!!!!!")
        NotificationCenter.default.removeObserver(observer)
    }
}
