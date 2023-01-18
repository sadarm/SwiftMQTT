//
//  File.swift
//  
//
//  Created by kisu park on 2023/01/12.
//

import Foundation

extension MQTT3 {
    struct DisconnectPacket: MQTT3ControlPacket {
        var typeAndFlags: ControlPacketTypeAndFlags { ControlPacketTypeAndFlags(type: .disconnect, flags: 0) }
        
        init() {
            
        }
        
        func variableHeader() -> [UInt8] {
            []
        }
        
        func payload() -> [UInt8] {
            []
        }
    }
}
