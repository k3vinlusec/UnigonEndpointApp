//
//  SystemExtensionLoadRequestDelegate.swift
//  UnigonEndpointApp
//
//  Created by Kai Lu on 11/20/20.
//

import Foundation
import NetworkExtension
import SystemExtensions
import os.log

class SystemExtensionLoadRequestDelegate: NSObject {
    
    var successfulExtensionLoad = false
    var sema: DispatchSemaphore?
    
    // Get the Bundle of the system extension.
    lazy var extensionBundle: Bundle = {

        let extensionsDirectoryURL = URL(fileURLWithPath: "Contents/Library/SystemExtensions", relativeTo: Bundle.main.bundleURL)
        let extensionURLs: [URL]
        do {
            extensionURLs = try FileManager.default.contentsOfDirectory(at: extensionsDirectoryURL,
                                                                        includingPropertiesForKeys: nil,
                                                                        options: .skipsHiddenFiles)
        } catch let error {
            fatalError("Failed to get the contents of \(extensionsDirectoryURL.absoluteString): \(error.localizedDescription)")
        }

        guard let extensionURL = extensionURLs.first else {
            fatalError("Failed to find any system extensions")
        }

        os_log("[*] extensionURL: %{public}@", extensionURLs)
        guard let extensionBundle = Bundle(url: extensionURL) else {
            fatalError("Failed to create a bundle with URL \(extensionURL.absoluteString)")
        }

        return extensionBundle
    }()
    /*
    func activateExtension() {
        os_log("[*] activateExtension")
        guard let extensionIdentifier = extensionBundle.bundleIdentifier else {
            return
        }

        os_log("[*] Ready to activate extension")
        // Start by activating the system extension
        let activationRequest = OSSystemExtensionRequest.activationRequest(forExtensionWithIdentifier: extensionIdentifier, queue: .main)
        
        let sema = DispatchSemaphore(value: 0)

        activationRequest.delegate = self
        OSSystemExtensionManager.shared.submitRequest(activationRequest)
        
        _ = sema.wait()
        os_log("[*] after submitRequest")
    }
    */
    
    // MARK: ProviderCommunication
    
    
    
}

extension SystemExtensionLoadRequestDelegate: OSSystemExtensionRequestDelegate {
    
    // MARK: OSSystemExtensionActivationRequestDelegate

    func request(_ request: OSSystemExtensionRequest, didFailWithError error: Error) {
        os_log("[*] System extension request failed \(error.localizedDescription.utf8CString) \((error as NSError).domain.utf8CString)")
        if sema?.signal() == 0 {
            os_log("[*] Unable to wake up response thread for system extension loading")
        }
    }
      
      
    func requestNeedsUserApproval(_ request: OSSystemExtensionRequest) {
        os_log("[*] System extension requires user approval")
    }
      
      
    func request(_ request: OSSystemExtensionRequest, actionForReplacingExtension existing: OSSystemExtensionProperties, withExtension extension: OSSystemExtensionProperties) -> OSSystemExtensionRequest.ReplacementAction {
        os_log("[*] Replacing extension %{public}@ version %@ with version %{public}@", request.identifier, existing.bundleShortVersion, `extension`.bundleShortVersion)
        successfulExtensionLoad = true
        
        if sema?.signal() == 0 {
            os_log("[*] Unable to wake up response thread for system extension loading")
        }
        return .replace
    }
      
      
    func request(_ request: OSSystemExtensionRequest, didFinishWithResult result: OSSystemExtensionRequest.Result) {
        os_log("[*] Extension %{public}@ requires user", request.identifier)
        os_log("[*] System extension activating request result: %{public}d", result.rawValue)
        
        let sharedFilterManager = NEFilterManager.shared()
        let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String
        
        sharedFilterManager.loadFromPreferences(completionHandler: { error in
            let configuration = NEFilterProviderConfiguration()
            configuration.filterSockets = true
            sharedFilterManager.providerConfiguration = configuration
            
            if appName != nil {
                sharedFilterManager.localizedDescription = appName
            }else{
                sharedFilterManager.localizedDescription = "UnigonEndpointAppFilter"
            }
            
            sharedFilterManager.isEnabled = true
            sharedFilterManager.saveToPreferences(completionHandler: {error in
                //if ((error?.localizedDescription) != nil) {
                //    os_log("[*] Unable to save system extension config")
                //}
                
                self.successfulExtensionLoad = true
                
                if self.sema?.signal() == 0 {
                    os_log("[*] Unable to wake up response thread for system extension loading")
                }
                
                IPCConnection.shared.register(withExtenson: self.extensionBundle, delegate: self, completionHandler: { success in
                    if success {
                        print("[*] Successfully registered with system extension")
                    } else {
                        print("[!] Registration with system extension failed")
                    }
                })
            
            })
        })
    }
    
}



extension SystemExtensionLoadRequestDelegate: ClientCommunication {
    
    // MARK: ClientCommunication
    func notifyNetworkEvent(aboutFlow flowInfo: [String : String], withCompletionHandler: @escaping (Bool) -> Void) {
        guard let type = flowInfo[FlowInfoKey.type.rawValue] else {
            return
        }
        
        switch Int(type) {
        case 0:
            guard let timestamp = flowInfo[FlowInfoKey.timestamp.rawValue],
                  let process = flowInfo[FlowInfoKey.process.rawValue],
                  let identifier = flowInfo[FlowInfoKey.identifier.rawValue],
                  let pid = flowInfo[FlowInfoKey.pid.rawValue],
                  let uid = flowInfo[FlowInfoKey.uid.rawValue],
                  let user = flowInfo[FlowInfoKey.user.rawValue],
                  let direction = flowInfo[FlowInfoKey.direction.rawValue],
                  let proto = flowInfo[FlowInfoKey.proto.rawValue],
                  let localEndpoint = flowInfo[FlowInfoKey.localEndpoint.rawValue],
                  let remoteEndPoint = flowInfo[FlowInfoKey.remoteEndPoint.rawValue],
                  let detail = flowInfo[FlowInfoKey.detail.rawValue] else {
                withCompletionHandler(true)
                return
            }
            DispatchQueue.main.async {
                os_log("[*] handleNewFlowEvent timestamp: %{public}@, identifier: %{public}@, process: %{public}@, pid: %{public}@, uid: %{public}@, user: %{public}@, direction: %{public}@, proto: %{public}@, localEndpoint: %{public}@, remoteEndPoint: %{public}@, detail: %{public}@ ", timestamp, identifier, process, pid, uid, user, direction, proto, localEndpoint, remoteEndPoint, detail)
                print("[*] handleNewFlowEvent timestamp: \(timestamp), identifier: \(identifier), process:  \(process), pid: \(pid), uid:  \(uid), user:  \(user), direction: \(direction), proto: \(proto), localEndpoint:  \(localEndpoint), remoteEndPoint: \(remoteEndPoint), detail: \(detail)")
                
                var dbRecord = [String: String]()
                dbRecord = [
                    DBRecordKey.timestamp.rawValue: timestamp,
                    DBRecordKey.event.rawValue: String(format: "Network(%@ %@)",direction,proto),
                    DBRecordKey.process.rawValue: process,
                    DBRecordKey.pid.rawValue: pid,
                    DBRecordKey.uid.rawValue: uid,
                    DBRecordKey.user.rawValue: user,
                    DBRecordKey.message.rawValue: detail,
                    DBRecordKey.traffic.rawValue: "",
                    DBRecordKey.inboundcomplete.rawValue: "0",
                    DBRecordKey.outboundcomplete.rawValue: "0",
                    DBRecordKey.identifier.rawValue: identifier
                ]
                
                insertDB(db!, dbRecord)
            }
            
        case 1:
            guard let timestamp = flowInfo[FlowInfoKey.timestamp.rawValue],
                  let identifier = flowInfo[FlowInfoKey.identifier.rawValue],
                  let detail = flowInfo[FlowInfoKey.detail.rawValue] else {
                withCompletionHandler(true)
                return
            }
            DispatchQueue.main.async {
                os_log("[*] handleInboundDataEvent timestamp: %{public}@, identifier: %{public}@, detail: %{public}@ ", timestamp, identifier, detail)
                //print("[*] handleInboundDataEvent timestamp: \(timestamp), identifier: \(identifier), detail: \(detail)")
                
                let ret = queryDB(String(format: "SELECT traffic FROM ungionendpoint WHERE identifier = '%@';", identifier), db!, identifier)
                var traffic = ""
                if ret.0 == true {
                    traffic = ret.1
                }else{
                    return
                }
                
                let updateTraffic = traffic + "\r\n[IN<---]\r\n"+detail
                let updateTrafficString = String(format: "UPDATE ungionendpoint SET traffic = '%@' WHERE  identifier = '%@';", updateTraffic, identifier )
                updateDB(db!,updateTrafficString)
            }
            
        case 2:
            guard let timestamp = flowInfo[FlowInfoKey.timestamp.rawValue],
                  let identifier = flowInfo[FlowInfoKey.identifier.rawValue],
                  let detail = flowInfo[FlowInfoKey.detail.rawValue] else {
                withCompletionHandler(true)
                return
            }
            DispatchQueue.main.async {
                os_log("[*] handleOutboundDataEvent timestamp: %{public}@, identifier: %{public}@, detail: %{public}@ ", timestamp, identifier, detail)
                //print("[*] handleOutboundDataEvent timestamp: \(timestamp), identifier: \(identifier), detail: \(detail)")
                
                let ret = queryDB(String(format: "SELECT traffic FROM ungionendpoint WHERE identifier = '%@';", identifier), db!, identifier)
                var traffic = ""
                if ret.0 == true {
                    traffic = ret.1
                }else{
                    return
                }
                
                let updateTraffic = traffic + "\r\n[OUT--->]\r\n"+detail
                let updateTrafficString = String(format: "UPDATE ungionendpoint SET traffic = '%@' WHERE  identifier = '%@';", updateTraffic, identifier )
                updateDB(db!,updateTrafficString)
            }
            
        case 3:
            guard let timestamp = flowInfo[FlowInfoKey.timestamp.rawValue],
                  let identifier = flowInfo[FlowInfoKey.identifier.rawValue] else {
                withCompletionHandler(true)
                return
            }
            DispatchQueue.main.async {
                os_log("[*] handleInboundDataCompleteEvent timestamp: %{public}@, identifier: %{public}@", timestamp, identifier)
                //print("[*] handleInboundDataCompleteEvent timestamp: \(timestamp), identifier: \(identifier)")
                
                let updateString = String(format: "UPDATE ungionendpoint SET inboundcomplete = '1' WHERE  identifier = '%@';",identifier )
                updateDB(db!,updateString)
            }
            
            
            
        case 4:
            guard let timestamp = flowInfo[FlowInfoKey.timestamp.rawValue],
                  let identifier = flowInfo[FlowInfoKey.identifier.rawValue] else {
                withCompletionHandler(true)
                return
            }
            DispatchQueue.main.async {
                os_log("[*] handleOutboundDataCompleteEvent timestamp: %{public}@, identifier: %{public}@", timestamp, identifier)
                //print("[*] handleOutboundDataCompleteEvent timestamp: \(timestamp), identifier: \(identifier)")
                
                let updateString = String(format: "UPDATE ungionendpoint SET outboundcomplete = '1' WHERE identifier = '%@';",identifier )
                updateDB(db!,updateString)
            }
        default: break
            
        }
        
    }
    
}

class SystemExtensionUnloadRequestDelegate: NSObject {
    var successfulExtensionUnload = false
    var sema: DispatchSemaphore?
}


extension SystemExtensionUnloadRequestDelegate: OSSystemExtensionRequestDelegate {
    
    func request(_ request: OSSystemExtensionRequest, actionForReplacingExtension existing: OSSystemExtensionProperties, withExtension ext: OSSystemExtensionProperties
        ) -> OSSystemExtensionRequest.ReplacementAction {
            successfulExtensionUnload = false
        if 0 == self.sema?.signal() {
                os_log("[*] Unable to wake up response thread for system extension unloading")
            }

            return .cancel
        }
    
    
    func request(_ request: OSSystemExtensionRequest, didFailWithError error: Error) {
        os_log("[*] System extension request failed \(error.localizedDescription.utf8CString) \((error as NSError).domain.utf8CString)")
        
        successfulExtensionUnload = false
        if 0 == self.sema?.signal() {
            os_log("[*] Unable to wake up response thread for system extension unloading")
        }
    }
    
    func request(_ request: OSSystemExtensionRequest, didFinishWithResult result: OSSystemExtensionRequest.Result) {
        successfulExtensionUnload = true
        if .willCompleteAfterReboot == result {
            os_log("[*] System extension will be fully unloaded after reboot")
        }

        if 0 == self.sema?.signal() {
            os_log("[*] Unable to wake up response thread for system extension unloading")
        }
    }

    func requestNeedsUserApproval(_ request: OSSystemExtensionRequest) {
        os_log("[*] Waiting on user approval...")
    }
}


