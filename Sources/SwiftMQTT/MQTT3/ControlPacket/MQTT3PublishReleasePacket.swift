//
//  File.swift
//  
//
//  Created by kisu park on 2023/01/12.
//

import Foundation

extension MQTT3 {
    struct PublishReleasePacket: MQTT3ControlPacket {
        var typeAndFlags: ControlPacketTypeAndFlags { ControlPacketTypeAndFlags(type: .pubrel, flags: 0) }
        var remainingLength: UInt32 { 2 }
        
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

extension MQTT3.PublishReleasePacket {
    init(_ data: Data) throws {
        guard data.count >= 2 else {
            throw SwiftMQTTError.notEnoughData
        }
        
        self.init(identifier: UInt16(data[data.startIndex] << 8) | UInt16(data[data.startIndex+1]))
    }
}
