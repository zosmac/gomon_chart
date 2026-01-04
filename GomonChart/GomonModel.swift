//
//  GomonModel.swift
//  GomonChart
//
//  Created by Keefe Hayes on 12/25/25.
//

import SwiftData
import UniformTypeIdentifiers

@Model class Measures: Codable & Identifiable {
    static func latestMeasures() -> Predicate<Measures> {
        let currentDate = Date.now - 600
        return #Predicate<Measures> {
            $0.timestamp > currentDate
        }
    }

    static private let encoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes, .sortedKeys]
        return encoder
    }()

    static private let decoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    var timestamp = Date()
    var id: Date { timestamp }
    var measures: [Measure]
    init(measures: [Measure]) {
        self.measures = measures
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case measures
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.measures = try container.decode([Measure].self, forKey: .measures)
    }

    convenience init(data: Data) {
        self.init(measures: [])
        try? decode(data: data)
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.measures, forKey: .measures)
    }

    func encode() throws -> Data {
        try Self.encoder.encode(self)
    }

    func decode(data: Data) throws {
        var measures = [Measure]()
        let events = String(data: data, encoding: .utf8)!
            .split(separator: "\n")
            .map { String($0) }
            .filter { $0 != "null" }
            .map { Data($0.utf8) }
        for event in events {
            let measure = try Self.decoder.decode(Measure.self, from: event)
            switch (measure.event, measure.source) {
            case ("measure", "process"):
                measures.append(try Self.decoder.decode(MeasureProcess.self, from: event))
            case ("measure", "serve"):
                measures.append(try Self.decoder.decode(MeasureServe.self, from: event))
            default:
                measures.append(measure)
            }
        }
        self.measures = measures
    }

    var data: Data {
        get {
            try! encode()
        }
        set {
            try? decode(data: newValue)
        }
    }
}

@Model class Measure: Identifiable & Codable {
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
        Measures.self, Measure.self, MeasureServe.self, MeasureProcess.self,
    ]
}
