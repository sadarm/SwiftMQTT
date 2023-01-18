//
//  File.swift
//  
//
//  Created by kisu park on 2023/01/12.
//

import Foundation

extension MQTT3 {
    struct PublishAckPacket: MQTT3ControlPacket {
        var typeAndFlags: ControlPacketTypeAndFlags { ControlPacketTypeAndFlags(type: .puback, flags: 0) }
        var remainingLength: UInt32 { 2 }
        
        var identifier: UInt16
        
        init(identifier: UInt16) {
            self.identifier = identifier
        }
        
        func variableHeader() -> [UInt8] {
            return self.identifier.bytesMQTTEncoded
        }
        
        func payload() -> [UInt8] {
            []
        }
    }
}

extension MQTT3.PublishAckPacket {
    init(_ data: Data) throws {
        guard data.count >= 2 else {
            throw SwiftMQTTError.notEnoughData
        }
        
        self.init(identifier: UInt16(data[data.startIndex] << 8) | UInt16(data[data.startIndex+1]))
    }
}
