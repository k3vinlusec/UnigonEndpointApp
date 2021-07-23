//
//  IPCConnectionDelegate.swift
//  UnigonEndpointApp
//
//  Created by Kai Lu on 11/24/20.
//

import Foundation


class IPCConnectionDelegate: NSObject {
    
}

extension IPCConnectionDelegate: ClientCommunication {
    func notifyNetworkEvent(aboutFlow flowInfo: [String : String], withCompletionHandler: @escaping (Bool) -> Void) {
        
    }
    
}
