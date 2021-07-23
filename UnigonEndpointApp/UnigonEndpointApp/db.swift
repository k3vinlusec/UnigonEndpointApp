//
//  db.swift
//  UnigonEndpointApp
//
//  Created by Kai Lu on 11/30/20.
//

import Foundation
import SQLite3



internal let SQLITE_STATIC = unsafeBitCast(0, to: sqlite3_destructor_type.self)
internal let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

func openDatabase(_ dbPath: String) -> OpaquePointer? {
    var db: OpaquePointer?
    if dbPath == "" {
        print("[*] dbPath is nil")
        return nil
    }
  
    if sqlite3_open(dbPath, &db) == SQLITE_OK {
        print("[*] Successfully opened connection to database at \(dbPath)")
        return db
    } else {
        print("[!] Unable to open database.")
        return nil
  }
}

func closeDatabase(_ db: OpaquePointer) {
    if sqlite3_close(db) == SQLITE_OK {
        print("[*] Successfully close connection to database")
    } else {
        print("[!] Unable to close database.")
    }
    
}

func createTable(_ db: OpaquePointer) {
    
    var createTableStatement: OpaquePointer?
    if sqlite3_prepare_v2(db, createTableString, -1, &createTableStatement, nil) == SQLITE_OK {
        if sqlite3_step(createTableStatement) == SQLITE_DONE {
          print("[*] ungionendpoint table created.")
        } else {
          print("[!] ungionendpoint table is not created.")
        }
    } else {
        print("[!] CREATE TABLE statement is not prepared.")
    }
    sqlite3_finalize(createTableStatement)
}

let createTableString = """
CREATE TABLE "ungionendpoint" (
    "timestamp"    TEXT,
    "event"    TEXT,
    "process"    TEXT,
    "pid"    TEXT,
    "uid"    TEXT,
    "user"    TEXT,
    "message"    TEXT,
    "traffic"    TEXT,
    "inboundcomplete"    TEXT,
    "outboundcomplete"    TEXT,
    "identifier"    TEXT NOT NULL,
    PRIMARY KEY("identifier")
);
"""

enum DBRecordKey: String {
    case timestamp
    case event
    case process
    case pid
    case uid
    case user
    case message
    case traffic
    case inboundcomplete
    case outboundcomplete
    case identifier
}

func queryDB(_ queryString: String, _ db: OpaquePointer, _ identifier: String) -> (Bool, String) {
    
    var result = false
    var traffic = ""
    var queryStatement: OpaquePointer?
    if sqlite3_prepare_v2(db, queryString, -1, &queryStatement, nil) == SQLITE_OK {
        if sqlite3_step(queryStatement) == SQLITE_ROW {
            guard let trafficCString = sqlite3_column_text(queryStatement, 0) else {
                print(String(cString: sqlite3_errmsg(db)))
                return (result, traffic)
            }
            traffic = String(cString: trafficCString)
            result = true
        } else {
                print("[!] \(identifier) query no results")
        }
    } else {
        let errorMessage = String(cString: sqlite3_errmsg(db))
        print("[!] Query is not prepared \(errorMessage)")
    }
    sqlite3_finalize(queryStatement)
    return (result, traffic)
}

func insertDB(_ db: OpaquePointer, _ dbRecord: [String : String]) {
    
    let insertRowString = "INSERT INTO ungionendpoint (timestamp, event, process, pid, uid, user, message, traffic, inboundcomplete, outboundcomplete, identifier) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);"
    var insertStatement: OpaquePointer?
        
    if sqlite3_prepare_v2(db, insertRowString, -1, &insertStatement, nil) == SQLITE_OK {
        
        sqlite3_bind_text(insertStatement, 1, dbRecord[DBRecordKey.timestamp.rawValue], -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(insertStatement, 2, dbRecord[DBRecordKey.event.rawValue], -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(insertStatement, 3, dbRecord[DBRecordKey.process.rawValue], -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(insertStatement, 4, dbRecord[DBRecordKey.pid.rawValue], -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(insertStatement, 5, dbRecord[DBRecordKey.uid.rawValue], -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(insertStatement, 6, dbRecord[DBRecordKey.user.rawValue], -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(insertStatement, 7, dbRecord[DBRecordKey.message.rawValue], -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(insertStatement, 8, dbRecord[DBRecordKey.traffic.rawValue], -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(insertStatement, 9, dbRecord[DBRecordKey.inboundcomplete.rawValue], -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(insertStatement, 10, dbRecord[DBRecordKey.outboundcomplete.rawValue], -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(insertStatement, 11, dbRecord[DBRecordKey.identifier.rawValue], -1, SQLITE_TRANSIENT)
        
        if sqlite3_step(insertStatement) == SQLITE_DONE {
            //print("[*] Insert data successfully")
        } else {
            print("[!] Insert data failed")
        }
    } else {
        print("[!] INSERT statement is not prepared.")
    }

    sqlite3_finalize(insertStatement)

}


func updateDB(_ db: OpaquePointer, _ updateTrafficString: String) {
    var updateStatement: OpaquePointer?
    if sqlite3_prepare_v2(db, updateTrafficString, -1, &updateStatement, nil) == SQLITE_OK {
       if sqlite3_step(updateStatement) == SQLITE_DONE {
         //print("[*] Successfully updated row.")
       } else {
         print("[!] Could not update row.")
       }
     } else {
       print("[!] UPDATE statement is not prepared")
     }
     sqlite3_finalize(updateStatement)
}

func handleDB() {
    var dbPath = ""
    if let libraryPathString = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first {
        let pathURL = URL(fileURLWithPath: libraryPathString).appendingPathComponent("unigonendpoint.sqlite")
        dbPath = pathURL.path
    }
    
    guard let db = openDatabase(dbPath) else { return }
    createTable(db)
    
    var flowInfo = [String: String]()
    flowInfo = [
        FlowInfoKey.timestamp.rawValue: "1606804462.116342",
        FlowInfoKey.identifier.rawValue: "D89B5B5D-793C-4940-C09D-010154DF1500",
        FlowInfoKey.process.rawValue: "ControlCenter",
        FlowInfoKey.pid.rawValue: "479",
        FlowInfoKey.uid.rawValue: "501",
        FlowInfoKey.direction.rawValue: "outbound",
        FlowInfoKey.proto.rawValue: "UDP(17)",
        FlowInfoKey.localEndpoint.rawValue: "0.0.0.0:0",
        FlowInfoKey.remoteEndPoint.rawValue: "192.168.1.1:53",
        FlowInfoKey.detail.rawValue: "procfullpath: /System/Library/CoreServices/ControlCenter.app/Contents/MacOS/ControlCenter, ppid: 1, gid: 20"
        
    ]
    //insertDB(db, flowInfo)
    
    let queryString = "SELECT traffic FROM ungionendpoint WHERE identifier = '%@';"
    let updateString = "UPDATE ungionendpoint SET traffic = '%@' WHERE  identifier = '%@';"
    
    let ret = queryDB("SELECT traffic FROM ungionendpoint WHERE identifier = 'D89B5B5D-793C-4940-C09D-010154DF1500';", db, "D89B5B5D-793C-4940-C09D-010154DF1500")
    var traffic = ""
    if ret.0 == true {
        traffic = ret.1
        print("traffic: \(traffic)")
    }else{
        print("false")
    }
    
    var updateTraffic = traffic + "\r\n[inbound]"
    let identifier = "D89B5B5D-793C-4940-C09D-010154DF1500"
    let updateTrafficString = String(format: "UPDATE ungionendpoint SET traffic = '%@' WHERE  identifier = '%@';", updateTraffic, identifier )
    updateDB(db,updateTrafficString)
}



