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
    case allEvents = 0, processMeasure, serverMeasure
}

@Model class Events: Codable & Identifiable & CustomStringConvertible {
    static private let encoder = {
        let encoder = JSONEncoder()
//        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .formatted(jsonDateFormatter)
        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes, .sortedKeys]
        return encoder
    }()

    static private let decoder = {
        let decoder = JSONDecoder()
//        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    var timestamp = Date()
    var id: Date { timestamp }
    var events: [Event]
    var description: String {
        timestamp.formatted(jsonDateStyle)
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case events
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.events = try container.decode([Event].self, forKey: .events)
    }

    init(data: Data) {
        self.events = [Event]()
        decode(data: data)
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.events, forKey: .events)
    }

    func encode() throws -> Data {
        try Self.encoder.encode(self)
    }

    func decode(data: Data) {
        let datas = String(data: data, encoding: .utf8)!
            .split(separator: "\n")
            .map { String($0) }
            .filter { $0 != "null" }
            .map { Data($0.utf8) }
        do {
            for data in datas {
                let eventKind = try Self.decoder.decode(Event.self, from: data)
                switch (eventKind.event, eventKind.source) {
                case ("measure", "process"):
                    events.append(try Self.decoder.decode(MeasureProcess.self, from: data))
                case ("measure", "serve"):
                    events.append(try Self.decoder.decode(MeasureServe.self, from: data))
                default:
                    events.append(eventKind)
                }
            }
        } catch {
            print("error \(error) decoding \(data)")
        }
    }

    var data: Data {
        get {
            try! encode()
        }
        set {
            decode(data: newValue)
        }
    }
}

@Model class Event: Identifiable & Codable {
    var id = UUID()
    var timestamp: Date
    var host: String
    var platform: String
    var source: String
    var event: String

    enum CodingKeys: String, CodingKey, CaseIterable {
        case timestamp
        case host
        case platform
        case source
        case event
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.timestamp = try container.decode(Date.self, forKey: .timestamp)
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
        Events.self, Event.self, MeasureServe.self, MeasureProcess.self,
    ]
}
