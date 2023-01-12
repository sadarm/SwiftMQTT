//
//  File.swift
//  
//
//  Created by kisu park on 2023/01/12.
//

import Foundation

struct MQTT3UnsubscribeAckPacket: MQTT3ControlPacket {
    var typeAndFlags: MQTT3ControlPacketTypeAndFlags { MQTT3ControlPacketTypeAndFlags(type: .unsuback, flags: 0) }
    
    let identifier: UInt16
    
    init(identifier: UInt16) {
        self.identifier = identifier
    }
    
    func variableHeader() -> [UInt8] {
        self.identifier.bytesMQTTEncoded
    }
    
    func payload() -> [UInt8] {
        []
    }
}

extension MQTT3UnsubscribeAckPacket {
    init(_ data: Data) throws {
        guard data.count >= 2 else {
            throw SwiftMQTTError.notEnoughData
        }
        
        let identifier = UInt16(data[0] << 8) | UInt16(data[1])
        self.init(identifier: identifier)
    }
}
