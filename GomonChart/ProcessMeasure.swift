//
//  ProcessMeasure.swift
//  GomonChart
//
//  Created by Keefe Hayes on 12/11/25.
//

import Foundation

struct ProcessMeasure: Codable & Sendable {
    let timestamp: Date
    let host: String
    let platform: String
    let source: String
    let event: String
    let eventId: ProcessID
    let ppid: Int
    let pgid: Int
    let tty: String
    let uid: Int
    let gid: Int
    let username: String
    let groupname: String
    let status: String
    let executable: String // a file path
    let args: [String]?
    let envs: [String: String]?
    let cwd: String // a file path
    let root: String // a file path
    let priority: Int
    let threads: Int
    let user: UInt64
    let system: UInt64
    let total: UInt64
    let size: UInt64
    let resident: UInt64
    let pageFaults: UInt64
    let contextSwitches: UInt64
    let readActual: UInt64
    let writeActual: UInt64
    let writeRequested: UInt64
    let connections: [Connection]

    struct Endpoint: Codable & Sendable {
        let name: String
        let pid: Int
    }

    struct Connection: Codable & Sendable {
        let fdType: String
        let local: Endpoint // "self"
        let remote: Endpoint // "peer"

        enum CodingKeys: String, CodingKey {
            case fdType = "type"
            case local = "self"
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

nonisolated
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
