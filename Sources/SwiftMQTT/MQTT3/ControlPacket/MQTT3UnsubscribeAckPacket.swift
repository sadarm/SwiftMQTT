//
//  File.swift
//  
//
//  Created by kisu park on 2023/01/12.
//

import Foundation

extension MQTT3 {
    struct UnsubscribeAckPacket: MQTT3ControlPacket {
        var typeAndFlags: ControlPacketTypeAndFlags { ControlPacketTypeAndFlags(type: .unsuback, flags: 0) }
        
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
}

extension MQTT3.UnsubscribeAckPacket {
    init(_ data: Data) throws {
        guard data.count >= 2 else {
            throw SwiftMQTTError.notEnoughData
        }
        
        let identifier = UInt16(data[data.startIndex] << 8) | UInt16(data[data.startIndex+1])
        self.init(identifier: identifier)
    }
}
