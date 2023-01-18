//
//  File.swift
//  
//
//  Created by kisu park on 2023/01/15.
//

import Foundation

extension MQTT5 {
    struct ConnectPacket {
        var protocolName: MQTTString { "MQTT" }
        var protocolLevel: UInt8 { 5 }
        
        var username: MQTTString?
        var password: MQTTString?
        var willMessage: WillMessage?
        var cleanStart: Bool = true
        
        var clientID: MQTTString
        var keepAlive: UInt16
        
        var properties: ConnectProperties
    }
    
    public struct ConnectProperties: MQTTBytesRepresentable {
        public var sessionExpiryInterval: MQTT5.Properties.SessionExpiryInterval?
        public var receiveMaximum: MQTT5.Properties.ReceiveMaximum?
        public var maximumPacketSize: MQTT5.Properties.MaximumPacketSize?
        public var topicAliasMaximum: MQTT5.Properties.TopicAliasMaximum?
        public var requestResponseInformation: MQTT5.Properties.RequestResponseInformation?
        public var requestProblemInformation: MQTT5.Properties.RequestProblemInformation?
        public var userProperty: [MQTT5.Properties.UserProperty]
        public var authenticationMethod: MQTT5.Properties.AuthenticationMethod?
        public var authenticationData: MQTT5.Properties.AuthenticationData?
    }
}

extension MQTT5.ConnectPacket {
    struct Flags: OptionSet {
        typealias RawValue = UInt8
        var rawValue: RawValue
        
        static let reserved = Self(rawValue: 0)
        static let cleanStart = Self(rawValue: 1 << 1)
        static let willFlag = Self(rawValue: 1 << 2)
        static func willQos(_ qos: MQTTQoS) -> Self {
            Self(rawValue: qos.rawValue << 4 | qos.rawValue << 3)
        }
        static let willRetain = Self(rawValue: 5)
        static let password = Self(rawValue: 6)
        static let userName = Self(rawValue: 7)
    }
    
    struct WillMessage: MQTTBytesRepresentable {
        var qos: MQTTQoS
        var retain: MQTTBool
        var topic: MQTTString
        var payload: MQTTString
        var properties: MQTT5.PublishPacket.Properties
        
        var bytesMQTTEncoded: [UInt8] {
            var bytes: [UInt8] = []
            bytes.append(self.properties)
            bytes.append(self.topic)
            bytes.append(self.payload)
            return bytes
        }
    }
}

extension MQTT5.ConnectPacket: MQTT5ControlPacket {
    var typeAndFlags: MQTT5.ControlPacketTypeAndFlags {
        MQTT5.ControlPacketTypeAndFlags(type: .connect, flags: 0)
    }

    func variableHeader() -> Data {
        var header: Data = Data()
        
        header.append(self.protocolName)
        header.append(self.protocolLevel)

        let connectFlags = self.makeConnectFlags()
        header.append(connectFlags.rawValue)
        
        header.append(self.keepAlive)
        
        let properties = self.properties.bytesMQTTEncoded
        header.append(MQTTVariableByteInteger(UInt32(properties.count)))
        header.append(contentsOf: properties)
        
        return header
    }
    
    private func makeConnectFlags() -> Flags {
        var connectFlags: Flags = Flags.reserved
        
        if self.cleanStart {
            connectFlags.insert(.cleanStart)
        }
        
        if let willMessage = self.willMessage {
            connectFlags.insert(.willFlag)
            connectFlags.insert(.willQos(willMessage.qos))
            
            if willMessage.retain.boolValue {
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
    
    
    func payload() -> Data {
        var payload = Data()
        
        payload.append(self.clientID)
        
        if let willMessage = self.willMessage {
            payload.append(willMessage)
        }
        
        if let username = self.username {
            payload.append(username)
            
            if let password = self.password {
                payload.append(password)
            }
        }
        return payload
    }
    
}
