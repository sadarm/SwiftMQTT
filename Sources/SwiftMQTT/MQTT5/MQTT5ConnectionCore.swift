//
//  File.swift
//  
//
//  Created by M1ProMacbook-kisupark on 2023/01/17.
//

import Foundation
import Network
import Combine

extension MQTT5 {
    final class ConnectionCore: MQTTConnectionCore {
        var state: MQTTConnectionState = .setup
        
        private let connectionInfo: MQTTConnectionInfo
        private let options: MQTT5.Options
        private let internalConnection: NWConnection
        
        init(connectionInfo: MQTTConnectionInfo, options: MQTT5.Options, internalConnection: NWConnection) {
            self.connectionInfo = connectionInfo
            self.options = options
            self.internalConnection = internalConnection
        }
        
        func start() async throws {
            
        }
        
        func cancel() {
            
        }
        
        
        func publish(message: MQTTString, qos: MQTTQoS) async throws {
            
        }
        
        func subscribe(topics: [(MQTTString, MQTTQoS)]) async throws {
            
        }
        
        func unsubscribe(topics: [MQTTString]) {
            
        }
    }
}


