//
//  MeasureProcess.swift
//  GomonChart
//
//  Created by Keefe Hayes on 12/11/25.
//

import Foundation
import SwiftData

@available(macOS 26.0, *)
@Model class MeasureProcess: Event {
    override var key: String {
        "\(eventId.name)[\(eventId.pid)]"
    }

    var eventId: ProcessID
    var ppid: Int
    var pgid: Int?
    var tgid: Int?
    var tty: String?
    var uid: Int?
    var gid: Int?
    var username: String
    var groupname: String
    var status: String
    var nice: Int?
    var executable: String // a file path
    var args: [String]
    var envs: [String: String]?
    var cwd: String // a file path
    var root: String // a file path
    var priority: Int?
    var threads: Int
    var user: Int64   // nanoseconds
    var system: Int64 // nanoseconds
    var total: Int64  // nanoseconds
    var size: Int
    var resident: Int
    var pageFaults: Int
    var contextSwitches: Int?
    var readActual: Int
    var writeActual: Int
    var writeRequested: Int?
    var connections: [Connection]?

    enum CodingKeys: String, CodingKey, CaseIterable {
        case eventId = "event_id"
        case ppid
        case pgid
        case tgid
        case tty
        case uid
        case gid
        case username
        case groupname
        case status
        case nice
        case executable // a file path
        case args
        case envs
        case cwd  // a file path
        case root // a file path
        case priority
        case threads
        case user
        case system
        case total
        case size
        case resident
        case pageFaults = "page_faults"
        case contextSwitches = "context_switches"
        case readActual = "read_actual"
        case writeActual = "write_actual"
        case writeRequested = "write_requested"
        case connections
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.eventId = try container.decode(ProcessID.self, forKey: .eventId)
        self.ppid = try container.decode(Int.self, forKey: .ppid)
        self.pgid = try? container.decode(Int.self, forKey: .pgid)
        self.tgid = try? container.decode(Int.self, forKey: .tgid)
        self.tty = try? container.decode(String.self, forKey: .tty)
        self.uid = try? container.decode(Int.self, forKey: .uid)
        self.gid = try? container.decode(Int.self, forKey: .gid)
        self.username = try container.decode(String.self, forKey: .username)
        self.groupname = try container.decode(String.self, forKey: .groupname)
        self.status = try container.decode(String.self, forKey: .status)
        self.nice = try? container.decode(Int.self, forKey: .nice)
        self.executable = try container.decode(String.self, forKey: .executable) // a file path
        self.args = try container.decode([String].self, forKey: .args)
        self.envs = try? container.decode([String: String].self, forKey: .envs)
        self.cwd = try container.decode(String.self, forKey: .cwd)  // a file path
        self.root = try container.decode(String.self, forKey: .root) // a file path
        self.priority = try? container.decode(Int.self, forKey: .priority)
        self.threads = try container.decode(Int.self, forKey: .threads)
        self.user = try container.decode(Int64.self, forKey: .user)
        self.system = try container.decode(Int64.self, forKey: .system)
        self.total = try container.decode(Int64.self, forKey: .total)
        self.size = try container.decode(Int.self, forKey: .size)
        self.resident = try container.decode(Int.self, forKey: .resident)
        self.pageFaults = try container.decode(Int.self, forKey: .pageFaults)
        self.contextSwitches = try? container.decode(Int.self, forKey: .contextSwitches)
        self.readActual = try container.decode(Int.self, forKey: .readActual)
        self.writeActual = try container.decode(Int.self, forKey: .writeActual)
        self.writeRequested = try? container.decode(Int.self, forKey: .writeRequested)
        self.connections = try? container.decode([Connection].self, forKey: .connections)
        try super.init(from: decoder)
    }

    override func encode(to encoder: any Encoder) throws {
        try super.encode(to :encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.eventId, forKey: .eventId)
        try container.encode(self.ppid, forKey: .ppid)
        try? container.encode(self.pgid, forKey: .pgid)
        try? container.encode(self.tgid, forKey: .tgid)
        try? container.encode(self.tty, forKey: .tty)
        try? container.encode(self.uid, forKey: .uid)
        try? container.encode(self.gid, forKey: .gid)
        try container.encode(self.username, forKey: .username)
        try container.encode(self.groupname, forKey: .groupname)
        try container.encode(self.status, forKey: .status)
        try? container.encode(self.nice, forKey: .nice)
        try container.encode(self.executable, forKey: .executable) // a file path
        try container.encode(self.args, forKey: .args)
        try container.encode(self.envs, forKey: .envs)
        try container.encode(self.cwd, forKey: .cwd)  // a file path
        try container.encode(self.root, forKey: .root) // a file path
        try? container.encode(self.priority, forKey: .priority)
        try container.encode(self.threads, forKey: .threads)
        try container.encode(self.user, forKey: .user)
        try container.encode(self.system, forKey: .system)
        try container.encode(self.total, forKey: .total)
        try container.encode(self.size, forKey: .size)
        try container.encode(self.resident, forKey: .resident)
        try container.encode(self.pageFaults, forKey: .pageFaults)
        try? container.encode(self.contextSwitches, forKey: .contextSwitches)
        try container.encode(self.readActual, forKey: .readActual)
        try container.encode(self.writeActual, forKey: .writeActual)
        try? container.encode(self.writeRequested, forKey: .writeRequested)
        try? container.encode(self.connections, forKey: .connections)
    }

    struct Endpoint: Codable & Sendable {
        let name: String
        let pid: Int
    }

    struct Connection: Codable & Sendable {
        let fdType: String
        let local:  Endpoint // "self"
        let remote: Endpoint // "peer"

        enum CodingKeys: String, CodingKey {
            case fdType = "type"
            case local  = "self"
            case remote = "peer"
        }
    }

    struct ProcessID: Codable & Sendable {
        let ppid: Int?
        let name: String
        let pid: Int
        let starttime: Date
    }
}

let sample: String = """
{
  "timestamp": "2025-12-11T07:40:30.013176-05:00",
  "host": "Keefes-MacBook-Air.local",
  "platform": "darwin_arm64",
  "source": "process",
  "event": "measure",
  "event_id": {
    "name": "Mail",
    "pid": 14549,
    "starttime": "2025-12-07T12:39:36.695391-05:00"
  },
  "ppid": 1,
  "pgid": 14549,
  "tty": "0XFFFFFFFF",
  "uid": 501,
  "gid": 20,
  "username": "Keefe Hayes",
  "groupname": "staff",
  "status": "Running",
  "executable": "/System/Applications/Mail.app/Contents/MacOS/Mail",
  "args": [
    "/System/Applications/Mail.app/Contents/MacOS/Mail"
  ],
  "envs": null,
  "cwd": "/Users/keefe/Library/Containers/com.apple.mail/Data",
  "root": "",
  "priority": 4,
  "threads": 10,
  "user": 190378385570,
  "system": 28417680744,
  "total": 218796066314,
  "size": 451322740736,
  "resident": 154664960,
  "page_faults": 884693,
  "context_switches": 3601784,
  "read_actual": 567029760,
  "write_actual": 186114048,
  "write_requested": 457384934,
  "connections": [
    {
      "type": "REG",
      "self": {
        "name": "",
        "pid": 14549
      },
      "peer": {
        "name": "/Users/keefe/Library/Mail/V10/MailData/Envelope Index",
        "pid": 2147485104
      }
    },
  ],
}
"""

/* a bunch of completions proposed by Xcode as I tabbed down!!
 let cpu: Double
 let memory: Double
 let swap: Double
 let io: Double
 let network: Double
 let blocked: Double
 let throttled: Double
 let iowait: Double

 let pwmxfer: Double
 let prmxfer: Double
 let pwpin: Double
 let pwpout: Double
 let prpin: Double
 let prpout: Double
 let ppsin: Double
 let ppsout: Double
 let ppserr: Double
 let ppsdrop: Double
 let ppsframe: Double
 let ppscompress: Double
 let ppsdeflate: Double
 let ppsinflate: Double
 let ppschecksum: Double
 let ppsredirect: Double
 let ppsreadahead: Double
 let ppswriteback: Double
 let ppswriteout: Double
 let ppscancelledwrite: Double
 let ppsmsghandled: Double
 let ppsmsgsent: Double
 let ppsmsgrcvd: Double
 let ppsmsgerr: Double
 let ppsmsgdrop: Double
 let ppsmsgsent6: Double
 let ppsmsgrcvd6: Double
 let ppsmsgerr6: Double
 let ppsmsgdrop6: Double
 let ppsipin: Double
 let ppsipout: Double
 let ppsipdrop: Double
 let ppsicmpin: Double
 let ppsicmpout: Double
 let ppsicmpdrop: Double
 let ppsicmperr: Double
 let ppsicmpfrag: Double
 let ppsicmpecho: Double
 let ppsicmpredirect: Double
 let ppsicmprouter: Double
 let ppsicmpnoport: Double
 let ppsicmpparam: Double
 let ppsicmpaltroute: Double
 let ppsigmpin: Double
 let ppsigmpout: Double
 let ppsigmpdrop: Double
 let ppsigmpqueries: Double
 let ppsigmpresponses: Double
 let ppsigmpquerierr: Double
 let ppsigmpquerydrop: Double
 */
