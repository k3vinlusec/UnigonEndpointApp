//
//  main.swift
//  UnigonEndpointNExtension
//
//  Created by Kai Lu on 11/19/20.
//

import Foundation
import NetworkExtension
import os.log

autoreleasepool {
    NEProvider.startSystemExtensionMode()
    os_log("[*] IPCConection is starting listener...")
    IPCConnection.shared.startListener()
}

dispatchMain()
