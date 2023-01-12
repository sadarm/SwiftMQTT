//
//  File.swift
//  
//
//  Created by kisu park on 2023/01/12.
//

import Foundation

protocol MQTT3BytesRepresentable {
    var bytesMQTTEncoded: [UInt8] { get }
}

extension UInt16: MQTT3BytesRepresentable {
    var msb: UInt8 { UInt8((self & 0xff00) >> 8) }
    var lsb: UInt8 { UInt8(self & 0x00ff) }
    
    var bytesMQTTEncoded: [UInt8] {
        [self.msb, self.lsb]
    }
}

extension Bool {
    var byte: UInt8 {
        self ? 1 : 0
    }
    
    init(byte: UInt8) {
        self = (byte | 0x01) != 0
    }
}

extension String {
    var bytesMQTTEncoded: [UInt8] {
        let length = UInt16(self.utf8.count)
        return [length.msb, length.lsb] + self.utf8
    }
}

extension Array where Element == UInt8 {
    mutating func append(_ byteRepresentable: any MQTT3BytesRepresentable) {
        self.append(contentsOf: byteRepresentable.bytesMQTTEncoded)
    }
}

extension Array: MQTT3BytesRepresentable where Element: MQTT3BytesRepresentable {
    var bytesMQTTEncoded: [UInt8] {
        self.reduce([UInt8](), { (result, mqtt3Bytes) in
            var result = result
            result.append(contentsOf: mqtt3Bytes.bytesMQTTEncoded)
            return result
        })
    }
}
