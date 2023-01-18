//
//  File.swift
//  
//
//  Created by M1ProMacbook-kisupark on 2023/01/16.
//

import Foundation

extension MQTT5 {
    struct ConnectAckPacket: MQTT5ControlPacket {
        var typeAndFlags: MQTT5.ControlPacketTypeAndFlags {
            MQTT5.ControlPacketTypeAndFlags(type: .connack, flags: 0)
        }
        
        var acknowledgeFlags: MQTTBool
        var sessionPresent: MQTTBool
        var reasonCode: ConnectReasonCode
        var properties: Properties
        
        func variableHeader() -> Data {
            var header: Data = Data()
            
            header.append(self.acknowledgeFlags)
            header.append(self.sessionPresent)
            header.append(self.reasonCode)
            
            return header
        }
        
        func payload() -> Data {
            Data()
        }
    }
}

extension MQTT5.ConnectAckPacket {
    enum ConnectReasonCode: UInt8 {
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
    
    struct Properties: MQTTBytesRepresentable {
        var sessionExpiryInterval: MQTT5.Properties.SessionExpiryInterval?
        var receiveMaximum: MQTT5.Properties.ReceiveMaximum?
        var maximumQoS: MQTT5.Properties.MaximumQoS?
        var retainAvailable: MQTT5.Properties.RetainAvailable?
        var maximumPacketSize: MQTT5.Properties.MaximumPacketSize?
        var assignedClientIdentifier: MQTT5.Properties.AssignedClientIdentifier?
        var topicAliasMaximum: MQTT5.Properties.TopicAliasMaximum?
        var userProperties: [MQTT5.Properties.UserProperty] = []
        var wildcardSubscriptionAvailable: MQTT5.Properties.WildecardSubscriptionAvailable?
        var subscriptionIdentifiersAvailable: MQTT5.Properties.SubscriptionIdentifiersAvailable?
        var sharedSubscriptionAvailable: MQTT5.Properties.SharedSubscriptionAvailable?
        var serverKeepAlive: MQTT5.Properties.ServerKeepAlive?
        var responseInformation: MQTT5.Properties.ResponseInformation?
        var serverReference: MQTT5.Properties.ServerReference?
        var authenticationMethod: MQTT5.Properties.AuthenticationMethod?
        var authenticationData: MQTT5.Properties.AuthenticationData?
        
        init(_ data: Data) throws {
            var data = data
            repeat {
                guard data.count >= 2 else {
                    throw SwiftMQTTError.corruptData
                }
                
                let identifier = MQTT5.PropertyIdentifier(rawValue: data[data.startIndex])
                data = data[data.startIndex..<data.endIndex]
                switch identifier {
                case .sessionExpiryInterval:
                    self.sessionExpiryInterval = try .init(data)
                case .receiveMaximum:
                    self.receiveMaximum = try .init(data)
                case .maximumQoS:
                    self.receiveMaximum = try .init(data)
                case .retainAvailable:
                    self.retainAvailable = try .init(data)
                case .maximumPacketSize:
                    self.maximumPacketSize = try .init(data)
                case .assignedClientIdentifier:
                    self.assignedClientIdentifier = try .init(data)
                case .topicAliasMaximum:
                    self.topicAliasMaximum = try .init(data)
                case .userProperty:
                    try self.userProperties.append(.init(data))
                case .wildcardSubscriptionAvailable:
                    self.wildcardSubscriptionAvailable = try .init(data)
                case .subscriptionIdentifiersAvailable:
                    self.subscriptionIdentifiersAvailable = try .init(data)
                case .sharedSubscriptionAvailable:
                    self.sharedSubscriptionAvailable = try .init(data)
                case .serverKeepAlive:
                    self.serverKeepAlive = try .init(data)
                case .responseInformation:
                    self.responseInformation = try .init(data)
                case .serverReference:
                    self.serverReference = try .init(data)
                case .authenticationMethod:
                    self.authenticationMethod = try .init(data)
                case .authenticationData:
                    self.authenticationData = .init(data)
                default:
                    break
                }
            } while true
            
            
        }
    }
}

extension MQTT5.ConnectAckPacket.ConnectReasonCode: MQTTBytesRepresentable {
    var bytesMQTTEncoded: [UInt8] {
        [self.rawValue]
    }
}

extension MQTT5.ConnectAckPacket {
    init(_ data: Data) throws {
        guard data.count >= 3 else {
            throw SwiftMQTTError.notEnoughData
        }
        var data = data
        
        let acknowledgeFlags = try MQTTBool(rawValue: data[data.startIndex])
        let sessionPresent = try MQTTBool(rawValue: data[data.startIndex+1])
        guard let reasonCode = ConnectReasonCode(rawValue: data[data.startIndex+2]) else {
            throw SwiftMQTTError.corruptData
        }
        
        data = data[data.startIndex+3..<data.endIndex]
        
        let (lengthOfProperties, remained) = try MQTTVariableByteInteger.create(from: data)
        data = remained
        
        guard data.count >= lengthOfProperties.intValue else {
            throw SwiftMQTTError.corruptData
        }
        data = data[data.startIndex..<data.startIndex+lengthOfProperties.intValue]
        
        let properties = try Properties(data)
        
        self.init(acknowledgeFlags: acknowledgeFlags,
                  sessionPresent: sessionPresent,
                  reasonCode: reasonCode,
                  properties: properties)
    }
}
