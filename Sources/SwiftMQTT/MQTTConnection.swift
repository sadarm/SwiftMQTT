//
//  File.swift
//  
//
//  Created by kisu park on 2023/01/07.
//

import Foundation
import Network
import Combine

public enum MQTTConnectionState {
    case setup
    case preparing
    case ready
    case waiting(SwiftMQTTError)
    case failed(SwiftMQTTError)
    case cancelled
}

public protocol MQTTConnectionProtocol {
    var host: String { get }
    var port: UInt16 { get }
    var clientID: String { get }
    var username: String? { get }
    var password: String? { get }
    var cleanStart: Bool { get }
    var keepAlive: UInt16 { get }
    var state: MQTTConnectionState { get }
    
    func start() async throws
    func stop()
    
    func subscribeTopics(_ topics: [(String, MQTTQoS)]) async throws
    func unsubscribeTopics(_ topics: [String])
}

public final class MQTTConnection: MQTTConnectionProtocol {

    private var cancellables: Set<AnyCancellable> = []
    
    public let parameters: MQTTConnectionParameters
    
    public let host: String
    public let port: UInt16
    public var clientID: String { self.parameters.connectionInfo.clientID }
    public var username: String? { self.parameters.connectionInfo.username }
    public var password: String? { self.parameters.connectionInfo.password }
    public var cleanStart: Bool { self.parameters.connectionInfo.cleanStart }
    public var keepAlive: UInt16 { self.parameters.connectionInfo.keepAlive }
    
    public var state: MQTTConnectionState { self.core.state }
    
    private let core: MQTTConnectionCore
    
    deinit {
        self.stop()
    }
    
    public init(host: String, port: UInt16, using parameters: MQTTConnectionParameters) {
        self.host = host
        self.port = port
        self.parameters = parameters
        
        let internalConnection = NWConnection(host: NWEndpoint.Host(host),
                                               port: NWEndpoint.Port(integerLiteral: port),
                                               using: .tcp)
        self.core = MQTTConnectionCoreFactory.createCore(with: self.parameters, internalConnection: internalConnection)
    }
    
    public func start() async throws {
        try await self.core.start()
    }
    
    public func stop() {
        self.core.cancel()
    }
    
    public func subscribeTopics(_ topics: [(String, MQTTQoS)]) async throws {
        try await self.core.subscribe(topics: topics.map { (MQTTString($0.0), $0.1) })
    }
    
    public func unsubscribeTopics(_ topics: [String]) {
        self.core.unsubscribe(topics: topics.map { MQTTString($0) })
    }
}

public struct MQTTConnectionParameters {
    public var connectionInfo: MQTTConnectionInfo
    public var mqttProtocol: MQTTProtocol
    
    public init(clientID: String, mqttProtocol: MQTTProtocol) {
        self.connectionInfo = MQTTConnectionInfo(clientID: clientID)
        self.mqttProtocol = mqttProtocol
    }
}

public struct MQTTConnectionInfo {
    public var clientID: String
    public var username: String?
    public var password: String?
    public var cleanStart: Bool = true
    public var keepAlive: UInt16 = 60
}

public enum MQTTProtocol {
    case v3(MQTT3.Options)
    case v5(MQTT5.Options)
}

extension MQTT3 {
    public struct Options {
        public init() {
            
        }
    }
}

extension MQTT5 {
    public struct Options {
        public var connectProperties: MQTT5.ConnectProperties
        
        public init(connectProperties: MQTT5.ConnectProperties) {
            self.connectProperties = connectProperties
        }
    }
}

