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
    func properties() -> Data
}

extension MQTT5ControlPacket {
    var type: MQTT5.ControlPacketType { self.typeAndFlags.type }
    
    var remainingLength: UInt32 {
        return UInt32(self.variableHeader().count + self.payload().count + self.properties().count)
    }
    
    func fixedHeader() -> Data {
        Data([self.typeAndFlags.rawValue] + MQTTVariableByteInteger(self.remainingLength).rawValue)
    }
    
    func bytes() -> Data {
        self.fixedHeader() + self.variableHeader() + self.payload()
    }
}




enum MQTT5 {
    
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
    
    enum Property {
        case payloadFormatIndicator(UInt8)
        case messageExpiryInterval(UInt32)
        case contentType(MQTTString)
        case responseTopic(MQTTString)
        case correlationData(UInt8)
        case subscriptionIdentifier(UInt32)
        case sessionExpiryInterval(UInt32)
        case assignedClientIdentifier(MQTTString)
        case serverKeepAlive(UInt16)
        case authenticationMethod(MQTTString)
        case authenticationData(Data)
        case requestProblemInformation(UInt8)
        case willDelayInterval(UInt32)
        case requestResponseInformation(MQTTString)
        case responseInformation(MQTTString)
        case serverReference(MQTTString)
        case responString(MQTTString)
        case receiveMaximum(UInt16)
        case topicAliasMaximum(UInt16)
        case topicAlias(UInt16)
        case maximumQoS(UInt8)
        case retainAvailable(UInt8)
        case userProperty((MQTTString, MQTTString))
        case maximumPacketSize(UInt32)
        case wildcardSubscriptionAvailable(UInt8)
        case subscriptionIdentifierAvailable(UInt8)
        case sharedSubscriptionAvailable(UInt8)
    }
    
    enum ReasonCode: UInt8 {
        case success = 0x00
        case grantedQoS1 = 0x01
        case grantedQoS2 = 0x02
        case disconnectWithWillMessage = 0x04
        case noMatchingSubscribers = 0x10
        case noSubscriptionExisted = 0x11
        case continueAuthentication = 0x18
        case reauthenticate = 0x19
        case unspecifiedError = 0x80
        case malformedPacket = 0x81
        case protocolError = 0x82
        case implementationSpecificError = 0x83
        case unsupportedProtocolVersion = 0x84
        case clientIdentifierNotValid = 0x85
        case badUserNameOrPassword = 0x86
        case notAuthorized = 0x87
        case serverUnavaiable = 0x88
        case serverBusy = 0x89
        case banned = 0x8A
        case serverShuttingDown = 0x8B
        case badAuthenticationMethod = 0x8C
        case keepAliveTimeout = 0x8D
        case sessionTakenOver = 0x8E
        case topicFilterInvalid = 0x8F
        case topicNameInvalid = 0x90
        case packetIdentifierInUse = 0x91
        case packetIdentifierNotFound = 0x92
        case receiveMaximumExceeded = 0x93
        case topicAliasInvalid = 0x94
        case packetTooLarge = 0x95
        case messageRateTooHigh = 0x96
        case quotaExceeded = 0x97
        case administrativeAction = 0x98
        case payloadFormatInvalid = 0x99
        case retainNotSUpported = 0x9A
        case qosNotSupported = 0x9B
        case useAnotherServer = 0x9C
        case serverMoved = 0x9D
        case sharedSubscriptionsNotSupported = 0x9E
        case connectionRateExceeded = 0x9F
        case maximumConnectTime = 0xA0
        case subscriptionIdentifiersNotSupported = 0xA1
        case wildcardSubscriptionsNotSupported = 0xA2
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
