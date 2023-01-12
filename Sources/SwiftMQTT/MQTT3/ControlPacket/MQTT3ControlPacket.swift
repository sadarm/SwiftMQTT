//
//  File.swift
//  
//
//  Created by kisu park on 2023/01/12.
//

import Foundation


protocol MQTT3ControlPacket {
    var typeAndFlags: MQTT3ControlPacketTypeAndFlags { get }
    var remainingLength: UInt8 { get }
    
    func fixedHeader() -> [UInt8]
    func variableHeader() -> [UInt8]
    func payload() -> [UInt8]
    func bytes() -> [UInt8]
}

extension MQTT3ControlPacket {
    var type: MQTT3ControlPacketType { self.typeAndFlags.type }
    
    var remainingLength: UInt8 {
        UInt8(self.variableHeader().count + self.payload().count)
    }

    func fixedHeader() -> [UInt8] {
        [self.typeAndFlags.rawValue, self.remainingLength]
    }
    
    func bytes() -> [UInt8] {
        self.fixedHeader() + self.variableHeader() + self.payload()
    }
}

struct MQTT3ControlPacketBody {
    var body: [UInt8]
}

enum MQTT3ControlPacketType: UInt8 {
    case reserved = 0x00
    case connect = 0x10
    case connack = 0x20
    case publish = 0x30
    case puback = 0x40
    case pubrec = 0x50
    case pubrel = 0x60
    case pubcomp = 0x70
    case subscribe = 0x80
    case suback = 0x90
    case unsubscribe = 0xa0
    case unsuback = 0xb0
    case pingreq = 0xc0
    case pingresp = 0xd0
    case disconnect = 0xe0
    case reserved2 = 0xf0
}

struct MQTT3ControlPacketTypeAndFlags: RawRepresentable {
    typealias RawValue = UInt8
    
    var rawValue: UInt8 {
        get {
            return self.type.rawValue | self.flags
        }
        set {
            guard let type = MQTT3ControlPacketType(rawValue: newValue & 0xf0) else {
                return
            }
            self.type = type
            self.flags = newValue & 0x0f
        }
    }
    
    var type: MQTT3ControlPacketType
    var flags: UInt8
    
    init?(rawValue: UInt8) {
        guard let type = MQTT3ControlPacketType(rawValue: rawValue & 0xf0) else {
            return nil
        }
        
        self.type = type
        self.flags = rawValue & 0x0f
    }
    
    init(type: MQTT3ControlPacketType, flags: UInt8) {
        self.type = type
        self.flags = flags
    }
}

struct MQTT3FixedHeader {
    let controlPacketType: MQTT3ControlPacketType
    let remainingLength: UInt8
    
    init(controlPacketType: MQTT3ControlPacketType, remainingLength: UInt8) {
        self.controlPacketType = controlPacketType
        self.remainingLength = remainingLength
    }
    
    init(bytes: [UInt8]) throws {
        guard 2 == bytes.count else {
            throw SwiftMQTTError.incorrentBytes
        }
        
        guard let controlPacketType = MQTT3ControlPacketType(rawValue: bytes[0] & 0xf0 >> 4) else {
            throw SwiftMQTTError.incorrentBytes
        }
        
        self.controlPacketType = controlPacketType
        self.remainingLength = bytes[1]
    }
}


public enum MQTT3QoS: UInt8, Comparable {
    case qos0 = 0
    case qos1
    case qos2
    
    public static func < (lhs: Self, rhs: Self) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}
