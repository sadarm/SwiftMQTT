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

public enum SwiftMQTTError: Error {
    case incorrentBytes
}

public protocol MQTTConnection {
    
    var host: String { get set }
    var port: UInt16 { get set }
    var clientID: String { get }
    var username: String? { get set }
    var password: String? { get set }
    var cleanSession: Bool { get set }
    var keepAlive: UInt16 { get set }
    
    func start()
    func stop()
    
    func subscribeTopics(_ topics: [String])
    func unsubscribeTopics(_ topics: [String])
    
}
