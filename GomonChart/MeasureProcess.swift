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
    override func eventId() -> String {
        guard let processId else { return "" }
        return "\(processId.name)[\(processId.pid)]"
    }

    var processId: ProcessID?
    var ppid: Int?
    var pgid: Int?
    var tgid: Int?
    var tty: String?
    var uid: Int?
    var gid: Int?
    var username: String?
    var groupname: String?
    var status: String?
    var nice: Int?
    var executable: String? // a file path
    var args: [String]?
    var envs: [String: String]?
    var cwd: String? // a file path
    var root: String? // a file path
    var priority: Int?
    var threads: Int?
    var user: Int64?   // nanoseconds
    var system: Int64? // nanoseconds
    var total: Int64?  // nanoseconds
    var size: Int?
    var resident: Int?
    var pageFaults: Int?
    var contextSwitches: Int?
    var readActual: Int?
    var writeActual: Int?
    var writeRequested: Int?
    var connections: [Connection]?

    enum CodingKeys: String, CodingKey, CaseIterable {
        case processId = "event_id"
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
        processId = try container.decode(ProcessID.self, forKey: .processId)
        ppid = try container.decode(Int.self, forKey: .ppid)
        pgid = try? container.decode(Int.self, forKey: .pgid)
        tgid = try? container.decode(Int.self, forKey: .tgid)
        tty = try? container.decode(String.self, forKey: .tty)
        uid = try? container.decode(Int.self, forKey: .uid)
        gid = try? container.decode(Int.self, forKey: .gid)
        username = try container.decode(String.self, forKey: .username)
        groupname = try container.decode(String.self, forKey: .groupname)
        status = try container.decode(String.self, forKey: .status)
        nice = try? container.decode(Int.self, forKey: .nice)
        executable = try container.decode(String.self, forKey: .executable) // a file path
        args = try? container.decode([String].self, forKey: .args)
        envs = try? container.decode([String: String].self, forKey: .envs)
        cwd = try container.decode(String.self, forKey: .cwd)  // a file path
        root = try container.decode(String.self, forKey: .root) // a file path
        priority = try? container.decode(Int.self, forKey: .priority)
        threads = try container.decode(Int.self, forKey: .threads)
        user = try container.decode(Int64.self, forKey: .user)
        system = try container.decode(Int64.self, forKey: .system)
        total = try container.decode(Int64.self, forKey: .total)
        size = try container.decode(Int.self, forKey: .size)
        resident = try container.decode(Int.self, forKey: .resident)
        pageFaults = try container.decode(Int.self, forKey: .pageFaults)
        contextSwitches = try? container.decode(Int.self, forKey: .contextSwitches)
        readActual = try container.decode(Int.self, forKey: .readActual)
        writeActual = try container.decode(Int.self, forKey: .writeActual)
        writeRequested = try? container.decode(Int.self, forKey: .writeRequested)
        connections = try? container.decode([Connection].self, forKey: .connections)
        try super.init(from: decoder)
    }

    override func encode(to encoder: any Encoder) throws {
        try super.encode(to :encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(processId, forKey: .processId)
        try container.encode(ppid, forKey: .ppid)
        try? container.encode(pgid, forKey: .pgid)
        try? container.encode(tgid, forKey: .tgid)
        try? container.encode(tty, forKey: .tty)
        try? container.encode(uid, forKey: .uid)
        try? container.encode(gid, forKey: .gid)
        try container.encode(username, forKey: .username)
        try container.encode(groupname, forKey: .groupname)
        try container.encode(status, forKey: .status)
        try? container.encode(nice, forKey: .nice)
        try container.encode(executable, forKey: .executable) // a file path
        try? container.encode(args, forKey: .args)
        try? container.encode(envs, forKey: .envs)
        try container.encode(cwd, forKey: .cwd)  // a file path
        try container.encode(root, forKey: .root) // a file path
        try? container.encode(priority, forKey: .priority)
        try container.encode(threads, forKey: .threads)
        try container.encode(user, forKey: .user)
        try container.encode(system, forKey: .system)
        try container.encode(total, forKey: .total)
        try container.encode(size, forKey: .size)
        try container.encode(resident, forKey: .resident)
        try container.encode(pageFaults, forKey: .pageFaults)
        try? container.encode(contextSwitches, forKey: .contextSwitches)
        try container.encode(readActual, forKey: .readActual)
        try container.encode(writeActual, forKey: .writeActual)
        try? container.encode(writeRequested, forKey: .writeRequested)
        try? container.encode(connections, forKey: .connections)
    }

    struct Endpoint: Codable & Sendable {
        let name: String
        let pid: Int
    }

    struct Connection: Codable & Sendable {
        let fdType: String
        let local:  Endpoint
        let remote: Endpoint

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
