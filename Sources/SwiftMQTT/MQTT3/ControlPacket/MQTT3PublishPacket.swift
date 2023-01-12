//
//  File.swift
//  
//
//  Created by kisu park on 2023/01/12.
//

import Foundation

struct MQTT3PublishPacket: MQTT3ControlPacket {
    struct Flags {
        var dupFlag: Bool
        var qos: MQTT3QoS
        var retain: Bool
        
        init?(byte: UInt8) {
            guard let qos = MQTT3QoS(rawValue: (byte & 0x06) >> 1) else {
                return nil
            }
            self.dupFlag = Bool(byte: (byte & 0x08 >> 3))
            self.qos = qos
            self.retain = Bool(byte: byte & 0x01)
        }
    }
    
    var typeAndFlags: MQTT3ControlPacketTypeAndFlags {
        MQTT3ControlPacketTypeAndFlags(type: .publish, flags: self.dupFlag.byte << 3 | self.message.qos.rawValue << 1 | self.message.retain.byte)
    }

    var dupFlag: Bool
    var identifier: UInt16?
    var message: MQTT3Message
    
    func variableHeader() -> [UInt8] {
        var header: [UInt8] = []
        header.append(self.message.topic)
        
        if self.message.qos > .qos0,
           let id = self.identifier {
            header.append(id)
        }
        
        return header
    }
    
    func payload() -> [UInt8] {
        return self.message.payload.bytesMQTTEncoded
    }
}

extension MQTT3PublishPacket {
    init(typeAndFlags: MQTT3ControlPacketTypeAndFlags, data: Data) throws {
        guard typeAndFlags.type == .publish else {
            throw SwiftMQTTError.typeMissmatch
        }
        
        guard let flags = MQTT3PublishPacket.Flags(byte: typeAndFlags.rawValue) else {
            throw SwiftMQTTError.corruptData
        }
        
        var data = data
        
        guard data.count >= 2 else {
            throw SwiftMQTTError.notEnoughData
        }
        
        let lengthOfTopic = Int(UInt16(data[0] << 8) | UInt16(data[1]))
        data = data[2..<data.endIndex]
        
        guard data.count >= lengthOfTopic else {
            throw SwiftMQTTError.notEnoughData
        }
        
        let topic = try MQTT3String(data[0..<lengthOfTopic])
        data = data[lengthOfTopic..<data.endIndex]
        
        guard data.count >= 2 else {
            throw SwiftMQTTError.notEnoughData
        }
        
        var identifier: UInt16?
        if flags.qos > .qos0 {
            identifier = (UInt16(data[0]) << 8) | UInt16(data[1])
            data = data[2..<data.endIndex]
        }
        
        guard data.count >= 2 else {
            throw SwiftMQTTError.notEnoughData
        }
        
        let lengthOfPayload = (UInt16(data[0]) << 8) | UInt16(data[1])
        data = data[2..<data.endIndex]
        
        let payload = try MQTT3String(data[0..<lengthOfPayload])
        let message = MQTT3Message(qos: flags.qos, topic: topic, payload: payload, retain: flags.retain)
        
        self.init(dupFlag: flags.dupFlag,
                  identifier: identifier,
                  message: message)
    }
}
