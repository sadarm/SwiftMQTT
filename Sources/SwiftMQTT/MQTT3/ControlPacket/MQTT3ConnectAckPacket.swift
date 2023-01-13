//
//  File.swift
//  
//
//  Created by kisu park on 2023/01/12.
//

import Foundation

struct MQTT3ConnectAckPacket: MQTT3ControlPacket {
    enum ReturnCode: UInt8 {
        case accepted = 0
        case unacceptableProtocolVersion
        case identifierRejected
        case serverUnavailable
        case badUserNameOrPassword
        case notAuthorized
        case reserved
        
        public init(byte: UInt8) {
            switch byte {
            case Self.accepted.rawValue..<Self.reserved.rawValue:
                self.init(rawValue: byte)!
            default:
                self = .reserved
            }
        }
    }
    
    var typeAndFlags: MQTT3ControlPacketTypeAndFlags {
        MQTT3ControlPacketTypeAndFlags(type: .connack, flags: 0)
    }
    var remainingLength: UInt32 { 2 }
    
    var acknowledgeFlags: Bool
    var returnCode: ReturnCode
    
    func variableHeader() -> [UInt8] {
        var header: [UInt8] = []
        
        header.append(self.acknowledgeFlags.byte)
        header.append(self.returnCode.rawValue)
        
        return header
    }
    
    func payload() -> [UInt8] {
        []
    }
}

extension MQTT3ConnectAckPacket {
    init(_ data: Data) throws {
        guard data.count >= 2 else {
            throw SwiftMQTTError.notEnoughData
        }
        
        let acknowledgeFlags: Bool = Bool(byte: data[data.startIndex])
        let returnCode = ReturnCode(byte: data[data.startIndex+1])
        self.init(acknowledgeFlags: acknowledgeFlags, returnCode: returnCode)
    }
}
