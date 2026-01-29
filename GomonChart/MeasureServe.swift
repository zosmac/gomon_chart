//
//  MeasureServe.swift
//  GomonChart
//
//  Created by Keefe Hayes on 12/31/25.
//

import Foundation
import SwiftData

@available(macOS 26.0, *)
@Model class MeasureServe: Event {
    override func eventId() -> String {
        "\(serveId?.name ?? "")"
    }

    var serveId: ServeID?
    var address: String?     // http address of gomon's server
    var endpoints: [String]? // server endpoints
    var httpRequests: Int?
    var collections: Int?      // prometheus
    var collectionTime: Int64? // prometheus
    var lokiStreams: Int?      // loki

    enum CodingKeys: String, CodingKey, CaseIterable {
        case serveId = "event_id"
        case address
        case endpoints
        case httpRequests = "http_requests"
        case collections
        case collectionTime = "collection_time"
        case lokiStreams = "loki_streams"
    }

    struct ServeID: Codable & Sendable {
        let name: String
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        serveId = try container.decode(ServeID.self, forKey: .serveId)
        address = try container.decode(String.self, forKey: .address)
        endpoints = try container.decode([String].self, forKey: .endpoints)
        httpRequests = try container.decode(Int.self, forKey: .httpRequests)
        collections = try container.decode(Int.self, forKey: .collections)
        collectionTime = try container.decode(Int64.self, forKey: .collectionTime)
        lokiStreams = try container.decode(Int.self, forKey: .lokiStreams)
        try super.init(from: decoder)
    }

    override func encode(to encoder: any Encoder) throws {
        try super.encode(to :encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(serveId, forKey: .serveId)
        try container.encode(address, forKey: .address)
        try container.encode(endpoints, forKey: .endpoints)
        try container.encode(httpRequests, forKey: .httpRequests)
        try container.encode(collections, forKey: .collections)
        try container.encode(collectionTime, forKey: .collectionTime)
        try container.encode(lokiStreams, forKey: .lokiStreams)
    }
}

let sampleMeasureServe: String = """
{
  "timestamp": "2025-12-31T07:13:30.000925-08:00",
  "host": "Keefes-MacBook-Air.local",
  "platform": "darwin_arm64",
  "source": "serve",
  "event": "measure",
  "event_id": {
    "name": "gomon"
  },
  "address": "http://localhost:1234",
  "endpoints": [
    "metrics",
    "gomon",
    "ws",
    "assets"
  ],
  "http_requests": 0,
  "collections": 0,
  "collection_time": 137683959,
  "loki_streams": 0
}
"""
