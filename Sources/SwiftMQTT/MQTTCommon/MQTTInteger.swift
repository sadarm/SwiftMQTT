//
//  File.swift
//  
//
//  Created by kisu park on 2023/01/15.
//

import Foundation

struct MQTTVariableByteInteger: ExpressibleByIntegerLiteral {
    typealias RawValue = [UInt8]
    
    let rawValue: RawValue
    let uint32Value: UInt32
    var intValue: Int { Int(self.uint32Value) }
    
    init(integerLiteral value: UInt32) {
        self.init(value)
    }
    
    init(_ value: UInt32) {
        self.rawValue = value.variableBytes()
        self.uint32Value = value
    }
    
//    init?(rawValue: RawValue) {
//        guard let uint32Value = try? UInt32(variableBytes: rawValue) else {
//            return nil
//        }
//        self.uint32Value = uint32Value
//        self.rawValue = rawValue
//    }
    
    static func create(from data: Data) throws -> (instance: Self, remained: Data) {
        guard !data.isEmpty else {
            throw SwiftMQTTError.malformedVariableByteInteger
        }
        
        var multiplier: UInt32 = 1
        var value: UInt32 = 0
        
        var lastIndex: Int = 0
        for index in data.indices {
            lastIndex = index
            
            let encodedByte = data[index]
            value += UInt32(encodedByte & 127) * multiplier
            
            if multiplier > 128*128*128 {
                throw SwiftMQTTError.malformedVariableByteInteger
            }
            
            if (encodedByte & 128) != 0 {
                break
            }
            
            multiplier *= 128
        }
        
        let remainedData: Data
        if data.indices.contains(lastIndex+1) {
            remainedData = data[lastIndex+1..<data.endIndex]
        } else {
            remainedData = Data()
        }
        return (MQTTVariableByteInteger(value), remainedData)
    }
}

public struct MQTTFourByteInteger: ExpressibleByIntegerLiteral, RawRepresentable {
    public typealias RawValue = (UInt8, UInt8, UInt8, UInt8)

    public let rawValue: RawValue
    public let uint32Value: UInt32
    
    public init(integerLiteral value: UInt32) {
        self.rawValue = (UInt8(value & 0xff000000 >> 24),
                         UInt8(value & 0x00ff0000 >> 16),
                         UInt8(value & 0x0000ff00 >> 8),
                         UInt8(value & 0x000000ff))
        self.uint32Value = value
    }
    
    public init(rawValue value: RawValue) {
        self.rawValue = value
        self.uint32Value = (UInt32(self.rawValue.0) << 24) |
        (UInt32(self.rawValue.1) << 16) |
        (UInt32(self.rawValue.2) << 8) |
        UInt32(self.rawValue.3)
    }
    
    init(data: Data) throws {
        guard data.count >= 4 else {
            throw SwiftMQTTError.corruptData
        }
        
        self.init(rawValue: (data[data.startIndex],
                             data[data.startIndex+1],
                             data[data.startIndex+2],
                             data[data.startIndex+3]))
    }
}

struct MQTTTwoByteInteger: ExpressibleByIntegerLiteral, RawRepresentable {
    typealias RawValue = (UInt8, UInt8)
    
    let rawValue: RawValue
    let uint16Value: UInt16

    init(integerLiteral value: UInt16) {
        self.rawValue = (UInt8(value & 0xff00 >> 8),
                         UInt8(value & 0x00ff))
        self.uint16Value = value
    }
    
    init(rawValue value: RawValue) {
        self.rawValue = value
        self.uint16Value = UInt16(self.rawValue.0 << 8) | UInt16(self.rawValue.1)
    }
    
    init(data: Data) throws {
        guard data.count >= 2 else {
            throw SwiftMQTTError.corruptData
        }
        
        self.init(rawValue: (data[data.startIndex],
                             data[data.startIndex+1]))
    }
}

enum MQTTBool: ExpressibleByBooleanLiteral {
    case `true`
    case `false`
    
    var rawValue: UInt8 {
        switch self {
        case .true:
            return 1
        case .false:
            return 0
        }
    }
    
    var boolValue: Bool {
        switch self {
        case .true:
            return true
        case .false:
            return false
        }
    }
    
    typealias BooleanLiteralType = Bool
    typealias RawValue = UInt8
    
    init(booleanLiteral value: Bool) {
        self = value ? .true : .false
    }
    
    init(rawValue: UInt8) throws {
        switch rawValue {
        case 0:
            self = .false
        case 1:
            self = .true
        default:
            throw SwiftMQTTError.malformedBool
        }
    }
    
    init(data: Data) throws {
        guard let instance = try data.first.flatMap(Self.init(rawValue:)) else {
            throw SwiftMQTTError.corruptData
        }
        self = instance
    }
    
}

struct MQTTBoolean: ExpressibleByBooleanLiteral, RawRepresentable {
    typealias RawValue = UInt8

    let rawValue: RawValue
    
    init(booleanLiteral value: Bool) {
        self.rawValue = value ? 1 : 0
    }
    
    init(rawValue: UInt8) {
        self.rawValue = rawValue > 0 ? 1 : 0
    }
}

extension MQTTTwoByteInteger: MQTTBytesRepresentable {
    var bytesMQTTEncoded: [UInt8] {
        [self.rawValue.0, self.rawValue.1]
    }
}

extension MQTTFourByteInteger: MQTTBytesRepresentable {
    var bytesMQTTEncoded: [UInt8] {
        [self.rawValue.0, self.rawValue.1, self.rawValue.2, self.rawValue.3]
    }
}

extension MQTTVariableByteInteger: MQTTBytesRepresentable {
    var bytesMQTTEncoded: [UInt8] {
        self.rawValue
    }
}

extension MQTTBool: MQTTBytesRepresentable {
    var bytesMQTTEncoded: [UInt8] {
        [self.rawValue]
    }
}

extension MQTTBoolean: MQTTBytesRepresentable {
    var bytesMQTTEncoded: [UInt8] {
        [self.rawValue]
    }
}

private extension UInt32 {
    func variableBytes() -> [UInt8] {
        var integerValue = self
        var variableBytes: [UInt8] = []
        repeat {
            var byte = UInt8(integerValue % 128)
            integerValue = integerValue / 128
            
            // if there are more data to encode, set the top bit of this byte
            if integerValue > 0 {
                byte = byte | 128
            }
            variableBytes.append(byte)
        } while integerValue > 0
        return variableBytes
    }
//
//    init(variableBytes: [UInt8]) throws {
//        var multiplier: UInt32 = 1
//        var value: UInt32 = 0
//
//        for encodedByte in variableBytes {
//            value += UInt32(encodedByte & 127) * multiplier
//
//            if multiplier > 128*128*128 {
//                throw SwiftMQTTError.malformedVariableByteInteger
//            }
//
//            multiplier *= 128
//
//            if (encodedByte & 128) != 0 {
//                break
//            }
//        }
//    }
}

