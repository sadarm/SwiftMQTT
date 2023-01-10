//
//  File.swift
//  
//
//  Created by kisu park on 2023/01/07.
//

import Foundation

enum ConnectReturnCode: UInt8 {
    case accepted = 0
    case unacceptableProtocolVersion
    case identifierRejected
    case serverUnavailable
    case bandUserNameOrPassword
    case notAuthorized
    case reserved
    
    public init(byte: UInt8) {
        switch byte {
        case Self.accepted.rawValue..<Self.reserved.rawValue:
            self.init(rawValue: byte)!
        default:
            self = .reserved
        }
    }
}


protocol MQTT3BytesRepresentable {
    var bytesMQTTEncoded: [UInt8] { get }
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

struct MQTT3FixedHeader {
    let controlPacketType: MQTT3ControlPacketType
    let remainingLength: UInt8
    
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

protocol MQTT3ControlPacket {
    var type: MQTT3ControlPacketType { get }
    func fixedHeader() -> [UInt8]
    func variableHeader() -> [UInt8]
    func payload() -> [UInt8]
}

extension MQTT3ControlPacket {
    func fixedHeader() -> [UInt8] {
        [self.type.rawValue, 0]
    }
}

struct MQTT3ConnectPacket {
    struct Flags: OptionSet {
        typealias RawValue = UInt8
        var rawValue: RawValue
        
        static let reserved = Self(rawValue: 0)
        static let cleanSession = Self(rawValue: 1 << 1)
        static let willFlag = Self(rawValue: 1 << 2)
        static func willQos(_ qos: MQTT3Qos) -> Self {
            Self(rawValue: qos.rawValue << 4 | qos.rawValue << 3)
        }
        static let willRetain = Self(rawValue: 5)
        static let password = Self(rawValue: 6)
        static let userName = Self(rawValue: 7)
    }
    
    var protocolSignature: MQTT3String { "MQTT" }
    var protocolLevel: UInt8 { 4 }
    
    var username: MQTT3String?
    var password: MQTT3String?
    var willMessage: MQTT3Message?
    var cleanSession: Bool = true
    
    var clientID: String
    var keepAlive: UInt16
}

extension MQTT3ConnectPacket: MQTT3ControlPacket {
    var type: MQTT3ControlPacketType { .connect }

    func variableHeader() -> [UInt8] {
        var header: [UInt8] = []
        
        header.append(contentsOf: self.protocolSignature.bytesMQTTEncoded)
        header.append(self.protocolLevel)

        let connectFlags = self.makeConnectFlags()
        header.append(connectFlags.rawValue)
        
        header.append(contentsOf: self.keepAlive.bytesMQTTEncoded)
        
        return header
    }
    
    private func makeConnectFlags() -> Flags {
        var connectFlags: Flags = Flags.reserved
        
        if self.cleanSession {
            connectFlags.insert(.cleanSession)
        }
        
        if let willMessage = self.willMessage {
            connectFlags.insert(.willFlag)
            connectFlags.insert(.willQos(willMessage.qos))
            
            if willMessage.retain {
                connectFlags.insert(.willRetain)
            }
        }
        
        if nil != self.username {
            connectFlags.insert(.userName)
        }
        
        if nil != self.password {
            connectFlags.insert(.password)
        }
        
        return connectFlags
    }
    
    func payload() -> [UInt8] {
        var payload: [UInt8] = []
        
        if let willMessage = self.willMessage {
            payload.append(contentsOf: willMessage.bytesMQTTEncoded)
        }
        
        if let username = self.username {
            payload.append(contentsOf: username.bytesMQTTEncoded)
            
            if let password = self.password {
                payload.append(contentsOf: password.bytesMQTTEncoded)
            }
        }
        return payload
    }
}



enum MQTT3Qos: UInt8, Comparable {
    case qos0 = 0
    case qos1
    case qos2
    
    static func < (lhs: MQTT3Qos, rhs: MQTT3Qos) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

struct MQTT3Message {
    var id: UInt16
    let qos: MQTT3Qos
    let topic: String
    let payload: MQTT3String
    let retain: Bool
}

extension MQTT3Message: MQTT3BytesRepresentable {
    var bytesMQTTEncoded: [UInt8] {
        var bytes: [UInt8] = []
        bytes.append(contentsOf: self.topic.bytesMQTTEncoded)
        bytes.append(contentsOf: self.payload.bytesMQTTEncoded)
        return bytes
    }
}

extension UInt16: MQTT3BytesRepresentable {
    var msb: UInt8 { UInt8((self & 0xff00) >> 8) }
    var lsb: UInt8 { UInt8(self & 0x00ff) }
    
    var bytesMQTTEncoded: [UInt8] {
        [self.msb, self.lsb]
    }
}

extension Bool {
    var byte: UInt8 {
        self ? 1 : 0
    }
}

extension String {
    var bytesMQTTEncoded: [UInt8] {
        let length = UInt16(self.utf8.count)
        return [length.msb, length.lsb] + self.utf8
    }
}

struct MQTT3String: ExpressibleByStringLiteral, MQTT3BytesRepresentable {
    typealias StringLiteralType = String

    var bytesMQTTEncoded: [UInt8] {
        return UInt16(self.rawString.count).bytesMQTTEncoded + self.rawString.utf8
    }
    
    let rawString: String
    
    init(stringLiteral value: String) {
        self.init(rawString: value)
    }
    
    init(rawString: String) {
        self.rawString = Self.triming(string: rawString)
    }
    
    private static func triming(string: String) -> String {
        let maxLength = Int(UInt16.max)
        if string.utf8.count > maxLength {
            let startIndex = string.utf8.startIndex
            let endIndex = string.utf8.index(startIndex, offsetBy: Int(UInt16.max))
            return String(string[startIndex..<endIndex])
        } else {
            return string
        }
    }
    
}


struct MQTT3ConnAckPacket: MQTT3ControlPacket {
    var type: MQTT3ControlPacketType { .connack }
    
    var acknowledgeFlags: Bool
    var returnCode: ConnectReturnCode
    
    func variableHeader() -> [UInt8] {
        var header: [UInt8] = []
        
        header.append(self.acknowledgeFlags.byte)
        header.append(self.returnCode.rawValue)
        
        return header
    }
    
    func payload() -> [UInt8] {
        []
    }
}

struct MQTT3PublishPacket: MQTT3ControlPacket {
    var type: MQTT3ControlPacketType { .publish }
    
    var dupFlag: Bool
    var message: MQTT3Message
    
    func fixedHeader() -> [UInt8] {
        let byte1 = self.type.rawValue | (self.dupFlag.byte << 3) | (self.message.qos.rawValue << 1) | self.message.retain.byte
        return [byte1, 0]
    }
    
    func variableHeader() -> [UInt8] {
        var header: [UInt8] = []
        header.append(contentsOf: self.message.topic.bytesMQTTEncoded)
        
        if self.message.qos > .qos0 {
            header.append(contentsOf: self.message.id.bytesMQTTEncoded)
        }
        
        return header
    }
    
    func payload() -> [UInt8] {
        return self.message.payload.bytesMQTTEncoded
    }
}

