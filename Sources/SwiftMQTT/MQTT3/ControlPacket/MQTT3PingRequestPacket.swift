//
//  File.swift
//  
//
//  Created by kisu park on 2023/01/12.
//

import Foundation

extension MQTT3 {
    struct PingRequestPacket: MQTT3ControlPacket {
        var typeAndFlags: ControlPacketTypeAndFlags { ControlPacketTypeAndFlags(type: .pingreq, flags: 0) }
        
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
