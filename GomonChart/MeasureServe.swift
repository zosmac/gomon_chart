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
    override var eventId: String {
        "\(_eventId.name)"
    }

    var _eventId: ServeID
    var address: String     // http address of gomon's server
    var endpoints: [String] // server endpoints
    var httpRequests: Int
    var collections: Int      // prometheus
    var collectionTime: Int64 // prometheus
    var lokiStreams: Int      // loki

    enum CodingKeys: String, CodingKey, CaseIterable {
        case eventId = "event_id"
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
        self._eventId = try container.decode(ServeID.self, forKey: .eventId)
        self.address = try container.decode(String.self, forKey: .address)
        self.endpoints = try container.decode([String].self, forKey: .endpoints)
        self.httpRequests = try container.decode(Int.self, forKey: .httpRequests)
        self.collections = try container.decode(Int.self, forKey: .collections)
        self.collectionTime = try container.decode(Int64.self, forKey: .collectionTime)
        self.lokiStreams = try container.decode(Int.self, forKey: .lokiStreams)
        try super.init(from: decoder)
    }

    override func encode(to encoder: any Encoder) throws {
        try super.encode(to :encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.eventId, forKey: .eventId)
        try container.encode(self.address, forKey: .address)
        try container.encode(self.endpoints, forKey: .endpoints)
        try container.encode(self.httpRequests, forKey: .httpRequests)
        try container.encode(self.collections, forKey: .collections)
        try container.encode(self.collectionTime, forKey: .collectionTime)
        try container.encode(self.lokiStreams, forKey: .lokiStreams)
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
