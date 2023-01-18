//
//  File.swift
//  
//
//  Created by M1ProMacbook-kisupark on 2023/01/17.
//

import Foundation
import Network

protocol MQTTConnectionCore {
    var state: MQTTConnectionState { get }
    
    func start() async throws
    func cancel()
    
    func publish(message: MQTTString, qos: MQTTQoS) async throws
    
    func subscribe(topics: [(MQTTString, MQTTQoS)]) async throws
    func unsubscribe(topics: [MQTTString])
}

struct MQTTConnectionCoreFactory {
    static func createCore(with parameters: MQTTConnectionParameters, internalConnection: NWConnection) -> MQTTConnectionCore {
        switch parameters.mqttProtocol {
        case .v3(let options):
            return MQTT3.ConnectionCore(connectionInfo: parameters.connectionInfo, options: options, internalConnection: internalConnection)
        case .v5(let options):
            return MQTT5.ConnectionCore(connectionInfo: parameters.connectionInfo, options: options, internalConnection: internalConnection)
        }
    }
}
