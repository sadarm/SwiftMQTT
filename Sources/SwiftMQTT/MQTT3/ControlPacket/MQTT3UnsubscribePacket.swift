//
//  File.swift
//  
//
//  Created by kisu park on 2023/01/12.
//

import Foundation

struct MQTT3UnsubscribePacket: MQTT3ControlPacket {
    var typeAndFlags: MQTT3ControlPacketTypeAndFlags { MQTT3ControlPacketTypeAndFlags(type: .unsubscribe, flags: 0) }
    let topics: [MQTT3String]
    
    let identifier: UInt16
    
    init(identifier: UInt16, topics: [MQTT3String]) {
        self.identifier = identifier
        self.topics = topics
    }
    
    func variableHeader() -> [UInt8] {
        self.identifier.bytesMQTTEncoded
    }
    
    func payload() -> [UInt8] {
        self.topics.bytesMQTTEncoded
    }
}

extension MQTT3UnsubscribePacket {
    init(_ data: Data) throws {
        guard data.count >= 2 else {
            throw SwiftMQTTError.notEnoughData
        }
        
        var data = data
        let identifier = UInt16(data[data.startIndex] << 8) | UInt16(data[data.startIndex+1])
        data = data[data.startIndex+2..<data.endIndex]
        
        var topics: [MQTT3String] = []
        while !data.isEmpty {
            guard data.count >= 2 else {
                throw SwiftMQTTError.corruptData
            }
            let lengthOfTopic = Int(UInt16(data[data.startIndex] << 8) | UInt16(data[data.startIndex+1]))
            data = data[data.startIndex+2..<data.endIndex]
            guard data.count >= lengthOfTopic else {
                throw SwiftMQTTError.corruptData
            }
            
            let topic = try MQTT3String(data)
            topics.append(topic)
        }
        self.init(identifier: identifier, topics: topics)
    }
}
