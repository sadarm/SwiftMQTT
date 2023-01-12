//
//  File.swift
//  
//
//  Created by kisu park on 2023/01/12.
//

import Foundation

struct MQTT3PublishReleasePacket: MQTT3ControlPacket {
    var typeAndFlags: MQTT3ControlPacketTypeAndFlags { MQTT3ControlPacketTypeAndFlags(type: .pubrel, flags: 0) }
    var remainingLength: UInt8 { 2 }
    
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

extension MQTT3PublishReleasePacket {
    init(_ data: Data) throws {
        guard data.count >= 2 else {
            throw SwiftMQTTError.notEnoughData
        }
        
        self.init(identifier: UInt16(data[0] << 8) | UInt16(data[1]))
    }
}
