//
//  File.swift
//  
//
//  Created by kisu park on 2023/01/15.
//

import Foundation

protocol MQTT5ControlPacket {
    var typeAndFlags: MQTT5.ControlPacketTypeAndFlags { get }
    var remainingLength: UInt32 { get }
    
    func fixedHeader() -> Data
    func variableHeader() -> Data
    func payload() -> Data
}

extension MQTT5ControlPacket {
    var type: MQTT5.ControlPacketType { self.typeAndFlags.type }
    
    var remainingLength: UInt32 {
        return UInt32(self.variableHeader().count + self.payload().count)
    }
    
    func fixedHeader() -> Data {
        Data([self.typeAndFlags.rawValue] + MQTTVariableByteInteger(self.remainingLength).rawValue)
    }
    
    func bytes() -> Data {
        self.fixedHeader() + self.variableHeader() + self.payload()
    }
}


public enum MQTT5 {
    
}

extension MQTT5 {
    enum ControlPacketType: UInt8 {
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
        case auth = 0xf0
    }
    
    public enum PropertyIdentifier: UInt8 {
        case payloadFormatIndicator = 0x01
        case messageExpiryInterval = 0x02
        case contentType = 0x03
        case responseTopic = 0x08
        case correlationData = 0x09
        case subscriptionIdentifier = 0x0B
        case sessionExpiryInterval = 0x11
        case assignedClientIdentifier = 0x12
        case serverKeepAlive = 0x13
        case authenticationMethod = 0x15
        case authenticationData = 0x16
        case requestProblemInformation = 0x17
        case willDelayInterval = 0x18
        case requestResponseInformation = 0x19
        case responseInformation = 0x1A
        case serverReference = 0x1C
        case reasonString = 0x1F
        case receiveMaximum = 0x21
        case topicAliasMaximum = 0x22
        case topicAlias = 0x23
        case maximumQoS = 0x24
        case retainAvailable = 0x25
        case userProperty = 0x26
        case maximumPacketSize = 0x27
        case wildcardSubscriptionAvailable = 0x28
        case subscriptionIdentifiersAvailable = 0x29
        case sharedSubscriptionAvailable = 0x2A
    }
}

extension MQTT5 {
    struct ControlPacketTypeAndFlags: RawRepresentable {
        typealias RawValue = UInt8
        
        var rawValue: UInt8 {
            get {
                return self.type.rawValue | self.flags
            }
            set {
                guard let type = ControlPacketType(rawValue: newValue & 0xf0) else {
                    return
                }
                self.type = type
                self.flags = newValue & 0x0f
            }
        }
        
        var type: ControlPacketType
        var flags: UInt8
        
        init?(rawValue: UInt8) {
            guard let type = ControlPacketType(rawValue: rawValue & 0xf0) else {
                return nil
            }
            
            self.type = type
            self.flags = rawValue & 0x0f
        }
        
        init(type: ControlPacketType, flags: UInt8) {
            self.type = type
            self.flags = flags
        }
    }
}
