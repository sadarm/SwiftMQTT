//
//  File.swift
//  
//
//  Created by kisu park on 2023/01/15.
//

import Foundation

struct MQTTVariableByteInteger: RawRepresentable {
    typealias RawValue = [UInt8]
    
    var rawValue: RawValue
    
    init?(rawValue: RawValue) {
        self.rawValue = rawValue
    }
    
    init(_ value: UInt32) {
        self.rawValue = value.variableBytes()
    }
}

struct MQTTFourByteInteger {
    
}

struct MQTTTwoByteInteger {
    
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
}

