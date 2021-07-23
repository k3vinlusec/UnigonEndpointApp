//
//  SharedIPC.swift
//  UnigonEndpointNExtension
//
//  Created by Kai Lu on 11/19/20.
//

import Foundation
import os.log
import Network

/// Provider --> App IPC
@objc protocol ClientCommunication {

    func notifyNetworkEvent(aboutFlow flowInfo: [String: String], withCompletionHandler: @escaping (Bool) -> Void)
}

/// App --> Provider IPC
@objc protocol ProviderCommunication {

    func registerWithCompletionHandler(_ completionHandler: @escaping (Bool) -> Void)
}

enum FlowInfoKey: String {
    case type
    case timestamp
    case identifier
    case process
    case pid
    case uid
    case user
    case direction
    case proto
    case localEndpoint
    case remoteEndPoint
    case detail
}

//Five types of flowInfo
let handleNewFlowEvent = 0
let handleInboundDataEvent = 1
let handleOutboundDataEvent = 2
let handleInboundDataCompleteEvent = 3
let handleOutboundDataCompleteEvent = 4


class IPCConnection: NSObject {
     
    // MARK: Properties
    var listener: NSXPCListener?
    var currentConnection: NSXPCConnection?
    weak var delegate: ClientCommunication?
    static let shared = IPCConnection()
    
    private func extensionMachServiceName(from bundle: Bundle) -> String {
        guard let networkExtensionKeys = bundle.object(forInfoDictionaryKey: "NetworkExtension") as? [String: Any],
              let machServiceName = networkExtensionKeys["NEMachServiceName"] as? String else{
            fatalError("[*] Mach service name is missing from the Info.plist")
        }
        return machServiceName
    }
    
    func startListener() {
        let machServiceName = extensionMachServiceName(from: Bundle.main)
        os_log("[*] Starting XPC listener for mach service %{public}@", machServiceName)
        let newListener = NSXPCListener(machServiceName: machServiceName)
        newListener.delegate = self
        newListener.resume()
        listener = newListener
    }
    
    func register(withExtenson bundle: Bundle, delegate: ClientCommunication, completionHandler: @escaping (Bool) -> Void) {
        
        os_log("[*] Register...")
        self.delegate = delegate
        
        guard currentConnection == nil else {
            os_log("[*] Already registered with the provider")
            completionHandler(true)
            return
        }

        let machServiceName = extensionMachServiceName(from: bundle)
        os_log("[*] machServiceName: %{public}@", machServiceName)
        let newConnection = NSXPCConnection(machServiceName: machServiceName, options: [])

        // The exported object is the delegate.
        newConnection.exportedInterface = NSXPCInterface(with: ClientCommunication.self)
        newConnection.exportedObject = delegate

        // The remote object is the provider's IPCConnection instance.
        newConnection.remoteObjectInterface = NSXPCInterface(with: ProviderCommunication.self)

        currentConnection = newConnection
        
        os_log("[*] currentConnection: %{public}@", currentConnection!)
        newConnection.resume()

        guard let providerProxy = newConnection.remoteObjectProxyWithErrorHandler({ registerError in
            os_log("[*] Failed to register with the provider: %{public}@", registerError.localizedDescription)
            self.currentConnection?.invalidate()
            self.currentConnection = nil
            completionHandler(false)
        }) as? ProviderCommunication else {
            fatalError("[*] Failed to create a remote object proxy for the provider")
        }

        providerProxy.registerWithCompletionHandler(completionHandler)
        
    }
    
    func notifyNetworkEvent(aboutFlow flowInfo: [String: String], withCompletionHandler: @escaping (Bool) -> Void) -> Bool {
        
        os_log("[*] notifyNetworkEvent")
        guard let connection = currentConnection else {
            os_log("[*] Cannot notify network event because the app isn't registered")
            return false
        }

        guard let appProxy = connection.remoteObjectProxyWithErrorHandler({ promptError in
            os_log("[*] Failed to notify network event: %{public}@", promptError.localizedDescription)
            self.currentConnection = nil
            withCompletionHandler(true)
        }) as? ClientCommunication else {
            fatalError("[*] Failed to create a remote object proxy for the app")
        }

        appProxy.notifyNetworkEvent(aboutFlow: flowInfo, withCompletionHandler: withCompletionHandler)

        return true
    }
}

extension IPCConnection: NSXPCListenerDelegate {

    // MARK: NSXPCListenerDelegate

    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {

        // The exported object is this IPCConnection instance.
        newConnection.exportedInterface = NSXPCInterface(with: ProviderCommunication.self)
        newConnection.exportedObject = self

        // The remote object is the delegate of the app's IPCConnection instance.
        newConnection.remoteObjectInterface = NSXPCInterface(with: ClientCommunication.self)

        newConnection.invalidationHandler = {
            self.currentConnection = nil
        }

        newConnection.interruptionHandler = {
            self.currentConnection = nil
        }

        self.currentConnection = newConnection
        newConnection.resume()

        return true
    }
}

extension IPCConnection: ProviderCommunication {
    func registerWithCompletionHandler(_ completionHandler: @escaping (Bool) -> Void) {
        os_log("[*] App registered")
        completionHandler(true)
    }
    
}
