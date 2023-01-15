//
//  File.swift
//  
//
//  Created by kisu park on 2023/01/12.
//

import Foundation

struct MQTT3SubscribeAckPacket: MQTT3ControlPacket {
    enum ReturnCode: RawRepresentable {
        typealias RawValue = UInt8
        private static var failureValue: RawValue = 0x80
        
        var rawValue: UInt8 {
            get {
                switch self {
                case .success(maximumQoS: let maximumQoS):
                    return maximumQoS.rawValue
                case .failure:
                    return Self.failureValue
                }
            } set {
                switch MQTT3QoS(rawValue: newValue) {
                case .some(let qos):
                    self = .success(maximumQoS: qos)
                case .none where rawValue == Self.failureValue:
                    self = .failure
                case .none:
                    break
                }
            }
        }
        
        case success(maximumQoS: MQTT3QoS)
        case failure // 0x80
        
        init?(rawValue: UInt8) {
            switch MQTT3QoS(rawValue: rawValue) {
            case .some(let qos):
                self = .success(maximumQoS: qos)
            case .none where rawValue == Self.failureValue:
                self = .failure
            case .none:
                return nil
            }
        }
    }
    
    var typeAndFlags: MQTT3ControlPacketTypeAndFlags { MQTT3ControlPacketTypeAndFlags(type: .suback, flags: 0) }
    
    let identifier: UInt16
    let returnCodes: [ReturnCode]
    
    init(identifier: UInt16, returnCodes: [ReturnCode]) {
        self.identifier = identifier
        self.returnCodes = returnCodes
    }
    
    func variableHeader() -> [UInt8] {
        self.identifier.bytesMQTT3Encoded
    }
    
    func payload() -> [UInt8] {
        self.returnCodes.map { $0.rawValue }
    }
}

extension MQTT3SubscribeAckPacket {
    init(_ data: Data) throws {
        guard data.count >= 2 else {
            throw SwiftMQTTError.notEnoughData
        }
        
        var data = data
        let identifier = UInt16(data[data.startIndex] << 8) | UInt16(data[data.startIndex+1])
        data = data[data.startIndex..<data.endIndex]
        
        let returnCodes = data.compactMap { ReturnCode(rawValue: $0) }
        self.init(identifier: identifier, returnCodes: returnCodes)
    }
}
