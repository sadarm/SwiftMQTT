//
//  File.swift
//  
//
//  Created by kisu park on 2023/01/15.
//

import Foundation

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

