//
//  GomonEvents.swift
//  GomonChart
//
//  Created by Keefe Hayes on 12/14/25.
//

import Foundation

/// GomonEvent defines an observable for observing Messages
@Observable final class GomonEvents: Sendable {
    typealias Events = [String]
    var events = Events()
}

/// EventType identifies the source of an event: "file", "filesystem", "io", "logs", "network", "process", "system", and for the source the type of event. Sources "filesystem", "io", "network", "process", "system" report "measure" events. Source "process" also reports events of "fork", "exec", "exit". Source "file" reports events "create", "rename", "update", "delete". Source "logs" reports "debug", "info", "warn", "error", "fatal".
struct EventType: Codable & Sendable {
    let source: String
    let event: String
}
