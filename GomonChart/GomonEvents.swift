//
//  GomonEvents.swift
//  GomonChart
//
//  Created by Keefe Hayes on 12/14/25.
//

import Foundation

/// Message delivers the JSON from the gomon process.
struct Message: NotificationCenter.MainActorMessage {
    typealias Subject = GomonEvents
    typealias Payload = [String]
    let payload: Payload
}

/// GomonEvent defines an observable for observing Messages
@Observable final class GomonEvents: Sendable {
    var message = Message.Payload()
}

/// EventType identifies the source of an event: "file", "filesystem", "io", "logs", "network", "process", "system", and for the source the type of event. Sources "filesystem", "io", "network", "process", "system" report "measure" events. Source "process" also reports events of "fork", "exec", "exit". Source "file" reports events "create", "rename", "update", "delete". Source "logs" reports "debug", "info", "warn", "error", "fatal".
struct EventType: Codable & Sendable {
    let source: String
    let event: String
}
