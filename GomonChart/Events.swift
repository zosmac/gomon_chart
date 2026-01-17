//
//  Events.swift
//  GomonChart
//
//  Created by Keefe Hayes on 12/25/25.
//

import SwiftData
import UniformTypeIdentifiers

/// jsonDateFormatter defines formatter for fomatting JSON dates consistent with jsonDateStyle used for displayed dates.
nonisolated
let jsonDateFormatter = { let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
    return formatter
}()

/// jsonDateStyle defines style for format dates to display consistent with the jsonDateFormatter used for JSON dates.
nonisolated
let jsonDateStyle = Date.ISO8601FormatStyle(
    timeZoneSeparator: .colon,
    includingFractionalSeconds: true,
    timeZone: .current,
)

enum EventKind: Int {
    case allEvents = 0, processMeasure, serveMeasure
}

nonisolated
final class Events {
    static let encoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .formatted(jsonDateFormatter)
        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes, .sortedKeys]
        return encoder
    }()

    static let decoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    var events: [Event]
    init(events: [Event]) {
        self.events = events
    }

    init(data: Data) {
        self.events = try! String(data: data, encoding: .utf8)!
            .split(separator: "\n")
            .filter { $0 != "null" }
            .map {
                let data = Data($0.utf8)
                let event = try Self.decoder.decode(Event.self, from: data)
                switch (event.event, event.source) {
                case ("measure", "process"):
                    return try Self.decoder.decode(MeasureProcess.self, from: data)
                case ("measure", "serve"):
                    return try Self.decoder.decode(MeasureServe.self, from: data)
                default:
                    return event
                }
        }
    }
}

@Model class Event: Identifiable & Codable {
    var id = UUID()
    var _timestamp: Date
    var host: String
    var platform: String
    var source: String
    var event: String
    var eventId: String { "" }

    var timestamp: String {
        get {
            _timestamp.formatted(jsonDateStyle)
        }
        set {
            _timestamp = try! Date(newValue, strategy: .iso8601)
        }
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case timestamp
        case host
        case platform
        case source
        case event
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        _timestamp = try container.decode(Date.self, forKey: .timestamp)
        self.host = try container.decode(String.self, forKey: .host)
        self.platform = try container.decode(String.self, forKey: .platform)
        self.source = try container.decode(String.self, forKey: .source)
        self.event = try container.decode(String.self, forKey: .event)
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.timestamp, forKey: .timestamp)
        try container.encode(self.host, forKey: .host)
        try container.encode(self.platform, forKey: .platform)
        try container.encode(self.source, forKey: .source)
        try container.encode(self.event, forKey: .event)
    }
}

extension UTType {
    static var gomonModelDocument: UTType {
        UTType(importedAs: "com.github.zosmac.gomonchart")
    }
}

struct GomonModelMigrationPlan: SchemaMigrationPlan {
    static let schemas: [VersionedSchema.Type] = [
        GomonModelVersionedSchema.self,
    ]

    static let stages: [MigrationStage] = [
        // Stages of migration between VersionedSchema, if required.
    ]
}

struct GomonModelVersionedSchema: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)

    static let models: [any PersistentModel.Type] = [
        Event.self, MeasureServe.self, MeasureProcess.self,
    ]
}
