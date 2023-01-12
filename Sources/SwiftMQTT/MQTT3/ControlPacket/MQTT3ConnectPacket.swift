//
//  File.swift
//  
//
//  Created by kisu park on 2023/01/12.
//

import Foundation

struct MQTT3ConnectPacket {
    struct Flags: OptionSet {
        typealias RawValue = UInt8
        var rawValue: RawValue
        
        static let reserved = Self(rawValue: 0)
        static let cleanSession = Self(rawValue: 1 << 1)
        static let willFlag = Self(rawValue: 1 << 2)
        static func willQos(_ qos: MQTT3QoS) -> Self {
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
    var typeAndFlags: MQTT3ControlPacketTypeAndFlags {
        MQTT3ControlPacketTypeAndFlags(type: .connect, flags: 0)
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