//
//  File.swift
//  
//
//  Created by kisu park on 2023/01/07.
//

import Foundation

public enum MQTTConnectionState {
    case setup
    case preparing
    case ready
    case waiting(SwiftMQTTError)
    case failed(SwiftMQTTError)
    case cancelled
}

public protocol MQTTConnection {
    
    var host: String { get }
    var port: UInt16 { get }
    var clientID: String { get }
    var username: String? { get }
    var password: String? { get }
    var cleanSession: Bool { get }
    var keepAlive: UInt16 { get }
    
    func start() async throws
    func stop()
    
    func subscribeTopics(_ topics: [(String, MQTT3QoS)]) async throws
    func unsubscribeTopics(_ topics: [String])
    
}
