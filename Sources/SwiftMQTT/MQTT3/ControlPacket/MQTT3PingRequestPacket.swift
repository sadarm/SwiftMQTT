//
//  File.swift
//  
//
//  Created by kisu park on 2023/01/12.
//

import Foundation

struct MQTT3PingRequestPacket: MQTT3ControlPacket {
    var typeAndFlags: MQTT3ControlPacketTypeAndFlags { MQTT3ControlPacketTypeAndFlags(type: .pingreq, flags: 0) }
    
    init() {
        
    }
    
    func variableHeader() -> [UInt8] {
        []
    }
    
    func payload() -> [UInt8] {
        []
    }
}
