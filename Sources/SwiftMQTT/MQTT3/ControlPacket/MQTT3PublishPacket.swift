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
    
    enum QoSWithIdentifier {
        case qos0
        case qos1(UInt16)
        case qos2(UInt16)
        
        var qos: MQTT3QoS {
            switch self {
            case .qos0:
                return .qos0
            case .qos1:
                return .qos1
            case .qos2:
                return .qos2
            }
        }
        
    }
    
    var typeAndFlags: MQTT3ControlPacketTypeAndFlags {
        MQTT3ControlPacketTypeAndFlags(type: .publish, flags: self.dupFlag.byte << 3 | self.qosWithIdentifier.qos.rawValue << 1 | self.retain.byte)
    }

    var dupFlag: Bool
    let qosWithIdentifier: QoSWithIdentifier
    let topic: MQTTString
    let message: MQTTString
    let retain: Bool
    
    func variableHeader() -> [UInt8] {
        var header: [UInt8] = []
        header.append(self.topic)

        switch self.qosWithIdentifier {
        case .qos0:
            break
        case .qos1(let identifier):
            header.append(identifier)
        case .qos2(let identifier):
            header.append(identifier)
        }
        
        return header
    }
    
    func payload() -> [UInt8] {
        var bytes: [UInt8] = []
        bytes.append(self.topic)
        bytes.append(self.message)
        return bytes
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
        
        let lengthOfTopic = Int(UInt16(data[data.startIndex] << 8) | UInt16(data[data.startIndex+1]))
        data = data[data.startIndex+2..<data.endIndex]
        
        guard data.count >= lengthOfTopic else {
            throw SwiftMQTTError.notEnoughData
        }
        
        let topic = try MQTTString(data[data.startIndex..<data.startIndex+lengthOfTopic])
        data = data[data.startIndex+lengthOfTopic..<data.endIndex]
        
        guard data.count >= 2 else {
            throw SwiftMQTTError.notEnoughData
        }
        
        let qosWithIdentifier: QoSWithIdentifier
        switch flags.qos {
        case .qos0:
            qosWithIdentifier = .qos0
        case .qos1:
            let identifier = (UInt16(data[data.startIndex]) << 8) | UInt16(data[data.startIndex+1])
            data = data[data.startIndex+2..<data.endIndex]
            qosWithIdentifier = .qos1(identifier)
        case .qos2:
            let identifier = (UInt16(data[data.startIndex]) << 8) | UInt16(data[data.startIndex+1])
            data = data[data.startIndex+2..<data.endIndex]
            qosWithIdentifier = .qos2(identifier)
        }
        
        let message = try MQTTString(data)
        
        self.init(dupFlag: flags.dupFlag,
                  qosWithIdentifier: qosWithIdentifier,
                  topic: topic,
                  message: message,
                  retain: flags.retain)
    }
}
