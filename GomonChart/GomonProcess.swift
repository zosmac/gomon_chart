//
//  GomonProcess.swift
//  GomonChart
//
//  Created by Keefe Hayes on 12/20/25.
//

import Foundation

actor GomonProcess {
    static let shared: GomonProcess = .init()
    let command = Process()
    let stdin = FileHandle(forReadingAtPath: "/dev/null")
    let stdout = Pipe()
    let stderr = Pipe()

    private init() {
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

    func runProcess(gomonEvents: GomonEvents) throws {
        print("INIT OBSERVER!!!!!!!!")
        let observer = NotificationCenter.default.addObserver(forName: FileHandle.readCompletionNotification, object: stdout.fileHandleForReading, queue: .current) {
            self.stdout.fileHandleForReading.readInBackgroundAndNotify() // stage for next read
            let data = $0.userInfo?["NSFileHandleNotificationDataItem"] as! Data
            let events = String(data: data, encoding: .utf8)!
                .split(separator: "\n")
                .map { String($0) }
                .filter({ $0 != "null" })
            if !events.isEmpty {
                print("====================\n\(events)\n====================")
                Task { @MainActor in
                    gomonEvents.events = events
                }
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

//    func decode() {
//        self.message = message
//                .map {
//                do {
//                    let eventType = try decoder.decode(EventType.self, from: $0)
//                    switch (eventType.source, eventType.event) {
//                    case ("process", "measure"):
//                        let measure = try decoder.decode(ProcessMeasure.self, from: $0)
//                        print(measure.total)
//                        print(measure.size)
//                        return measure
//                    default:
//                        print("unrecognized event type \(eventType)")
//                        break
//                    }
//                } catch {
//                    print("failure with ProcessMeasure", error)
//                }
//                return Data()
//            }
//    }

}
