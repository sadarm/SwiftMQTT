//
//  File.swift
//  
//
//  Created by kisu park on 2023/01/15.
//

import Foundation

extension UInt16: MQTTBytesRepresentable {
    var msb: UInt8 { UInt8((self & 0xff00) >> 8) }
    var lsb: UInt8 { UInt8(self & 0x00ff) }
    
    var bytesMQTTEncoded: [UInt8] {
        [self.msb, self.lsb]
    }
}

extension UInt32: MQTTBytesRepresentable {
    var bytesMQTTEncoded: [UInt8] {
        self.variableBytes()
    }
    
    private func variableBytes() -> [UInt8] {
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

extension Bool {
    var byte: UInt8 {
        self ? 1 : 0
    }
    
    init(byte: UInt8) {
        self = (byte & 0x01) != 0
    }
}

extension String {
    var bytesMQTTEncoded: [UInt8] {
        let length = UInt16(self.utf8.count)
        return [length.msb, length.lsb] + self.utf8
    }
}


extension Array: MQTTBytesRepresentable where Element: MQTTBytesRepresentable {
    var bytesMQTTEncoded: [UInt8] {
        self.reduce([UInt8](), { (result, mqtt3Bytes) in
            var result = result
            result.append(contentsOf: mqtt3Bytes.bytesMQTTEncoded)
            return result
        })
    }
}



extension Array where Element == UInt8 {
    mutating func append(_ byteRepresentable: any MQTTBytesRepresentable) {
        self.append(contentsOf: byteRepresentable.bytesMQTTEncoded)
    }
}

extension Data {
    mutating func append(_ byteRepresentable: any MQTTBytesRepresentable) {
        self.append(contentsOf: byteRepresentable.bytesMQTTEncoded)
    }
}

extension Data: MQTTBytesRepresentable {
    var bytesMQTTEncoded: [UInt8] {
        var bytes: [UInt8] = []
        self.copyBytes(to: &bytes, count: self.count)
        return bytes
    }
}
