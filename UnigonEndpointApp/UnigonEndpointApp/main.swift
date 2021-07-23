//
//  main.swift
//  UnigonEndpointApp
//
//  Created by Kai Lu on 11/21/20.
//

//
//  main.swift
//  UnigonEndpointApp
//
//  Created by Kai Lu on 11/20/20.
//

import Foundation
import NetworkExtension
import SystemExtensions
import os.log

func InstallSystemExtension() -> Bool {
    
    let systemExtensionLoadRequestDelegate = SystemExtensionLoadRequestDelegate()
    let extensionBundle = systemExtensionLoadRequestDelegate.extensionBundle
    guard let extensionIdentifier = extensionBundle.bundleIdentifier else {
        return false
    }
    
    os_log("[*] InstallSystemExtension")
    // Start by activating the system extension
    let activationRequest = OSSystemExtensionRequest.activationRequest(forExtensionWithIdentifier: extensionIdentifier, queue: DispatchQueue.main)
    
    systemExtensionLoadRequestDelegate.successfulExtensionLoad = false
    systemExtensionLoadRequestDelegate.sema = DispatchSemaphore(value: 0)


    activationRequest.delegate = systemExtensionLoadRequestDelegate
    OSSystemExtensionManager.shared.submitRequest(activationRequest)
    
    _ = systemExtensionLoadRequestDelegate.sema?.wait(timeout: DispatchTime.distantFuture)
    
    return systemExtensionLoadRequestDelegate.successfulExtensionLoad
}



func UninstallSystemExtension() -> Bool {
    let systemExtensionLoadRequestDelegate = SystemExtensionLoadRequestDelegate()
    let extensionBundle = systemExtensionLoadRequestDelegate.extensionBundle
    guard let extensionIdentifier = extensionBundle.bundleIdentifier else {
        return false
    }
    
    os_log("[*] UninstallSystemExtension")
    let deactivationRequest = OSSystemExtensionRequest.deactivationRequest(forExtensionWithIdentifier: extensionIdentifier, queue: DispatchQueue.main)

    let systemExtensionUnloadRequestDelegate = SystemExtensionUnloadRequestDelegate()
    
    systemExtensionUnloadRequestDelegate.successfulExtensionUnload = false
    systemExtensionUnloadRequestDelegate.sema = DispatchSemaphore(value: 0)
    
    deactivationRequest.delegate = systemExtensionUnloadRequestDelegate
    OSSystemExtensionManager.shared.submitRequest(deactivationRequest)

    _ = systemExtensionUnloadRequestDelegate.sema?.wait(timeout: DispatchTime.distantFuture)
    
    return systemExtensionUnloadRequestDelegate.successfulExtensionUnload
}

//print("[*] UnigonEndpointApp entrypoint...")

let argc = CommandLine.argc
let argv = CommandLine.arguments
var db: OpaquePointer?

//print("[*] argc=\(argc)")
//print("[*] argv=\(argv)")
if argc == 2 {
    
    autoreleasepool {
    
        DispatchQueue.global(qos: .default).async(execute:  {
            
            var result = EINVAL
            autoreleasepool {
                os_log("[*] argv: %{public}@", argv)
                if argv[1] == "--load" {
                    var dbPath = ""
                    if let libraryPathString = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first {
                        let pathURL = URL(fileURLWithPath: libraryPathString).appendingPathComponent("unigonendpoint.sqlite")
                        dbPath = pathURL.path
                    }
                    
                    db = openDatabase(dbPath)
                    
                    guard db != nil else {
                        exit(result)
                    }
                    
                    createTable(db!)
                    
                    result = InstallSystemExtension() == true ? 0 : -1
                    //exit(result)
                }else if argv[1] == "--unload" {
                    result = UninstallSystemExtension() == true ? 0 : -1
                    
                    var dbPath = ""
                    if let libraryPathString = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first {
                        let pathURL = URL(fileURLWithPath: libraryPathString).appendingPathComponent("unigonendpoint.sqlite")
                        dbPath = pathURL.path
                    }
                    
                    let fileManager = FileManager.default
                    do {
                        let fileURL = NSURL(fileURLWithPath: dbPath)
                        try fileManager.removeItem(at: fileURL as URL)
                        print("[*] db file \(dbPath) has been deleted")
                        
                    } catch let error as NSError {
                        print("[!] Error: \(error.domain)")
                    }
                    exit(result)
                }else{
                    exit(result)
                }
            }
        })
        
        defer {
            closeDatabase(db!)
        }
        dispatchMain()
    }
}else {
    print("[*] Start Service: /Applications/UnigonEndpointApp.app/Contents/MacOS/UnigonEndpointApp  --load")
    print("[*] Stop Service:  /Applications/UnigonEndpointApp.app/Contents/MacOS/UnigonEndpointApp  --unload")
}

//print("[*] UnigonEndpointApp exit...")






