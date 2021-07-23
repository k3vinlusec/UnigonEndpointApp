//
//  FilterDataProvider.swift
//  UnigonEndpointNExtension
//
//  Created by Kai Lu on 11/19/20.
//

import NetworkExtension
import os.log
import Darwin.bsm



extension Data {
    func hexEncodedString() -> String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
}


//It seems that NEFilterDataProvider cannot intercept the traffic from webkit like Safari, only udp works, no tcp traffic is passing through it. For network extension, apple has a whitelist of some apps itself to bypass the network extension.

class FilterDataProvider: NEFilterDataProvider {

    override func startFilter(completionHandler: @escaping (Error?) -> Void) {
        // Add code to initialize the filter.
        completionHandler(nil)
    }
    
    override func stopFilter(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        // Add code to clean up filter resources.
        completionHandler()
    }
    
    override func handleInboundData(from flow: NEFilterFlow, readBytesStartOffset offset: Int, readBytes: Data) -> NEFilterDataVerdict {
        
        //Here I need to use mutex to sync for guaranteeing all function related to pid being executed properly.
        var mutex = pthread_mutex_t()
        var mutextAttr = pthread_mutexattr_t()
        pthread_mutexattr_settype(&mutextAttr, PTHREAD_MUTEX_DEFAULT)
        
        pthread_mutex_init(&mutex, &mutextAttr)
        //pthread_mutexattr_destroy(&mutexattr)
        
        pthread_mutex_lock(&mutex)
        
        defer {
            pthread_mutex_unlock(&mutex)
            pthread_mutex_destroy(&mutex)
        }
        
        let identifier = flow.identifier.uuidString
        let buffer = readBytes.hexEncodedString()
        let count = readBytes.count
        let details = String(format: "%d %d %@", offset, count, buffer)
        var flowInfo = [String: String]()
        flowInfo = [
            FlowInfoKey.type.rawValue: String(handleInboundDataEvent),
            FlowInfoKey.timestamp.rawValue: String(Date().timeIntervalSince1970),
            FlowInfoKey.identifier.rawValue: flow.identifier.uuidString,
            FlowInfoKey.detail.rawValue: details
        ]
        
        os_log("[*] handleInboundData identifier: %{public}@ offset: %{public}d readBytes: %{public}@ readBytes.count: %{public}d", identifier, offset, buffer, count)
        
        _ = IPCConnection.shared.notifyNetworkEvent(aboutFlow: flowInfo, withCompletionHandler: { success in
            if success == false {
                os_log("[*] Failed to notify about network event")
            }
        })
        return NEFilterDataVerdict(passBytes: readBytes.count, peekBytes: Int.max)
    }
    
    override func handleOutboundData(from flow: NEFilterFlow, readBytesStartOffset offset: Int, readBytes: Data) -> NEFilterDataVerdict {
        
        //Here I need to use mutex to sync for guaranteeing all function related to pid being executed properly.
        var mutex = pthread_mutex_t()
        var mutextAttr = pthread_mutexattr_t()
        pthread_mutexattr_settype(&mutextAttr, PTHREAD_MUTEX_DEFAULT)
        
        pthread_mutex_init(&mutex, &mutextAttr)
        //pthread_mutexattr_destroy(&mutexattr)
        
        pthread_mutex_lock(&mutex)
        
        defer {
            pthread_mutex_unlock(&mutex)
            pthread_mutex_destroy(&mutex)
        }
        
        let identifier = flow.identifier.uuidString
        let buffer = readBytes.hexEncodedString()
        let count = readBytes.count
        let details = String(format: "%d %d %@", offset, count, buffer)
        var flowInfo = [String: String]()
        flowInfo = [
            FlowInfoKey.type.rawValue: String(handleOutboundDataEvent),
            FlowInfoKey.timestamp.rawValue: String(Date().timeIntervalSince1970),
            FlowInfoKey.identifier.rawValue: flow.identifier.uuidString,
            FlowInfoKey.detail.rawValue: details
        ]
        
        os_log("[*] handleOutboundData identifier: %{public}@ offset: %{public}d readBytes: %{public}@ readBytes.count: %{public}d",identifier ,offset, buffer, count)
        
        _ = IPCConnection.shared.notifyNetworkEvent(aboutFlow: flowInfo, withCompletionHandler: { success in
            if success == false {
                os_log("[*] Failed to notify about network event")
            }
        })
        
        return NEFilterDataVerdict(passBytes: readBytes.count, peekBytes: Int.max)
    }
    
    override func handleInboundDataComplete(for flow: NEFilterFlow) -> NEFilterDataVerdict {
        let result = NEFilterDataVerdict.allow()
        
        //Here I need to use mutex to sync for guaranteeing all function related to pid being executed properly.
        var mutex = pthread_mutex_t()
        var mutextAttr = pthread_mutexattr_t()
        pthread_mutexattr_settype(&mutextAttr, PTHREAD_MUTEX_DEFAULT)
        
        pthread_mutex_init(&mutex, &mutextAttr)
        //pthread_mutexattr_destroy(&mutexattr)
        
        pthread_mutex_lock(&mutex)
        
        defer {
            pthread_mutex_unlock(&mutex)
            pthread_mutex_destroy(&mutex)
        }
        
        let identifier = flow.identifier.uuidString

        var flowInfo = [String: String]()
        flowInfo = [
            FlowInfoKey.type.rawValue: String(handleInboundDataCompleteEvent),
            FlowInfoKey.timestamp.rawValue: String(Date().timeIntervalSince1970),
            FlowInfoKey.identifier.rawValue: identifier
        ]
        
        os_log("[*] handleInboundDataComplete identifier: %{public}@", identifier)
        
        _ = IPCConnection.shared.notifyNetworkEvent(aboutFlow: flowInfo, withCompletionHandler: { success in
            if success == false {
                os_log("[*] Failed to notify about network event")
            }
        })
        
        return result
    }
    
    override func handleOutboundDataComplete(for flow: NEFilterFlow) -> NEFilterDataVerdict {
        let result = NEFilterDataVerdict.allow()
        
        //Here I need to use mutex to sync for guaranteeing all function related to pid being executed properly.
        var mutex = pthread_mutex_t()
        var mutextAttr = pthread_mutexattr_t()
        pthread_mutexattr_settype(&mutextAttr, PTHREAD_MUTEX_DEFAULT)
        
        pthread_mutex_init(&mutex, &mutextAttr)
        //pthread_mutexattr_destroy(&mutexattr)
        
        pthread_mutex_lock(&mutex)
        
        defer {
            pthread_mutex_unlock(&mutex)
            pthread_mutex_destroy(&mutex)
        }
        
        let identifier = flow.identifier.uuidString

        var flowInfo = [String: String]()
        flowInfo = [
            FlowInfoKey.type.rawValue: String(handleOutboundDataCompleteEvent),
            FlowInfoKey.timestamp.rawValue: String(Date().timeIntervalSince1970),
            FlowInfoKey.identifier.rawValue: identifier
        ]
        
        os_log("[*] handleOutboundDataComplete identifier: %{public}@",identifier)
        
        _ = IPCConnection.shared.notifyNetworkEvent(aboutFlow: flowInfo, withCompletionHandler: { success in
            if success == false {
                os_log("[*] Failed to notify about network event")
            }
        })
        
        return result
    }
    
    
    
    override func handleNewFlow(_ flow: NEFilterFlow) -> NEFilterNewFlowVerdict {
        // Add code to determine if the flow should be dropped or not, downloading new rules if required.
        
        //Here I need to use mutex to sync for guaranteeing all function related to pid being executed properly.
        var mutex = pthread_mutex_t()
        var mutextAttr = pthread_mutexattr_t()
        pthread_mutexattr_settype(&mutextAttr, PTHREAD_MUTEX_DEFAULT)
        
        pthread_mutex_init(&mutex, &mutextAttr)
        //pthread_mutexattr_destroy(&mutexattr)
        
        pthread_mutex_lock(&mutex)
        
        defer {
            pthread_mutex_unlock(&mutex)
            pthread_mutex_destroy(&mutex)
        }
        
        guard let socketFlow = flow as? NEFilterSocketFlow,
            let remoteEndpoint = socketFlow.remoteEndpoint as? NWHostEndpoint,
            let localEndpoint = socketFlow.localEndpoint as? NWHostEndpoint else {
                return .allow()
        }
        
        //os_log("[*] handleNewFlow")
        
        //os_log("[*] Got a new flow with local endpoint %{public}@, remote endpoint %{public}@", localEndpoint, remoteEndpoint)
        
        //os_log("[*] Got a new flow with local endpoint （%{public}s : %{public}s）, remote endpoint （%{public}s : %{public}s, url: %{public}@, sourceAppAuditToken: %{public}@", localEndpoint.hostname,localEndpoint.port, remoteEndpoint.hostname,remoteEndpoint.port, [socketFlow.url], [socketFlow.sourceAppAuditToken])
        
        //It refers to https://developer.apple.com/forums/thread/126820, how to get pid from sourceAppAuditToken
        var sourceAppAuditTokenQ: audit_token_t? {
            guard let tokenData = socketFlow.sourceAppAuditToken,
                tokenData.count == MemoryLayout<audit_token_t>.size else {
                    return nil
                }
            return tokenData.withUnsafeBytes { buf in
                buf.baseAddress!.assumingMemoryBound(to: audit_token_t.self).pointee
            }
        }

       
        //It needs to be fixed.
        //let mem = UnsafeMutablePointer<audit_token_t>(.allocate(capacity: 1))
        //mem.initialize(from: sourceAppAuditTokenQ, count: 1)
        //getprocfullpath(UnsafeMutablePointer(mem))
        
        let pid = audit_token_to_pid(sourceAppAuditTokenQ!)
        let procInfo = getProcInfoDetail(pid)
        
        
        let proto = socketFlow.socketProtocol
        var protoDesc: String
        switch proto {
        case 1:
            protoDesc = "ICMP("+String(proto)+")"
        case 6:
            protoDesc = "TCP("+String(proto)+")"
        case 17:
            protoDesc = "UDP("+String(proto)+")"
        default:
            protoDesc = String(proto)
        }
        let dof = socketFlow.direction.rawValue
        var direction: String = ""
        if dof == 1 {
            direction = "Inbound"
        }else if dof == 2 {
            direction = "Outbound"
        }
        

        
        var flowInfo = [String: String]()
        
        if procInfo.success ==  true {
            
            let procName  = withUnsafePointer(to: procInfo.procName) {
                $0.withMemoryRebound(to: Int8.self, capacity: MemoryLayout.size(ofValue: $0)){
                    String(cString: $0)
                }
            }
            
            let fullPath  = withUnsafePointer(to: procInfo.fullPath) {
                $0.withMemoryRebound(to: Int8.self, capacity: MemoryLayout.size(ofValue: $0)){
                    String(cString: $0)
                }
            }
            
            let user = withUnsafePointer(to: procInfo.userName) {
                $0.withMemoryRebound(to: Int8.self, capacity: MemoryLayout.size(ofValue: $0)){
                    String(cString: $0)
                }
            }
            
            
           
            let details = String(format: "{\t\r\n\"processfullpath\": \"%@\",\t\r\n\"direction\": \"%@\",\t\r\n\"localendpoint\": \"%@\",\t\r\n\"remoteendpoint\": \"%@\",\t\r\n\"ppid\": \"%@\",\t\r\n\"gid\": \"%@\"\r\n}",fullPath,direction, localEndpoint.hostname+":"+localEndpoint.port,remoteEndpoint.hostname+":"+remoteEndpoint.port, String(procInfo.ppid),String(procInfo.gid))
            flowInfo = [
                FlowInfoKey.type.rawValue: String(handleNewFlowEvent),
                FlowInfoKey.timestamp.rawValue: String(Date().timeIntervalSince1970),
                FlowInfoKey.identifier.rawValue: socketFlow.identifier.uuidString,
                FlowInfoKey.process.rawValue: procName,
                FlowInfoKey.pid.rawValue: String(procInfo.pid),
                FlowInfoKey.uid.rawValue: String(procInfo.uid),
                FlowInfoKey.user.rawValue: user,
                FlowInfoKey.direction.rawValue: direction,
                FlowInfoKey.proto.rawValue: protoDesc,
                FlowInfoKey.localEndpoint.rawValue: String(localEndpoint.hostname+":"+localEndpoint.port),
                FlowInfoKey.remoteEndPoint.rawValue: String(remoteEndpoint.hostname+":"+remoteEndpoint.port),
                FlowInfoKey.detail.rawValue: details
            ]
            
        }else if procInfo.success ==  false {
            flowInfo = [
                FlowInfoKey.type.rawValue: String(handleNewFlowEvent),
                FlowInfoKey.timestamp.rawValue: String(Date().timeIntervalSince1970),
                FlowInfoKey.identifier.rawValue: socketFlow.identifier.uuidString,
                FlowInfoKey.process.rawValue: "N/A",
                FlowInfoKey.pid.rawValue: "N/A",
                FlowInfoKey.uid.rawValue: "N/A",
                FlowInfoKey.user.rawValue: "N/A",
                FlowInfoKey.direction.rawValue: direction,
                FlowInfoKey.proto.rawValue: protoDesc,
                FlowInfoKey.localEndpoint.rawValue: String(localEndpoint.hostname+":"+localEndpoint.port),
                FlowInfoKey.remoteEndPoint.rawValue: String(remoteEndpoint.hostname+":"+remoteEndpoint.port),
                FlowInfoKey.detail.rawValue: "None"
            ]
        }
        
        
        //os_log("[*] Got a new flow identifier: %{public}@  with local endpoint （%{public}s : %{public}s）, remote endpoint （%{public}s : %{public}s, url: %{public}@, direcion: %{public}@, protocol: %{public}d, sourceAppAuditToken: %{public}@, pid: %{public}d", flow.identifier.uuidString ,localEndpoint.hostname,localEndpoint.port, remoteEndpoint.hostname,remoteEndpoint.port, [socketFlow.url], direction, proto, [socketFlow.sourceAppAuditToken], pid)
        
        
        os_log("[*] Got a new flow identifier: %{public}@  with local endpoint （%{public}s:%{public}s）, remote endpoint （%{public}s:%{public}s), direcion: %{public}@, protocol: %{public}d, pid: %{public}d, procname: %{public}s, fullpath: %{public}s", flow.identifier.uuidString ,localEndpoint.hostname,localEndpoint.port, remoteEndpoint.hostname,remoteEndpoint.port,direction,proto,pid, flowInfo[FlowInfoKey.process.rawValue]!, flowInfo[FlowInfoKey.detail.rawValue]!)
        
        
        _ = IPCConnection.shared.notifyNetworkEvent(aboutFlow: flowInfo, withCompletionHandler: { success in
            if success == false {
                os_log("[*] Failed to notify about network event")
            }
        })
        //return .allow()
        
        //https://developer.apple.com/forums/thread/123170 and https://developer.apple.com/forums/thread/123829
        return NEFilterNewFlowVerdict.filterDataVerdict(withFilterInbound: true, peekInboundBytes: Int.max, filterOutbound: true, peekOutboundBytes: Int.max)
    }
}
