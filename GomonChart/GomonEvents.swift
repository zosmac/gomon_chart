//
//  GomonEvents.swift
//  GomonChart
//
//  Created by Keefe Hayes on 12/14/25.
//

import Foundation

struct Message: NotificationCenter.MainActorMessage {
    typealias Subject = GomonEvents
    let json: Data?
}

@Observable final class GomonEvent: Sendable {
    var json: Data?
    var any: Any?
}

struct EventType: Codable & Sendable {
    // source: "file", "filesystem", "io", "logs", "network", "process", "system"
    let source: String
    // if source == "process", event can be "measure" (i.e. a measurement) or an observation (e.g. "fork", "exec", or "exit")
    let event: String
}

@Observable final class GomonEvents: Sendable {
    let event: GomonEvent
    nonisolated let observer: NotificationCenter.ObservationToken

    init(event: GomonEvent) {
        print("Init Observer!!!!!")
        self.event = event
        self.observer = NotificationCenter.default.addObserver(
            for: Message.self
        ) {
            event.json = $0.json
            event.any = nil
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            decoder.dateDecodingStrategy = .iso8601
            var eventType: EventType
            do {
                eventType = try decoder.decode(EventType.self, from: $0.json!)
            } catch {
                print("failure with EventIdentifier", error)
                return
            }
            switch (eventType.source, eventType.event) {
                case ("process", "measure"):
                do {
                    event.any = try decoder.decode(ProcessMeasure.self, from: $0.json!)
                } catch {
                    print("failure with ProcessMeasure", error)
                }
            default:
                return
            }
        }
    }

    deinit {
        print("Free Observer!!!!!")
        NotificationCenter.default.removeObserver(observer)
    }

    func capture() {
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { timer in
            print("Five seconds have passed!")
            guard let data = sample.data(using: .utf8) else { return }
            let message = Message(json: data)
            Task { @MainActor in
                NotificationCenter.default.post(message)

                Timer.scheduledTimer(withTimeInterval: 2, repeats: false) {
                    let data = "{\n\t\"timestamp\": \"\($0.fireDate.formatted(.iso8601))\",\n\t\"source\": \"bogus\",\n\t\"event\": \"bogus\",\n\t\"event_id\": 1,\n\t\"value\": 100.0\n}".data(using: .utf8)!
                    let message = Message(json: data)
                    Task { @MainActor in
                        NotificationCenter.default.post(message)
                    }
                }
            }
        }
        _ = Observations {
            self.event
        }
    }
}
