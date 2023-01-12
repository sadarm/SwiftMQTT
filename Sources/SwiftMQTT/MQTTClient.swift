//
//  File.swift
//  
//
//  Created by kisu park on 2023/01/12.
//

import Foundation
import Network

public final class MQTT3Connection: MQTTConnection {
    public struct Parameters {
        public let host: String
        public let port: UInt16
        public let clientID: String
        public var username: String?
        public var password: String?
        public var cleanSession: Bool
        public var keepAlive: UInt16
    }
    
    public var parameters: Parameters
    
    public var host: String { self.parameters.host }
    public var port: UInt16 { self.parameters.port }
    public var clientID: String { self.parameters.clientID }
    public var username: String? { self.parameters.username }
    public var password: String? { self.parameters.password }
    public var cleanSession: Bool { self.parameters.cleanSession }
    public var keepAlive: UInt16 { self.parameters.keepAlive }
    
    private let internalConnection: NWConnection
    private var connectionState: NWConnection.State = .setup {
        didSet {
            
        }
    }
    
    private let queue: DispatchQueue = DispatchQueue(label: "SwiftMQTT.NWConnection")
    
    private let streamReader: MQTT3StreamReader
    private var packetIdentifier: UInt16 = 0
    
    public init(using parameters: Parameters) {
        self.parameters = parameters
        self.internalConnection = NWConnection(host: NWEndpoint.Host(self.parameters.host),
                                               port: NWEndpoint.Port(rawValue: self.parameters.port)!,
                                               using: .tcp)
        self.streamReader = MQTT3StreamReader(self.internalConnection)
        
        self.internalConnection.stateUpdateHandler = { [weak self] (state) in
            self?.connectionState = state
        }
    }
    
    public func start() {
        self.internalConnection.start(queue: self.queue)
    }
    
    public func stop() {
        self.internalConnection.cancel()
    }
    
    public func subscribeTopics(_ topics: [(String, MQTT3QoS)]) {
        self.send(MQTT3SubscribePacket(identifier: self.nextPacketIdentifier(),
                                       subscriptions: topics.map { MQTT3SubscribePacket.Subscription(topic: MQTT3String($0.0), qos: $0.1) }))
    }
    
    public func unsubscribeTopics(_ topics: [String]) {
        self.send(MQTT3UnsubscribePacket(identifier: self.nextPacketIdentifier(),
                                         topics: topics.map { MQTT3String($0) }))
    }
    
    private func nextPacketIdentifier() -> UInt16 {
        self.packetIdentifier &+= 1
        return self.packetIdentifier
    }
}

extension MQTT3Connection {
    private func connectionStateIsUpdated() {
        switch self.connectionState {
        case .setup:
            break
        case .ready:
            self.sendConnectPacket()
        case .waiting(let error):
            break
        case .failed(let error):
            break
        case .cancelled:
            break
        case .preparing:
            break
        @unknown default:
            break
        }
    }
    
    private func sendConnectPacket() {
        let connectPacket = MQTT3ConnectPacket(username: self.username.map { MQTT3String($0) },
                                               password: self.password.map { MQTT3String($0) },
                                               willMessage: nil,
                                               cleanSession: self.cleanSession,
                                               clientID: self.clientID,
                                               keepAlive: self.keepAlive)
        self.send(connectPacket)
    }
    
    private func send(_ controlPacket: MQTT3ControlPacket) {
        self.internalConnection.send(content: controlPacket.bytes(),
                                     completion: .contentProcessed({ (error) in
            if let error = error {
                print("failed to send control packet(\(controlPacket)). error: \(error)")
            }
        }))
    }
    
    private func startReading() {
        self.streamReader.start()
    }
    
    private func stopReading() {
        self.streamReader.cancel()
    }
}
