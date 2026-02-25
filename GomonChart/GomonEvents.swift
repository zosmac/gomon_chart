//
//  GomonEvents.swift
//  GomonChart
//
//  Created by Keefe Hayes on 12/25/25.
//

import Foundation
import SwiftData
import UniformTypeIdentifiers

extension UTType {
    static var gomonEventsDocument: UTType {
        UTType(exportedAs: "com.github.zosmac.gomonevents")
    }
}

/// GomonEvents encodes and decodes JSON Gomon events, nonisolated so that it can be called from GomonProcess detached Task.
nonisolated final class GomonEvents {
    enum Kind: String, CaseIterable {
        static let allCases: [Kind] = [processCPUTime, collectionTime, event]
        case processCPUTime = "Process CPU Time"
        case collectionTime = "Collection Time"
        case event = "Event"
    }

    /// jsonDateStyle defines style to format dates consistent with the JSON encoder's date format.
    static let jsonDateStyle = Date.ISO8601FormatStyle(
        timeZoneSeparator: .colon,
        includingFractionalSeconds: true,
        timeZone: .current,
    )

    /// JSON Encoder with Date formatter to format dates consistent with jsonDateStyle used for UI displayed dates.
    static private let encoder = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .formatted(formatter)
        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes, .sortedKeys]
        return encoder
    }()

    static private let decoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    static fileprivate func encode<T: Encodable>(_ event: T) throws -> Data {
        try Self.encoder.encode(event)
    }

    static private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        try Self.decoder.decode(T.self, from: data)
    }

    static func events(data: Data) -> [Event] {
        var events = [Event]()
        do {
            events = try String(data: data, encoding: .utf8)!
                .split(separator: "\n")
                .filter { $0 != "null" }
                .map {
                    let data = Data($0.utf8)
                    let event = try Self.decode(Event.self, from: data)
                    switch (event.event, event.source) {
                    case ("measure", "process"):
                        return try Self.decode(MeasureProcess.self, from: data)
                    case ("measure", "serve"):
                        return try Self.decode(MeasureServe.self, from: data)
                    default:
                        return event
                    }
                }
        } catch {
            print("decoding events failed \(error)")
        }
        return events
    }
}

/// Event is the superclass for all Gomon events (i.e. measurements and observations)
@Model class Event: Codable {
    var _timestamp: Date?
    var host: String?
    var platform: String?
    var source: String?
    var event: String?
    var eventId: String = ""

    var timestamp: String {
        get {
            _timestamp?.formatted(GomonEvents.jsonDateStyle) ?? ""
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
        host = try container.decode(String.self, forKey: .host)
        platform = try container.decode(String.self, forKey: .platform)
        source = try container.decode(String.self, forKey: .source)
        event = try container.decode(String.self, forKey: .event)
    }

    func encode() throws -> Data {
        try GomonEvents.encode(self)
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(host, forKey: .host)
        try container.encode(platform, forKey: .platform)
        try container.encode(source, forKey: .source)
        try container.encode(event, forKey: .event)
    }
}

struct GomonEventsMigrationPlan: SchemaMigrationPlan {
    static let schemas: [VersionedSchema.Type] = [
        GomonEventsVersionedSchema.self,
    ]
    static let stages: [MigrationStage] = []
}

struct GomonEventsVersionedSchema: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)
    static let models: [any PersistentModel.Type] = [
        Event.self,
        MeasureProcess.self,
        MeasureServe.self,
    ]
}
