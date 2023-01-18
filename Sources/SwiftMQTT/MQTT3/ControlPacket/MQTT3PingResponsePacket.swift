//
//  File.swift
//  
//
//  Created by kisu park on 2023/01/12.
//

import Foundation

extension MQTT3 {
    struct PingResponsePacket: MQTT3ControlPacket {
        var typeAndFlags: ControlPacketTypeAndFlags { ControlPacketTypeAndFlags(type: .pingresp, flags: 0) }
        
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
