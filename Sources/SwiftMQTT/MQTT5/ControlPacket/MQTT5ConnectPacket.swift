//
//  File.swift
//  
//
//  Created by kisu park on 2023/01/15.
//

import Foundation

extension MQTT5 {
    struct ConnectPacket {
        struct Flags: OptionSet {
            typealias RawValue = UInt8
            var rawValue: RawValue
            
            static let reserved = Self(rawValue: 0)
            static let cleanStart = Self(rawValue: 1 << 1)
            static let willFlag = Self(rawValue: 1 << 2)
            static func willQos(_ qos: MQTT3QoS) -> Self {
                Self(rawValue: qos.rawValue << 4 | qos.rawValue << 3)
            }
            static let willRetain = Self(rawValue: 5)
            static let password = Self(rawValue: 6)
            static let userName = Self(rawValue: 7)
        }
        
        var protocolName: MQTTString { "MQTT" }
        var protocolLevel: UInt8 { 5 }
        
        var username: MQTTString?
        var password: MQTTString?
        var willMessage: MQTT3Message?
        var cleanStart: Bool = true
        
        var clientID: MQTTString
        var keepAlive: UInt16
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
    
    func properties() -> Data {
        return Data()
    }
}
