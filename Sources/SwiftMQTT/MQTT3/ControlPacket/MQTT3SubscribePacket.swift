//
//  File.swift
//  
//
//  Created by kisu park on 2023/01/12.
//

import Foundation

extension MQTT3 {
    struct SubscribePacket: MQTT3ControlPacket {
        struct Subscription {
            let topic: MQTTString
            let qos: MQTTQoS
            
            init(topic: MQTTString, qos: MQTTQoS) {
                self.topic = topic
                self.qos = qos
            }
        }
        
        var typeAndFlags: ControlPacketTypeAndFlags { ControlPacketTypeAndFlags(type: .subscribe, flags: 2) }
        
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
}

extension MQTT3.SubscribePacket.Subscription: MQTTBytesRepresentable {
    var bytesMQTTEncoded: [UInt8] {
        var bytes: [UInt8] = self.topic.bytesMQTTEncoded
        bytes.append(self.qos.rawValue)
        return bytes
    }
}

extension MQTT3.SubscribePacket {
    init(_ data: Data) throws {
        guard data.count >= 2 else {
            throw SwiftMQTTError.corruptData
        }
        
        var data = data
        let identifier = UInt16(data[data.startIndex] << 8) | UInt16(data[data.startIndex+1])
        data = data[data.startIndex+2..<data.endIndex]
        
        var subscriptions: [Subscription] = []
        while !data.isEmpty {
            guard data.count >= 2 else {
                throw SwiftMQTTError.corruptData
            }
            let lengthOfTopic = Int(UInt16(data[data.startIndex] << 8) | UInt16(data[data.startIndex+1]))
            data = data[data.startIndex+2..<data.endIndex]
            guard data.count >= lengthOfTopic else {
                throw SwiftMQTTError.corruptData
            }
            
            let topic = try MQTTString(data)
            data = data[lengthOfTopic..<data.endIndex]
            
            guard let qos = data.first.flatMap({ MQTTQoS(rawValue: $0) }) else {
                throw SwiftMQTTError.corruptData
            }
            data = data[data.startIndex..<data.endIndex]
            
            subscriptions.append(Subscription(topic: topic, qos: qos))
        }
        
        self.init(identifier: identifier,
                  subscriptions: subscriptions)
    }
}
