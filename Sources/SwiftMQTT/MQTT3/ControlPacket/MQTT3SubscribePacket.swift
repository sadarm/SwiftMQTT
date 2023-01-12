//
//  File.swift
//  
//
//  Created by kisu park on 2023/01/12.
//

import Foundation

struct MQTT3SubscribePacket: MQTT3ControlPacket {
    struct Subscription {
        let topic: MQTT3String
        let qos: MQTT3QoS

        init(topic: MQTT3String, qos: MQTT3QoS) {
            self.topic = topic
            self.qos = qos
        }
    }
    
    var typeAndFlags: MQTT3ControlPacketTypeAndFlags { MQTT3ControlPacketTypeAndFlags(type: .subscribe, flags: 0) }
    var remainingLength: UInt8 { 2 }
    
    let identifier: UInt16
    let subscriptions: [Subscription]
    
    init(identifier: UInt16, subscriptions: [Subscription]) {
        self.identifier = identifier
        self.subscriptions = subscriptions
    }
    
    func variableHeader() -> [UInt8] {
        self.identifier.bytesMQTTEncoded
    }
    
    func payload() -> [UInt8] {
        return self.subscriptions.bytesMQTTEncoded
    }
}

extension MQTT3SubscribePacket.Subscription: MQTT3BytesRepresentable {
    var bytesMQTTEncoded: [UInt8] {
        var bytes: [UInt8] = self.topic.bytesMQTTEncoded
        bytes.append(self.qos.rawValue)
        return bytes
    }
}

extension MQTT3SubscribePacket {
    init(_ data: Data) throws {
        guard data.count >= 2 else {
            throw SwiftMQTTError.corruptData
        }
        
        var data = data
        let identifier = UInt16(data[0] << 8) | UInt16(data[1])
        data = data[2..<data.endIndex]
        
        var subscriptions: [Subscription] = []
        while !data.isEmpty {
            guard data.count >= 2 else {
                throw SwiftMQTTError.corruptData
            }
            let lengthOfTopic = Int(UInt16(data[0] << 8) | UInt16(data[1]))
            data = data[2..<data.endIndex]
            guard data.count >= lengthOfTopic else {
                throw SwiftMQTTError.corruptData
            }
            
            let topic = try MQTT3String(data)
            data = data[lengthOfTopic..<data.endIndex]
            
            guard let qos = data.first.flatMap({ MQTT3QoS(rawValue: $0) }) else {
                throw SwiftMQTTError.corruptData
            }
            data = data[0..<data.endIndex]
            
            subscriptions.append(Subscription(topic: topic, qos: qos))
        }
        
        self.init(identifier: identifier,
                  subscriptions: subscriptions)
    }
}
