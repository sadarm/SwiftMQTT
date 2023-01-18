//
//  File.swift
//  
//
//  Created by kisu park on 2023/01/12.
//

import Foundation

extension MQTT3 {
    struct ConnectPacket {
        struct Flags: OptionSet {
            typealias RawValue = UInt8
            var rawValue: RawValue
            
            static let reserved = Self(rawValue: 0)
            static let cleanSession = Self(rawValue: 1 << 1)
            static let willFlag = Self(rawValue: 1 << 2)
            static func willQos(_ qos: MQTTQoS) -> Self {
                Self(rawValue: qos.rawValue << 4 | qos.rawValue << 3)
            }
            static let willRetain = Self(rawValue: 5)
            static let password = Self(rawValue: 6)
            static let userName = Self(rawValue: 7)
        }
        
        var protocolSignature: MQTTString { "MQTT" }
        var protocolLevel: UInt8 { 4 }
        
        var username: MQTTString?
        var password: MQTTString?
        var willMessage: MQTT3Message?
        var cleanSession: Bool = true
        
        var clientID: MQTTString
        var keepAlive: UInt16
    }
}


extension MQTT3.ConnectPacket: MQTT3ControlPacket {
    var typeAndFlags: MQTT3.ControlPacketTypeAndFlags {
        MQTT3.ControlPacketTypeAndFlags(type: .connect, flags: 0)
    }

    func variableHeader() -> [UInt8] {
        var header: [UInt8] = []
        
        header.append(self.protocolSignature)
        header.append(self.protocolLevel)

        let connectFlags = self.makeConnectFlags()
        header.append(connectFlags.rawValue)
        
        header.append(self.keepAlive)
        
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
